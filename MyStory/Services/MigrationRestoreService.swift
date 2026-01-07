import Foundation
import CoreData
import Security

/// 负责从加密备份文件恢复 MasterKey、媒体文件和 Core Data 数据
final class MigrationRestoreService {
    struct Progress {
        let step: String
        let fractionCompleted: Double
    }

    // 与 MigrationBackupService 中的 BackupPayload 结构保持一致
    struct BackupPayload: Codable {
        struct EntityStats: Codable {
            var categoryCount: Int
            var storyCount: Int
            var mediaCount: Int
        }

        struct MediaStats: Codable {
            var totalFiles: Int
            var totalBytes: Int64
        }

        struct CategoryDTO: Codable {
            var id: UUID
            var name: String
            var nameEn: String?
            var colorHex: String?
            var level: Int16
            var sortOrder: Int32
            var createdAt: Date
            var iconName: String?
            var iconType: String?
            var customIconData: Data?
            var parentId: UUID?
        }

        struct StoryDTO: Codable {
            var id: UUID
            var title: String?
            var content: String?
            var plainTextContent: String?
            var createdAt: Date
            var updatedAt: Date
            var timestamp: Date
            var syncStatus: Int16
            var mood: String?
            var locationName: String?
            var locationAddress: String?
            var locationCity: String?
            var latitude: Double
            var longitude: Double
            var horizontalAccuracy: Double
            var verticalAccuracy: Double
        }

        struct MediaDTO: Codable {
            var id: UUID
            var type: String?
            var fileName: String?
            var thumbnailFileName: String?
            var createdAt: Date
            var width: Int32
            var height: Int32
            var duration: Double
            var storyId: UUID?
        }

        struct StoryCategoryRelationDTO: Codable {
            var storyId: UUID
            var categoryId: UUID
        }

        struct MediaFileDescriptor: Codable {
            var relativePath: String
            var fileSize: Int64
        }

        var backupId: UUID
        var appVersion: String
        var schemaVersion: Int
        var createdAt: Date
        var entityStats: EntityStats
        var mediaStats: MediaStats
        var hasBrokenMedia: Bool
        var brokenMediaCount: Int
        var masterKeyBase64: String?
        var categories: [CategoryDTO]
        var stories: [StoryDTO]
        var media: [MediaDTO]
        var relationsStoryCategories: [StoryCategoryRelationDTO]
        var mediaFiles: [MediaFileDescriptor]
    }

    private let context: NSManagedObjectContext
    private let cryptoService = MigrationCryptoService()

    init(context: NSManagedObjectContext) {
        self.context = context
    }

    /// 从加密备份文件恢复数据
    /// - Parameters:
    ///   - encryptedURL: 加密备份文件路径
    ///   - password: 用户迁移密码
    ///   - progressHandler: 进度回调
    func restoreFromEncryptedBackup(encryptedURL: URL,
                                    password: String,
                                    progressHandler: ((Progress) -> Void)? = nil) throws {
        // 1. 从文件名解析 backupId
        guard let backupId = extractBackupId(from: encryptedURL) else {
            throw NSError(domain: "Migration", code: -10, userInfo: [NSLocalizedDescriptionKey: "无法解析备份 ID"])
        }
        progressHandler?(Progress(step: "decrypting", fractionCompleted: 0.05))

        // 2. 解密得到容器文件
        let containerURL = try cryptoService.decryptBackup(encryptedURL: encryptedURL,
                                                           password: password,
                                                           backupId: backupId)

        progressHandler?(Progress(step: "reading_container", fractionCompleted: 0.2))

        // 3. 解析容器文件：MAGIC + JSON 长度 + JSON + 媒体字节
        let (payload, mediaOffsets) = try readContainerFile(url: containerURL)

        progressHandler?(Progress(step: "restoring_master_key", fractionCompleted: 0.3))

        // 4. 恢复 MasterKey
        if let base64 = payload.masterKeyBase64, let keyData = Data(base64Encoded: base64) {
            try importMasterKey(data: keyData)
        }

        progressHandler?(Progress(step: "restoring_media_files", fractionCompleted: 0.45))

        // 5. 恢复媒体文件
        try restoreMediaFiles(containerURL: containerURL,
                              payload: payload,
                              mediaOffsets: mediaOffsets,
                              progressHandler: progressHandler)

        progressHandler?(Progress(step: "restoring_coredata", fractionCompleted: 0.7))

        // 6. 恢复 Core Data 实体
        try restoreCoreData(from: payload)

        // 7. 删除中间产物（解密后的 .bin 容器文件）
        try? FileManager.default.removeItem(at: containerURL)
        print("🗑️ [Restore] 已删除中间容器文件: \(containerURL.lastPathComponent)")

        progressHandler?(Progress(step: "finished", fractionCompleted: 1.0))
    }

    // MARK: - 解析 backupId

    private func extractBackupId(from url: URL) -> UUID? {
        let name = url.deletingPathExtension().lastPathComponent // 例如 "backup-<uuid>"
        let prefix = "backup-"
        guard name.hasPrefix(prefix) else { return nil }
        let idString = String(name.dropFirst(prefix.count))
        return UUID(uuidString: idString)
    }

    // MARK: - 容器文件读取

    private func readContainerFile(url: URL) throws -> (BackupPayload, [Int64]) {
        let handle = try FileHandle(forReadingFrom: url)
        defer { try? handle.close() }

        // MAGIC
        let magicLength = 9
        guard let magicData = try handle.read(upToCount: magicLength),
              magicData.count == magicLength,
              let magicString = String(data: magicData, encoding: .utf8),
              magicString == "MYSTBACK1" else {
            throw NSError(domain: "Migration", code: -11, userInfo: [NSLocalizedDescriptionKey: "备份文件格式不正确"])
        }

        // JSON 长度（UInt64 小端）
        let lengthSize = MemoryLayout<UInt64>.size
        guard let lengthData = try handle.read(upToCount: lengthSize), lengthData.count == lengthSize else {
            throw NSError(domain: "Migration", code: -12, userInfo: [NSLocalizedDescriptionKey: "备份元数据长度读取失败"])
        }
        let jsonLength = lengthData.withUnsafeBytes { ptr -> UInt64 in
            ptr.load(as: UInt64.self)
        }

        // JSON 数据
        guard let jsonData = try handle.read(upToCount: Int(jsonLength)), jsonData.count == Int(jsonLength) else {
            throw NSError(domain: "Migration", code: -13, userInfo: [NSLocalizedDescriptionKey: "备份元数据读取失败"])
        }

        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        let payload = try decoder.decode(BackupPayload.self, from: jsonData)

        // 记录媒体起始偏移
        var offsets: [Int64] = []
        var currentOffset = Int64(magicLength + lengthSize) + Int64(jsonLength)
        for descriptor in payload.mediaFiles {
            offsets.append(currentOffset)
            currentOffset += descriptor.fileSize
        }

        return (payload, offsets)
    }

    // MARK: - MasterKey 导入

    private func importMasterKey(data: Data) throws {
        let account = "MyStory.MasterKey"
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: account
        ]
        let attrs: [String: Any] = [
            kSecValueData as String: data,
            kSecAttrAccessible as String: kSecAttrAccessibleWhenUnlocked
        ]
        SecItemDelete(query as CFDictionary)
        let status = SecItemAdd(query.merging(attrs) { _, new in new } as CFDictionary, nil)
        guard status == errSecSuccess else {
            throw NSError(domain: "Migration", code: Int(status), userInfo: [NSLocalizedDescriptionKey: "MasterKey 写入 Keychain 失败"])
        }
    }

    // MARK: - 媒体文件恢复

    private func restoreMediaFiles(containerURL: URL,
                                   payload: BackupPayload,
                                   mediaOffsets: [Int64],
                                   progressHandler: ((Progress) -> Void)?) throws {
        let fileManager = FileManager.default
        let docs = fileManager.urls(for: .documentDirectory, in: .userDomainMask)[0]
        let mediaRoot = docs.appendingPathComponent(MediaStorageService.baseDirName, isDirectory: true)

        print("📁 [Restore] 目标媒体目录: \(mediaRoot.path)")
        print("📊 [Restore] 待恢复媒体文件数量: \(payload.mediaFiles.count)")
        
        // 清空旧媒体目录
        if fileManager.fileExists(atPath: mediaRoot.path) {
            print("🗑️ [Restore] 删除旧媒体目录")
            try fileManager.removeItem(at: mediaRoot)
        }
        try fileManager.createDirectory(at: mediaRoot, withIntermediateDirectories: true)
        print("✅ [Restore] 创建新媒体目录")

        let handle = try FileHandle(forReadingFrom: containerURL)
        defer { try? handle.close() }

        let totalFiles = max(payload.mediaFiles.count, 1)
        for (index, descriptor) in payload.mediaFiles.enumerated() {
            let offset = mediaOffsets[index]
            try handle.seek(toOffset: UInt64(offset))

            var remaining = descriptor.fileSize
            let chunkSize = 64 * 1024
            var data = Data()
            while remaining > 0 {
                let readCount = Int(min(remaining, Int64(chunkSize)))
                guard let chunk = try handle.read(upToCount: readCount), !chunk.isEmpty else { break }
                data.append(chunk)
                remaining -= Int64(chunk.count)
            }

            let targetURL = mediaRoot.appendingPathComponent(descriptor.relativePath)
            let dir = targetURL.deletingLastPathComponent()
            try fileManager.createDirectory(at: dir, withIntermediateDirectories: true)
            try data.write(to: targetURL, options: [.atomic])
            print("✅ [Restore] 恢复媒体文件: \(descriptor.relativePath) (\(data.count) bytes)")

            let fractionBase = 0.45
            let fractionRange = 0.25
            let progressValue = fractionBase + fractionRange * Double(index + 1) / Double(totalFiles)
            progressHandler?(Progress(step: "restoring_media_files", fractionCompleted: progressValue))
        }
        
        print("✅ [Restore] 媒体文件恢复完成，共 \(payload.mediaFiles.count) 个文件")
    }

    // MARK: - Core Data 恢复

    private func restoreCoreData(from payload: BackupPayload) throws {
        // 1. 清空旧数据
        try context.performAndWait {
            let storyRequest = StoryEntity.fetchRequest()
            let stories = try context.fetch(storyRequest)
            stories.forEach { context.delete($0) }

            let categoryRequest = CategoryEntity.fetchRequest()
            let categories = try context.fetch(categoryRequest)
            categories.forEach { context.delete($0) }

            let mediaRequest = MediaEntity.fetchRequest()
            let media = try context.fetch(mediaRequest)
            media.forEach { context.delete($0) }

            // SettingEntity 如需支持，可在此处一并清除并恢复

            try context.save()
        }

        // 2. 导入分类、故事、媒体和关系
        try context.performAndWait {
            var categoryMap: [UUID: CategoryEntity] = [:]
            var storyMap: [UUID: StoryEntity] = [:]

            // Categories（不设置 parent）
            for dto in payload.categories {
                let entity = CategoryEntity(context: context)
                entity.id = dto.id
                entity.name = dto.name
                entity.nameEn = dto.nameEn
                entity.colorHex = dto.colorHex
                entity.level = dto.level
                entity.sortOrder = dto.sortOrder
                entity.createdAt = dto.createdAt
                entity.iconName = dto.iconName
                entity.iconType = dto.iconType
                entity.customIconData = dto.customIconData
                categoryMap[dto.id] = entity
            }

            // Stories
            for dto in payload.stories {
                let entity = StoryEntity(context: context)
                entity.id = dto.id
                entity.title = dto.title
                entity.content = dto.content
                entity.plainTextContent = dto.plainTextContent
                entity.createdAt = dto.createdAt
                entity.updatedAt = dto.updatedAt
                entity.timestamp = dto.timestamp
                entity.syncStatus = dto.syncStatus
                entity.mood = dto.mood
                entity.locationName = dto.locationName
                entity.locationAddress = dto.locationAddress
                entity.locationCity = dto.locationCity
                entity.latitude = dto.latitude
                entity.longitude = dto.longitude
                entity.horizontalAccuracy = dto.horizontalAccuracy
                entity.verticalAccuracy = dto.verticalAccuracy
                storyMap[dto.id] = entity
            }

            // Media
            for dto in payload.media {
                let entity = MediaEntity(context: context)
                entity.id = dto.id
                entity.type = dto.type
                entity.fileName = dto.fileName
                entity.thumbnailFileName = dto.thumbnailFileName
                entity.createdAt = dto.createdAt
                entity.width = dto.width
                entity.height = dto.height
                entity.duration = dto.duration
                if let storyId = dto.storyId, let story = storyMap[storyId] {
                    entity.story = story
                }
            }

            // Relations: Story <-> Category
            for relation in payload.relationsStoryCategories {
                if let story = storyMap[relation.storyId],
                   let category = categoryMap[relation.categoryId] {
                    story.addToCategories(category)
                }
            }

            // 第二轮：设置 Category parent
            for dto in payload.categories {
                guard let parentId = dto.parentId,
                      let entity = categoryMap[dto.id],
                      let parent = categoryMap[parentId] else { continue }
                entity.parent = parent
            }

            try context.save()
        }
    }
}

