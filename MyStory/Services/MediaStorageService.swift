import Foundation
import UIKit
import CryptoKit
import Security
import AVFoundation
import ImageIO

public final class MediaStorageService: ObservableObject {
    public enum MediaType: String { case image, video }

    public static let baseDirName = "Media"
    private let keyManager = KeyManager()

    public func saveImage(_ image: UIImage) throws -> String {
        let fileName = UUID().uuidString + ".heic"
        let keyId = (fileName as NSString).deletingPathExtension
        let url = try ensureImageDir().appendingPathComponent(fileName)
        // 保存前先修正图片方向
        let fixedImage = image.fixedOrientation()
        guard let data = fixedImage.heicData(compressionQuality: 0.8) ?? fixedImage.jpegData(compressionQuality: 0.8) else {
            throw NSError(domain: "Media", code: -1, userInfo: [NSLocalizedDescriptionKey: "无法编码图片"])
        }
        let enc = try encrypt(data: data, keyId: keyId)
        try enc.write(to: url)
        return fileName
    }

    public func saveImageWithThumbnail(_ image: UIImage) throws -> (fileName: String, thumbFileName: String) {
        let fileId = UUID().uuidString
        let fileName = fileId + ".heic"
        let thumbName = fileId + "_thumb.heic"
        let dir = try ensureImageDir()
        // 保存前先修正图片方向
        let fixedImage = image.fixedOrientation()
        guard let fullData = fixedImage.heicData(compressionQuality: 0.8) ?? fixedImage.jpegData(compressionQuality: 0.8) else {
            throw NSError(domain: "Media", code: -2, userInfo: [NSLocalizedDescriptionKey: "无法编码原图"])
        }
        let thumbImg = generateThumbnail(from: fixedImage, maxEdge: 800)
        guard let thumbData = thumbImg.heicData(compressionQuality: 0.6) ?? thumbImg.jpegData(compressionQuality: 0.6) else {
            throw NSError(domain: "Media", code: -3, userInfo: [NSLocalizedDescriptionKey: "无法编码缩略图"])
        }
        let encFull = try encrypt(data: fullData, keyId: fileId)
        let encThumb = try encrypt(data: thumbData, keyId: fileId + "_thumb")
        try encFull.write(to: dir.appendingPathComponent(fileName))
        try encThumb.write(to: dir.appendingPathComponent(thumbName))
        return (fileName, thumbName)
    }

    public func url(for fileName: String, type: MediaType = .image) -> URL? {
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

    public func loadImage(fileName: String) -> UIImage? {
        guard let url = url(for: fileName, type: .image) else { return nil }
        guard let enc = try? Data(contentsOf: url) else { return nil }
        let keyId = (fileName as NSString).deletingPathExtension
        guard let dec = try? decrypt(data: enc, keyId: keyId) else { return nil }
        // 加载时图片方向已在保存时修正，直接返回
        return UIImage(data: dec)
    }
    
    public func loadVideoThumbnail(fileName: String) -> UIImage? {
        guard let url = url(for: fileName, type: .video) else { return nil }
        guard let data = try? Data(contentsOf: url) else { return nil }
        
        // 先尝试直接作为 JPEG 读取（新格式）
        if let image = UIImage(data: data) {
            return image
        }
        
        // 回退到旧的加密格式解密
        let keyId = (fileName as NSString).deletingPathExtension
        guard let dec = try? decrypt(data: data, keyId: keyId) else { return nil }
        return UIImage(data: dec)
    }
    
    public func saveVideo(from sourceURL: URL, progressHandler: ((Double) -> Void)? = nil) throws -> (fileName: String, thumbFileName: String) {
        let fileId = UUID().uuidString
        // 保留源文件扩展名（mov/mp4）
        let ext = sourceURL.pathExtension.isEmpty ? "mov" : sourceURL.pathExtension
        let fileName = fileId + "." + ext
        let thumbName = fileId + "_thumb.jpg"
        let dir = try ensureVideoDir()
        
        let destURL = dir.appendingPathComponent(fileName)
        
        // 直接移动文件到存储目录（同文件系统内为 rename，几乎零耗时）
        // 如果 move 失败（跨文件系统），回退到 copy
        do {
            try FileManager.default.moveItem(at: sourceURL, to: destURL)
        } catch {
            try FileManager.default.copyItem(at: sourceURL, to: destURL)
            try? FileManager.default.removeItem(at: sourceURL)
        }
        progressHandler?(0.8)
        
        // 生成视频封面（直接保存 JPEG，不加密）
        if let thumbImage = try? generateVideoThumbnail(from: destURL) {
            if let thumbData = thumbImage.jpegData(compressionQuality: 0.7) {
                try thumbData.write(to: dir.appendingPathComponent(thumbName))
            }
        }
        
        progressHandler?(1.0)
        return (fileName, thumbName)
    }
    
    /// 流式加密视频文件 - 已废弃，保留用于旧数据兼容
    /// 新保存的视频不再加密
    private func encryptVideoStreaming(from sourceURL: URL, to destURL: URL, keyId: String, fileSize: Int64, progressHandler: ((Double) -> Void)?) throws {
        let chunkSize = 4 * 1024 * 1024  // 4MB 分块
        
        // 对于小文件（< 50MB），直接使用传统方式
        if fileSize < 50 * 1024 * 1024 {
            let videoData = try Data(contentsOf: sourceURL)
            let encVideo = try encrypt(data: videoData, keyId: keyId)
            try encVideo.write(to: destURL)
            progressHandler?(1.0)
            return
        }
        
        // 大文件使用分块加密
        let inputStream = InputStream(url: sourceURL)!
        inputStream.open()
        defer { inputStream.close() }
        
        var outputData = Data()
        var buffer = [UInt8](repeating: 0, count: chunkSize)
        var totalBytesRead: Int64 = 0
        var chunkIndex = 0
        
        // 写入文件头：版本号 + 分块数量占位
        var header = Data()
        header.append(contentsOf: [0x01])  // 版本 1
        let chunkCountPlaceholder: UInt32 = 0
        header.append(contentsOf: withUnsafeBytes(of: chunkCountPlaceholder.bigEndian) { Array($0) })
        outputData.append(header)
        
        var encryptedChunks: [Data] = []
        
        while inputStream.hasBytesAvailable {
            let bytesRead = inputStream.read(&buffer, maxLength: chunkSize)
            if bytesRead <= 0 { break }
            
            totalBytesRead += Int64(bytesRead)
            let chunkData = Data(buffer[0..<bytesRead])
            
            // 使用带索引的 keyId 加密每个分块
            let chunkKeyId = "\(keyId)_chunk_\(chunkIndex)"
            let encryptedChunk = try encrypt(data: chunkData, keyId: chunkKeyId)
            
            // 写入分块长度 + 加密数据
            var chunkLength = UInt32(encryptedChunk.count).bigEndian
            outputData.append(contentsOf: withUnsafeBytes(of: &chunkLength) { Array($0) })
            outputData.append(encryptedChunk)
            
            chunkIndex += 1
            
            // 报告进度
            if fileSize > 0 {
                let progress = Double(totalBytesRead) / Double(fileSize)
                progressHandler?(min(progress, 0.99))
            }
            
            // 定期写入磁盘以释放内存
            if outputData.count > 16 * 1024 * 1024 {  // 每 16MB 写入一次
                if chunkIndex == 1 {
                    try outputData.write(to: destURL)
                } else {
                    let fileHandle = try FileHandle(forWritingTo: destURL)
                    try fileHandle.seekToEnd()
                    try fileHandle.write(contentsOf: outputData)
                    try fileHandle.close()
                }
                outputData = Data()
            }
        }
        
        // 写入剩余数据
        if !outputData.isEmpty {
            if chunkIndex == 1 || !FileManager.default.fileExists(atPath: destURL.path) {
                try outputData.write(to: destURL)
            } else {
                let fileHandle = try FileHandle(forWritingTo: destURL)
                try fileHandle.seekToEnd()
                try fileHandle.write(contentsOf: outputData)
                try fileHandle.close()
            }
        }
        
        // 更新文件头中的分块数量
        let fileHandle = try FileHandle(forUpdating: destURL)
        try fileHandle.seek(toOffset: 1)  // 跳过版本号
        var chunkCount = UInt32(chunkIndex).bigEndian
        try fileHandle.write(contentsOf: withUnsafeBytes(of: &chunkCount) { Array($0) })
        try fileHandle.close()
        
        progressHandler?(1.0)
    }
    
    public func loadVideoURL(fileName: String, progressHandler: ((Double) -> Void)? = nil) -> URL? {
        guard let fileURL = url(for: fileName, type: .video) else { return nil }
        guard FileManager.default.fileExists(atPath: fileURL.path) else { return nil }
        
        // 检测文件是否为旧的加密格式
        // 读取前几个字节判断：分块加密以 0x01 开头，AES-GCM 密文不会是合法视频头
        // 合法视频文件头部通常以 ftyp（offset 4）或 moov/mdat 等 box 开头
        if isLegacyEncryptedVideo(at: fileURL) {
            return loadLegacyEncryptedVideo(fileURL: fileURL, fileName: fileName, progressHandler: progressHandler)
        }
        
        // 新格式：直接返回存储路径，无需解密
        progressHandler?(1.0)
        return fileURL
    }
    
    /// 检测文件是否为旧的加密格式
    private func isLegacyEncryptedVideo(at url: URL) -> Bool {
        guard let handle = try? FileHandle(forReadingFrom: url) else { return false }
        defer { try? handle.close() }
        guard let header = try? handle.read(upToCount: 8) else { return false }
        
        // 分块加密格式：第一个字节是 0x01（版本号）
        if header.count >= 1 && header[0] == 0x01 {
            return true
        }
        
        // 检查是否为合法视频文件（ftyp box 通常在 offset 4-7）
        if header.count >= 8 {
            let ftyp = String(data: header[4..<8], encoding: .ascii)
            if ftyp == "ftyp" {
                return false  // 合法视频文件
            }
        }
        
        // 不是合法视频头，可能是 AES-GCM 整体加密
        // AES-GCM combined 格式: nonce(12) + ciphertext + tag(16)，最小 28 字节
        // 尝试解密来判断
        return true
    }
    
    /// 加载旧的加密视频（兼容）
    private func loadLegacyEncryptedVideo(fileURL: URL, fileName: String, progressHandler: ((Double) -> Void)?) -> URL? {
        guard let enc = try? Data(contentsOf: fileURL) else { return nil }
        
        // 分块加密格式
        if enc.count >= 5 && enc[0] == 0x01 {
            return loadChunkedEncryptedVideo(enc, fileName: fileName, progressHandler: progressHandler)
        }
        
        // 传统单块 AES-GCM 解密
        let keyId = (fileName as NSString).deletingPathExtension
        guard let dec = try? decrypt(data: enc, keyId: keyId) else { return nil }
        
        let tempURL = URL.documentsDirectory.appendingPathComponent("temp_\(UUID().uuidString).mov")
        try? dec.write(to: tempURL)
        progressHandler?(1.0)
        return tempURL
    }
    
    private func loadChunkedEncryptedVideo(_ data: Data, fileName: String, progressHandler: ((Double) -> Void)?) -> URL? {
        let keyId = (fileName as NSString).deletingPathExtension
        
        // 读取文件头
        guard data.count >= 5 else { return nil }
        let chunkCount = data[1...4].withUnsafeBytes { $0.load(as: UInt32.self).bigEndian }
        
        let tempURL = URL.documentsDirectory.appendingPathComponent("temp_\(UUID().uuidString).mov")
        FileManager.default.createFile(atPath: tempURL.path, contents: nil)
        guard let fileHandle = try? FileHandle(forWritingTo: tempURL) else { return nil }
        
        var offset = 5  // 跳过头部
        var chunkIndex = 0
        
        while offset < data.count && chunkIndex < chunkCount {
            // 读取分块长度
            guard offset + 4 <= data.count else { break }
            let chunkLength = data[offset..<offset+4].withUnsafeBytes { $0.load(as: UInt32.self).bigEndian }
            offset += 4
            
            // 读取加密数据
            guard offset + Int(chunkLength) <= data.count else { break }
            let encryptedChunk = data[offset..<offset+Int(chunkLength)]
            offset += Int(chunkLength)
            
            // 解密
            let chunkKeyId = "\(keyId)_chunk_\(chunkIndex)"
            guard let decryptedChunk = try? decrypt(data: Data(encryptedChunk), keyId: chunkKeyId) else {
                try? fileHandle.close()
                try? FileManager.default.removeItem(at: tempURL)
                return nil
            }
            
            try? fileHandle.write(contentsOf: decryptedChunk)
            
            chunkIndex += 1
            progressHandler?(Double(chunkIndex) / Double(chunkCount))
        }
        
        try? fileHandle.close()
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
        
        // 获取视频分辨率
        if let track = asset.tracks(withMediaType: .video).first {
            let size = track.naturalSize
            let transform = track.preferredTransform
            
            // 处理视频旋转，获取真实显示尺寸
            var videoSize = size
            if transform.a == 0 && transform.b == 1.0 && transform.c == -1.0 && transform.d == 0 {
                // 90度旋转
                videoSize = CGSize(width: size.height, height: size.width)
            } else if transform.a == 0 && transform.b == -1.0 && transform.c == 1.0 && transform.d == 0 {
                // 270度旋转
                videoSize = CGSize(width: size.height, height: size.width)
            }
            
            // 计算保持宽高比的缩略图尺寸，最大边不超过800
            let maxEdge: CGFloat = 800
            let scale = min(maxEdge / videoSize.width, maxEdge / videoSize.height)
            if scale < 1.0 {
                let thumbnailSize = CGSize(
                    width: videoSize.width * scale,
                    height: videoSize.height * scale
                )
                generator.maximumSize = thumbnailSize
            }
            // 如果视频本身就小于800，不设置maximumSize，保持原始分辨率
        }
        
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
    
    /// 修正图片方向，确保显示正确
    func fixedOrientation() -> UIImage {
        // 如果图片方向已经是正确的，直接返回
        if imageOrientation == .up {
            return self
        }
        
        // 根据图片方向重绘图片
        guard let cgImage = self.cgImage else { return self }
        guard let colorSpace = cgImage.colorSpace else { return self }
        guard let context = CGContext(
            data: nil,
            width: Int(size.width),
            height: Int(size.height),
            bitsPerComponent: cgImage.bitsPerComponent,
            bytesPerRow: 0,
            space: colorSpace,
            bitmapInfo: cgImage.bitmapInfo.rawValue
        ) else { return self }
        
        // 根据方向应用变换
        var transform = CGAffineTransform.identity
        
        switch imageOrientation {
        case .down, .downMirrored:
            transform = transform.translatedBy(x: size.width, y: size.height)
            transform = transform.rotated(by: .pi)
        case .left, .leftMirrored:
            transform = transform.translatedBy(x: size.width, y: 0)
            transform = transform.rotated(by: .pi / 2)
        case .right, .rightMirrored:
            transform = transform.translatedBy(x: 0, y: size.height)
            transform = transform.rotated(by: -.pi / 2)
        default:
            break
        }
        
        switch imageOrientation {
        case .upMirrored, .downMirrored:
            transform = transform.translatedBy(x: size.width, y: 0)
            transform = transform.scaledBy(x: -1, y: 1)
        case .leftMirrored, .rightMirrored:
            transform = transform.translatedBy(x: size.height, y: 0)
            transform = transform.scaledBy(x: -1, y: 1)
        default:
            break
        }
        
        context.concatenate(transform)
        
        // 绘制图片
        switch imageOrientation {
        case .left, .leftMirrored, .right, .rightMirrored:
            context.draw(cgImage, in: CGRect(x: 0, y: 0, width: size.height, height: size.width))
        default:
            context.draw(cgImage, in: CGRect(x: 0, y: 0, width: size.width, height: size.height))
        }
        
        guard let newCGImage = context.makeImage() else { return self }
        return UIImage(cgImage: newCGImage)
    }
}
