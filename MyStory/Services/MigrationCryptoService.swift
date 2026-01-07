import Foundation
import CryptoKit

/// 负责对备份 zip 文件进行加解密的服务
struct MigrationCryptoService {
    enum CryptoError: Error {
        case invalidPasswordOrCorruptedData
        case ioError
    }

    /// 使用用户输入的迁移密码和 backupId 派生对称密钥
    /// - Parameters:
    ///   - password: 用户迁移密码
    ///   - backupId: 备份唯一标识（UUID）
    /// - Returns: 对称密钥
    private func deriveKey(password: String, backupId: UUID) -> SymmetricKey {
        var data = Data()
        if let pwdData = password.data(using: .utf8) {
            data.append(pwdData)
        }
        var uuid = backupId.uuid
        withUnsafeBytes(of: &uuid) { buffer in
            data.append(buffer.bindMemory(to: UInt8.self))
        }
        let hash = SHA256.hash(data: data)
        return SymmetricKey(data: Data(hash))
    }

    /// 对备份 zip 文件进行加密，生成 .enc 文件
    /// - Parameters:
    ///   - zipURL: 未加密的 zip 备份文件路径
    ///   - password: 用户迁移密码
    ///   - backupId: manifest 中的 backupId
    /// - Returns: 加密后的 .enc 文件路径
    func encryptBackup(zipURL: URL, password: String, backupId: UUID) throws -> URL {
        let data = try Data(contentsOf: zipURL)
        let key = deriveKey(password: password, backupId: backupId)
        let sealed = try AES.GCM.seal(data, using: key)
        guard let combined = sealed.combined else {
            throw CryptoError.invalidPasswordOrCorruptedData
        }
        let encURL = zipURL.deletingPathExtension().appendingPathExtension("enc")
        try combined.write(to: encURL, options: [.atomic])
        return encURL
    }

    /// 对加密备份 .enc 文件进行解密，生成容器文件（.bin）
    /// - Parameters:
    ///   - encryptedURL: 加密的备份文件路径
    ///   - password: 用户迁移密码
    ///   - backupId: manifest 中的 backupId
    /// - Returns: 解密得到的容器文件路径
    func decryptBackup(encryptedURL: URL, password: String, backupId: UUID) throws -> URL {
        let encData = try Data(contentsOf: encryptedURL)
        let key = deriveKey(password: password, backupId: backupId)
        do {
            let box = try AES.GCM.SealedBox(combined: encData)
            let decrypted = try AES.GCM.open(box, using: key)
            let containerURL = encryptedURL.deletingPathExtension().appendingPathExtension("bin")
            try decrypted.write(to: containerURL, options: [.atomic])
            return containerURL
        } catch {
            throw CryptoError.invalidPasswordOrCorruptedData
        }
    }
}
