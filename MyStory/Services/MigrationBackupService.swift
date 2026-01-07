import Foundation
import CoreData
import Security

/// 负责导出 Core Data + 媒体文件 + MasterKey 并生成加密备份文件
final class MigrationBackupService {
    struct Progress {
        let step: String
        let fractionCompleted: Double
    }

    /// 元数据 + 实体数据的整体载体（写入容器文件开头的 JSON）
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

        // manifest 信息
        var backupId: UUID
        var appVersion: String
        var schemaVersion: Int
        var createdAt: Date
        var entityStats: EntityStats
        var mediaStats: MediaStats
        var hasBrokenMedia: Bool
        var brokenMediaCount: Int

        // MasterKey（Base64 编码）
        var masterKeyBase64: String?

        // 实体数据
        var categories: [CategoryDTO]
        var stories: [StoryDTO]
        var media: [MediaDTO]
        var relationsStoryCategories: [StoryCategoryRelationDTO]

        // 媒体文件描述（用于恢复时按顺序读写文件）
        var mediaFiles: [MediaFileDescriptor]
    }

    private let context: NSManagedObjectContext
    private let cryptoService = MigrationCryptoService()

    init(context: NSManagedObjectContext) {
        self.context = context
    }

    /// 创建加密备份文件
    /// - Parameters:
    ///   - password: 用户迁移密码
    ///   - progressHandler: 进度回调（可选）
    /// - Returns: 加密后的备份文件路径
    func createEncryptedBackup(password: String,
                               progressHandler: ((Progress) -> Void)? = nil) throws -> URL {
        let backupId = UUID()
        progressHandler?(Progress(step: "collecting_data", fractionCompleted: 0.05))

        // 1. 从 Core Data 导出实体数据
        let payload = try exportCoreDataAndMediaMetadata(backupId: backupId)
        progressHandler?(Progress(step: "building_container", fractionCompleted: 0.3))

        // 2. 构建容器文件（自定义格式）：MAGIC + JSON 长度 + JSON + 媒体文件字节
        let containerURL = try buildContainerFile(payload: payload,
                                                  backupId: backupId,
                                                  progressHandler: progressHandler)

        progressHandler?(Progress(step: "encrypting", fractionCompleted: 0.9))

        // 3. 调用加密服务，生成 .enc 文件
        let encryptedURL = try cryptoService.encryptBackup(zipURL: containerURL,
                                                           password: password,
                                                           backupId: backupId)

        // 4. 删除中间产物（未加密的 .bin 容器文件）
        try? FileManager.default.removeItem(at: containerURL)
        print("🗑️ [Backup] 已删除中间容器文件: \(containerURL.lastPathComponent)")

        progressHandler?(Progress(step: "finished", fractionCompleted: 1.0))
        return encryptedURL
    }

    // MARK: - Core Data 导出

    private func exportCoreDataAndMediaMetadata(backupId: UUID) throws -> BackupPayload {
        var categories: [BackupPayload.CategoryDTO] = []
        var stories: [BackupPayload.StoryDTO] = []
        var mediaItems: [BackupPayload.MediaDTO] = []
        var relations: [BackupPayload.StoryCategoryRelationDTO] = []

        try context.performAndWait {
            // CategoryEntity
            let categoryRequest = CategoryEntity.fetchRequest()
            let categoryResults = try context.fetch(categoryRequest)
            categories = categoryResults.compactMap { category in
                guard let id = category.id,
                      let createdAt = category.createdAt else { return nil }
                let parentId = category.parent?.id
                return BackupPayload.CategoryDTO(
                    id: id,
                    name: category.name ?? "",
                    nameEn: category.nameEn,
                    colorHex: category.colorHex,
                    level: category.level,
                    sortOrder: category.sortOrder,
                    createdAt: createdAt,
                    iconName: category.iconName,
                    iconType: category.iconType,
                    customIconData: category.customIconData,
                    parentId: parentId
                )
            }

            // StoryEntity
            let storyRequest = StoryEntity.fetchRequest()
            let storyResults = try context.fetch(storyRequest)
            stories = storyResults.compactMap { story in
                guard let id = story.id,
                      let createdAt = story.createdAt,
                      let updatedAt = story.updatedAt,
                      let timestamp = story.timestamp else { return nil }

                // 关系：Story <-> Category
                if let categoriesSet = story.categories as? Set<CategoryEntity> {
                    for category in categoriesSet {
                        if let cid = category.id {
                            relations.append(BackupPayload.StoryCategoryRelationDTO(storyId: id, categoryId: cid))
                        }
                    }
                }

                return BackupPayload.StoryDTO(
                    id: id,
                    title: story.title,
                    content: story.content,
                    plainTextContent: story.plainTextContent,
                    createdAt: createdAt,
                    updatedAt: updatedAt,
                    timestamp: timestamp,
                    syncStatus: story.syncStatus,
                    mood: story.mood,
                    locationName: story.locationName,
                    locationAddress: story.locationAddress,
                    locationCity: story.locationCity,
                    latitude: story.latitude,
                    longitude: story.longitude,
                    horizontalAccuracy: story.horizontalAccuracy,
                    verticalAccuracy: story.verticalAccuracy
                )
            }

            // MediaEntity
            let mediaRequest = MediaEntity.fetchRequest()
            let mediaResults = try context.fetch(mediaRequest)
            mediaItems = mediaResults.compactMap { media in
                guard let id = media.id,
                      let createdAt = media.createdAt else { return nil }
                let storyId = media.story?.id
                return BackupPayload.MediaDTO(
                    id: id,
                    type: media.type,
                    fileName: media.fileName,
                    thumbnailFileName: media.thumbnailFileName,
                    createdAt: createdAt,
                    width: media.width,
                    height: media.height,
                    duration: media.duration,
                    storyId: storyId
                )
            }
        }

        // 媒体目录扫描
        let (mediaFiles, mediaStats, hasBrokenMedia, brokenCount) = scanMediaDirectory()

        // MasterKey 导出
        let masterKeyBase64 = exportMasterKey()?.base64EncodedString()

        // 应用版本 & schemaVersion
        let appVersion = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0.0"
        let schemaVersion = 1

        let entityStats = BackupPayload.EntityStats(
            categoryCount: categories.count,
            storyCount: stories.count,
            mediaCount: mediaItems.count
        )

        return BackupPayload(
            backupId: backupId,
            appVersion: appVersion,
            schemaVersion: schemaVersion,
            createdAt: Date(),
            entityStats: entityStats,
            mediaStats: mediaStats,
            hasBrokenMedia: hasBrokenMedia,
            brokenMediaCount: brokenCount,
            masterKeyBase64: masterKeyBase64,
            categories: categories,
            stories: stories,
            media: mediaItems,
            relationsStoryCategories: relations,
            mediaFiles: mediaFiles
        )
    }

    // MARK: - 媒体目录扫描

    private func scanMediaDirectory() -> (
        [BackupPayload.MediaFileDescriptor],
        BackupPayload.MediaStats,
        Bool,
        Int
    ) {
        var descriptors: [BackupPayload.MediaFileDescriptor] = []
        var totalFiles = 0
        var totalBytes: Int64 = 0
        var brokenCount = 0

        let fileManager = FileManager.default
        let docs = fileManager.urls(for: .documentDirectory, in: .userDomainMask)[0]
        let mediaRoot = docs.appendingPathComponent(MediaStorageService.baseDirName, isDirectory: true)

        print("📁 [Backup] 扫描媒体目录: \(mediaRoot.path)")
        guard fileManager.fileExists(atPath: mediaRoot.path) else {
            print("⚠️ [Backup] 媒体目录不存在")
            let stats = BackupPayload.MediaStats(totalFiles: 0, totalBytes: 0)
            return ([], stats, false, 0)
        }

        if let enumerator = fileManager.enumerator(at: mediaRoot,
                                                   includingPropertiesForKeys: [.isRegularFileKey, .fileSizeKey],
                                                   options: [.skipsHiddenFiles]) {
            for case let fileURL as URL in enumerator {
                do {
                    let values = try fileURL.resourceValues(forKeys: [.isRegularFileKey, .fileSizeKey])
                    guard values.isRegularFile == true else { continue }
                    let fileSize = Int64(values.fileSize ?? 0)
                    
                    // 计算相对于 mediaRoot 的相对路径
                    let relativePath: String
                    if let range = fileURL.path.range(of: mediaRoot.path) {
                        let afterRoot = fileURL.path[range.upperBound...]
                        // 移除开头的 /（如果存在）
                        relativePath = afterRoot.trimmingCharacters(in: CharacterSet(charactersIn: "/"))
                    } else {
                        // 降级方案：使用 lastPathComponent
                        relativePath = fileURL.lastPathComponent
                    }
                    
                    descriptors.append(.init(relativePath: relativePath, fileSize: fileSize))
                    totalFiles += 1
                    totalBytes += fileSize
                    print("📄 [Backup] 找到媒体文件: \(relativePath) (\(fileSize) bytes)")
                } catch {
                    brokenCount += 1
                    print("❌ [Backup] 无法读取文件信息: \(error)")
                }
            }
        }

        print("✅ [Backup] 媒体扫描完成: \(totalFiles) 个文件, 总大小 \(totalBytes) bytes")
        let stats = BackupPayload.MediaStats(totalFiles: totalFiles, totalBytes: totalBytes)
        let hasBroken = brokenCount > 0
        return (descriptors, stats, hasBroken, brokenCount)
    }

    // MARK: - MasterKey 导出

    private func exportMasterKey() -> Data? {
        let account = "MyStory.MasterKey"
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: account,
            kSecReturnData as String: true,
            kSecMatchLimit as String: kSecMatchLimitOne
        ]
        var item: CFTypeRef?
        let status = SecItemCopyMatching(query as CFDictionary, &item)
        guard status == errSecSuccess, let data = item as? Data else { return nil }
        return data
    }

    // MARK: - 容器文件构建（简单自定义格式）

    /// 容器格式：
    /// - MAGIC: "MYSTBACK1" (UTF8)
    /// - JSON_LENGTH: 8 字节 UInt64（小端）
    /// - JSON_DATA: BackupPayload 的 JSON
    /// - MEDIA_BYTES: 按 payload.mediaFiles 顺序依次拼接的媒体文件字节
    private func buildContainerFile(payload: BackupPayload,
                                    backupId: UUID,
                                    progressHandler: ((Progress) -> Void)?) throws -> URL {
        let fileManager = FileManager.default
        let docs = fileManager.urls(for: .documentDirectory, in: .userDomainMask)[0]
        let backupsRoot = docs.appendingPathComponent("MigrationBackups", isDirectory: true)
        try fileManager.createDirectory(at: backupsRoot, withIntermediateDirectories: true)

        let containerURL = backupsRoot.appendingPathComponent("backup-\(backupId.uuidString).bin")

        // 编码 JSON 元数据
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        let jsonData = try encoder.encode(payload)

        // 写文件
        fileManager.createFile(atPath: containerURL.path, contents: nil)
        guard let handle = try? FileHandle(forWritingTo: containerURL) else {
            throw NSError(domain: "Migration", code: -1, userInfo: [NSLocalizedDescriptionKey: "无法创建备份容器文件"])
        }
        defer { try? handle.close() }

        // MAGIC
        if let magicData = "MYSTBACK1".data(using: .utf8) {
            handle.write(magicData)
        }

        // JSON 长度（UInt64 小端）
        var length = UInt64(jsonData.count)
        withUnsafeBytes(of: &length) { buffer in
            handle.write(Data(buffer))
        }

        // JSON 数据
        handle.write(jsonData)

        // 媒体字节
        let fileManager2 = FileManager.default
        let docs2 = fileManager2.urls(for: .documentDirectory, in: .userDomainMask)[0]
        let mediaRoot = docs2.appendingPathComponent(MediaStorageService.baseDirName, isDirectory: true)

        let totalFiles = max(payload.mediaFiles.count, 1)
        for (index, descriptor) in payload.mediaFiles.enumerated() {
            let fileURL = mediaRoot.appendingPathComponent(descriptor.relativePath)
            print("📂 [Backup] 尝试读取媒体文件: \(fileURL.path)")
            if fileManager2.fileExists(atPath: fileURL.path) {
                let data = try Data(contentsOf: fileURL)
                handle.write(data)
                print("✅ [Backup] 成功写入媒体文件: \(descriptor.relativePath) (\(data.count) bytes)")
            } else {
                print("❌ [Backup] 媒体文件不存在: \(fileURL.path)")
            }
            let fractionBase = 0.3
            let fractionRange = 0.5 // 从 0.3 到 0.8 之间用于写媒体
            let progressValue = fractionBase + fractionRange * Double(index + 1) / Double(totalFiles)
            progressHandler?(Progress(step: "writing_media", fractionCompleted: progressValue))
        }

        return containerURL
    }
}

