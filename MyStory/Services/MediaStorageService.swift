import Foundation
import UIKit
import CryptoKit
import Security
import AVFoundation
import ImageIO

final class MediaStorageService: ObservableObject {
    enum MediaType: String { case image, video }

    static let baseDirName = "Media"
    private let keyManager = KeyManager()

    func saveImage(_ image: UIImage) throws -> String {
        let fileName = UUID().uuidString + ".heic"
        let keyId = (fileName as NSString).deletingPathExtension
        let url = try ensureImageDir().appendingPathComponent(fileName)
        guard let data = image.heicData(compressionQuality: 0.8) ?? image.jpegData(compressionQuality: 0.8) else {
            throw NSError(domain: "Media", code: -1, userInfo: [NSLocalizedDescriptionKey: "无法编码图片"])
        }
        let enc = try encrypt(data: data, keyId: keyId)
        try enc.write(to: url)
        return fileName
    }

    func saveImageWithThumbnail(_ image: UIImage) throws -> (fileName: String, thumbFileName: String) {
        let fileId = UUID().uuidString
        let fileName = fileId + ".heic"
        let thumbName = fileId + "_thumb.heic"
        let dir = try ensureImageDir()
        guard let fullData = image.heicData(compressionQuality: 0.8) ?? image.jpegData(compressionQuality: 0.8) else {
            throw NSError(domain: "Media", code: -2, userInfo: [NSLocalizedDescriptionKey: "无法编码原图"])
        }
        let thumbImg = generateThumbnail(from: image, maxEdge: 800)
        guard let thumbData = thumbImg.heicData(compressionQuality: 0.6) ?? thumbImg.jpegData(compressionQuality: 0.6) else {
            throw NSError(domain: "Media", code: -3, userInfo: [NSLocalizedDescriptionKey: "无法编码缩略图"])
        }
        let encFull = try encrypt(data: fullData, keyId: fileId)
        let encThumb = try encrypt(data: thumbData, keyId: fileId + "_thumb")
        try encFull.write(to: dir.appendingPathComponent(fileName))
        try encThumb.write(to: dir.appendingPathComponent(thumbName))
        return (fileName, thumbName)
    }

    func url(for fileName: String, type: MediaType = .image) -> URL? {
        let mediaRoot = MediaStorageService.documentsDirectory().appendingPathComponent(MediaStorageService.baseDirName)
        switch type {
        case .image:
            let y = currentYear()
            let m = currentMonth()
            return mediaRoot
                .appendingPathComponent("Images")
                .appendingPathComponent(y)
                .appendingPathComponent(m)
                .appendingPathComponent(fileName)
        case .video:
            let y = currentYear()
            let m = currentMonth()
            return mediaRoot
                .appendingPathComponent("Videos")
                .appendingPathComponent(y)
                .appendingPathComponent(m)
                .appendingPathComponent(fileName)
        }
    }

    func loadImage(fileName: String) -> UIImage? {
        guard let url = url(for: fileName, type: .image) else { return nil }
        guard let enc = try? Data(contentsOf: url) else { return nil }
        let keyId = (fileName as NSString).deletingPathExtension
        guard let dec = try? decrypt(data: enc, keyId: keyId) else { return nil }
        return UIImage(data: dec)
    }
    
    func loadVideoThumbnail(fileName: String) -> UIImage? {
        guard let url = url(for: fileName, type: .video) else { return nil }
        guard let enc = try? Data(contentsOf: url) else { return nil }
        let keyId = (fileName as NSString).deletingPathExtension
        guard let dec = try? decrypt(data: enc, keyId: keyId) else { return nil }
        return UIImage(data: dec)
    }
    
    func saveVideo(from sourceURL: URL) throws -> (fileName: String, thumbFileName: String) {
        let fileId = UUID().uuidString
        let fileName = fileId + ".mov"
        let thumbName = fileId + "_thumb.jpg"
        let dir = try ensureVideoDir()
        
        // 读取视频文件
        let videoData = try Data(contentsOf: sourceURL)
        let encVideo = try encrypt(data: videoData, keyId: fileId)
        try encVideo.write(to: dir.appendingPathComponent(fileName))
        
        // 生成视频封面
        if let thumbImage = try? generateVideoThumbnail(from: sourceURL) {
            if let thumbData = thumbImage.jpegData(compressionQuality: 0.7) {
                let encThumb = try encrypt(data: thumbData, keyId: fileId + "_thumb")
                try encThumb.write(to: dir.appendingPathComponent(thumbName))
            }
        }
        
        // 清理临时文件
        try? FileManager.default.removeItem(at: sourceURL)
        
        return (fileName, thumbName)
    }
    
    func loadVideoURL(fileName: String) -> URL? {
        guard let encURL = url(for: fileName, type: .video) else { return nil }
        guard let enc = try? Data(contentsOf: encURL) else { return nil }
        let keyId = (fileName as NSString).deletingPathExtension
        guard let dec = try? decrypt(data: enc, keyId: keyId) else { return nil }
        
        let tempURL = URL.documentsDirectory.appendingPathComponent("temp_\(UUID().uuidString).mov")
        try? dec.write(to: tempURL)
        return tempURL
    }

    private func ensureImageDir() throws -> URL {
        let root = MediaStorageService.documentsDirectory().appendingPathComponent(MediaStorageService.baseDirName)
        let images = root.appendingPathComponent("Images")
            .appendingPathComponent(currentYear())
            .appendingPathComponent(currentMonth())
        try FileManager.default.createDirectory(at: images, withIntermediateDirectories: true)
        return images
    }
    
    private func ensureVideoDir() throws -> URL {
        let root = MediaStorageService.documentsDirectory().appendingPathComponent(MediaStorageService.baseDirName)
        let videos = root.appendingPathComponent("Videos")
            .appendingPathComponent(currentYear())
            .appendingPathComponent(currentMonth())
        try FileManager.default.createDirectory(at: videos, withIntermediateDirectories: true)
        return videos
    }

    private func generateThumbnail(from image: UIImage, maxEdge: CGFloat) -> UIImage {
        let size = image.size
        let scale = max(size.width, size.height) > maxEdge ? maxEdge / max(size.width, size.height) : 1.0
        let newSize = CGSize(width: size.width * scale, height: size.height * scale)
        let renderer = UIGraphicsImageRenderer(size: newSize)
        return renderer.image { _ in
            image.draw(in: CGRect(origin: .zero, size: newSize))
        }
    }
    
    private func generateVideoThumbnail(from url: URL) throws -> UIImage {
        let asset = AVAsset(url: url)
        let generator = AVAssetImageGenerator(asset: asset)
        generator.appliesPreferredTrackTransform = true
        // 优化：设置最大尺寸以加快生成速度
        generator.maximumSize = CGSize(width: 800, height: 800)
        // 优化：使用快速模式，降低精度换取速度
        generator.requestedTimeToleranceBefore = CMTime(seconds: 1, preferredTimescale: 60)
        generator.requestedTimeToleranceAfter = CMTime(seconds: 1, preferredTimescale: 60)
        let time = CMTime(seconds: 0.1, preferredTimescale: 60)  // 使用更早的帧
        let cgImage = try generator.copyCGImage(at: time, actualTime: nil)
        return UIImage(cgImage: cgImage)
    }

    private func encrypt(data: Data, keyId: String) throws -> Data {
        let key = try keyManager.key(for: keyId)
        let sealed = try AES.GCM.seal(data, using: key)
        guard let combined = sealed.combined else {
            throw NSError(domain: "Media", code: -4, userInfo: [NSLocalizedDescriptionKey: "加密失败"])
        }
        return combined
    }

    private func decrypt(data: Data, keyId: String) throws -> Data {
        let key = try keyManager.key(for: keyId)
        let box = try AES.GCM.SealedBox(combined: data)
        return try AES.GCM.open(box, using: key)
    }

    private static func documentsDirectory() -> URL {
        FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
    }

    private func currentYear() -> String {
        let c = Calendar.current
        let y = c.component(.year, from: Date())
        return String(y)
    }

    private func currentMonth() -> String {
        let c = Calendar.current
        let m = c.component(.month, from: Date())
        return String(format: "%02d", m)
    }
}

private struct KeyManager {
    private static let masterKeyAccount = "MyStory.MasterKey"

    func key(for keyId: String) throws -> SymmetricKey {
        let master = try masterKey()
        let salt = Data(keyId.utf8)
        let derived = HKDF<SHA256>.deriveKey(inputKeyMaterial: master, salt: salt, info: Data(), outputByteCount: 32)
        return derived
    }

    private func masterKey() throws -> SymmetricKey {
        if let stored = try? readKeychain(account: Self.masterKeyAccount) {
            return SymmetricKey(data: stored)
        }
        var bytes = [UInt8](repeating: 0, count: 32)
        let _ = SecRandomCopyBytes(kSecRandomDefault, bytes.count, &bytes)
        let data = Data(bytes)
        try saveKeychain(data, account: Self.masterKeyAccount)
        return SymmetricKey(data: data)
    }

    private func saveKeychain(_ data: Data, account: String) throws {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: account,
            kSecValueData as String: data,
            kSecAttrAccessible as String: kSecAttrAccessibleWhenUnlocked
        ]
        SecItemDelete(query as CFDictionary)
        let status = SecItemAdd(query as CFDictionary, nil)
        guard status == errSecSuccess else { throw NSError(domain: "Keychain", code: Int(status), userInfo: nil) }
    }

    private func readKeychain(account: String) throws -> Data {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: account,
            kSecReturnData as String: true,
            kSecMatchLimit as String: kSecMatchLimitOne
        ]
        var item: CFTypeRef?
        let status = SecItemCopyMatching(query as CFDictionary, &item)
        guard status == errSecSuccess, let data = item as? Data else { throw NSError(domain: "Keychain", code: Int(status), userInfo: nil) }
        return data
    }
}

private extension UIImage {
    func heicData(compressionQuality: CGFloat) -> Data? {
        let data = NSMutableData()
        guard let destination = CGImageDestinationCreateWithData(data as CFMutableData, AVFileType.heic as CFString, 1, nil) else {
            return nil
        }
        guard let cgImage = self.cgImage else { return nil }
        let options: [CFString: Any] = [kCGImageDestinationLossyCompressionQuality: compressionQuality]
        CGImageDestinationAddImage(destination, cgImage, options as CFDictionary)
        guard CGImageDestinationFinalize(destination) else { return nil }
        return data as Data
    }
}
