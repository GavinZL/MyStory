//
//  CacheCleanupService.swift
//  MyStory
//
//  缓存清理服务
//

import Foundation

public final class CacheCleanupService {
    
    public struct CleanupResult {
        public let deletedFilesCount: Int
        public let freedSpace: Int64 // 以字节为单位
        public let errors: [String]
        
        public var freedSpaceMB: Double {
            return Double(freedSpace) / 1024.0 / 1024.0
        }
        
        public var isSuccess: Bool {
            return deletedFilesCount > 0 || errors.isEmpty
        }
    }
    
    private static let supportedArchiveExtensions = ["zip", "tar", "gz", "rar", "7z"]
    
    /// 清理应用程序缓存文件
    public static func cleanupCache() -> CleanupResult {
        var deletedCount = 0
        var freedSpace: Int64 = 0
        var errors: [String] = []
        
        let fileManager = FileManager.default
        
        // 获取 Documents 和 Temp 目录
        let documentsURL = fileManager.urls(for: .documentDirectory, in: .userDomainMask).first
        let tempURL = fileManager.temporaryDirectory
        
        // 清理 Documents 目录中的临时文件
        if let documentsURL = documentsURL {
            let result = cleanupDirectory(documentsURL, fileManager: fileManager)
            deletedCount += result.count
            freedSpace += result.space
            errors.append(contentsOf: result.errors)
        }
        
        // 清理系统临时目录
        let tempResult = cleanupDirectory(tempURL, fileManager: fileManager)
        deletedCount += tempResult.count
        freedSpace += tempResult.space
        errors.append(contentsOf: tempResult.errors)
        
        // 清理缓存目录
        if let cacheURL = fileManager.urls(for: .cachesDirectory, in: .userDomainMask).first {
            let cacheResult = cleanupCachesDirectory(cacheURL, fileManager: fileManager)
            deletedCount += cacheResult.count
            freedSpace += cacheResult.space
            errors.append(contentsOf: cacheResult.errors)
        }
        
        return CleanupResult(
            deletedFilesCount: deletedCount,
            freedSpace: freedSpace,
            errors: errors
        )
    }
    
    /// 清理指定目录中的临时文件
    private static func cleanupDirectory(_ directoryURL: URL, fileManager: FileManager) -> (count: Int, space: Int64, errors: [String]) {
        var deletedCount = 0
        var freedSpace: Int64 = 0
        var errors: [String] = []
        
        guard let enumerator = fileManager.enumerator(
            at: directoryURL,
            includingPropertiesForKeys: [.isRegularFileKey, .fileSizeKey],
            options: [.skipsHiddenFiles]
        ) else {
            errors.append("无法访问目录: \(directoryURL.path)")
            return (0, 0, errors)
        }
        
        for case let fileURL as URL in enumerator {
            // 跳过非文件（如目录）
            guard let resourceValues = try? fileURL.resourceValues(forKeys: [.isRegularFileKey]),
                  let isRegularFile = resourceValues.isRegularFile,
                  isRegularFile else {
                continue
            }
            
            let fileName = fileURL.lastPathComponent.lowercased()
            let fileExtension = fileURL.pathExtension.lowercased()
            
            // 判断是否应该删除
            var shouldDelete = false
            
            // 1. 文件名以 "temp" 开头的临时文件
            if fileName.hasPrefix("temp") {
                shouldDelete = true
            }
            
            // 2. 压缩文件（数据同步遗留）
            if supportedArchiveExtensions.contains(fileExtension) {
                shouldDelete = true
            }
            
            // 3. 其他系统临时文件标识
            if fileName.contains(".tmp") || fileName.contains("cache") {
                shouldDelete = true
            }
            
            // 安全检查：确保不删除重要数据文件
            // 排除 Media 目录（用户媒体文件）
            if fileURL.path.contains("/Media/") {
                shouldDelete = false
            }
            
            // 排除 CoreData 数据库文件
            if fileExtension == "sqlite" || fileExtension == "sqlite-shm" || fileExtension == "sqlite-wal" {
                shouldDelete = false
            }
            
            // 排除 .heic 和 .mov 文件（用户媒体）
            if fileExtension == "heic" || fileExtension == "mov" || fileExtension == "jpg" || fileExtension == "jpeg" || fileExtension == "png" {
                // 只有在 temp 开头时才删除
                if !fileName.hasPrefix("temp") {
                    shouldDelete = false
                }
            }
            
            // 执行删除
            if shouldDelete {
                do {
                    // 获取文件大小
                    let fileSize = try fileURL.resourceValues(forKeys: [.fileSizeKey]).fileSize ?? 0
                    
                    // 删除文件
                    try fileManager.removeItem(at: fileURL)
                    
                    deletedCount += 1
                    freedSpace += Int64(fileSize)
                    
                } catch {
                    errors.append("删除文件失败: \(fileName) - \(error.localizedDescription)")
                }
            }
        }
        
        return (deletedCount, freedSpace, errors)
    }
    
    /// 清理系统缓存目录
    private static func cleanupCachesDirectory(_ cacheURL: URL, fileManager: FileManager) -> (count: Int, space: Int64, errors: [String]) {
        var deletedCount = 0
        var freedSpace: Int64 = 0
        var errors: [String] = []
        
        // 只清理缓存目录中的临时文件，不清理整个缓存
        guard let items = try? fileManager.contentsOfDirectory(at: cacheURL, includingPropertiesForKeys: [.isRegularFileKey, .fileSizeKey]) else {
            return (0, 0, errors)
        }
        
        for itemURL in items {
            let fileName = itemURL.lastPathComponent.lowercased()
            
            // 只删除明确的临时文件
            if fileName.hasPrefix("temp") || fileName.contains(".tmp") {
                do {
                    let fileSize = try itemURL.resourceValues(forKeys: [.fileSizeKey]).fileSize ?? 0
                    try fileManager.removeItem(at: itemURL)
                    deletedCount += 1
                    freedSpace += Int64(fileSize)
                } catch {
                    errors.append("删除缓存文件失败: \(fileName) - \(error.localizedDescription)")
                }
            }
        }
        
        return (deletedCount, freedSpace, errors)
    }
    
    /// 计算可清理的缓存大小（不实际删除）
    public static func calculateCacheSize() -> Int64 {
        var totalSize: Int64 = 0
        let fileManager = FileManager.default
        
        let documentsURL = fileManager.urls(for: .documentDirectory, in: .userDomainMask).first
        let tempURL = fileManager.temporaryDirectory
        let cacheURL = fileManager.urls(for: .cachesDirectory, in: .userDomainMask).first
        
        if let documentsURL = documentsURL {
            totalSize += calculateDirectorySize(documentsURL, fileManager: fileManager)
        }
        
        totalSize += calculateDirectorySize(tempURL, fileManager: fileManager)
        
        if let cacheURL = cacheURL {
            totalSize += calculateDirectorySize(cacheURL, fileManager: fileManager)
        }
        
        return totalSize
    }
    
    private static func calculateDirectorySize(_ directoryURL: URL, fileManager: FileManager) -> Int64 {
        var totalSize: Int64 = 0
        
        guard let enumerator = fileManager.enumerator(
            at: directoryURL,
            includingPropertiesForKeys: [.isRegularFileKey, .fileSizeKey],
            options: [.skipsHiddenFiles]
        ) else {
            return 0
        }
        
        for case let fileURL as URL in enumerator {
            guard let resourceValues = try? fileURL.resourceValues(forKeys: [.isRegularFileKey, .fileSizeKey]),
                  let isRegularFile = resourceValues.isRegularFile,
                  isRegularFile else {
                continue
            }
            
            let fileName = fileURL.lastPathComponent.lowercased()
            let fileExtension = fileURL.pathExtension.lowercased()
            
            var shouldCount = false
            
            if fileName.hasPrefix("temp") {
                shouldCount = true
            }
            
            if supportedArchiveExtensions.contains(fileExtension) {
                shouldCount = true
            }
            
            if fileName.contains(".tmp") || fileName.contains("cache") {
                shouldCount = true
            }
            
            // 安全过滤
            if fileURL.path.contains("/Media/") {
                shouldCount = false
            }
            
            if fileExtension == "sqlite" || fileExtension == "sqlite-shm" || fileExtension == "sqlite-wal" {
                shouldCount = false
            }
            
            if (fileExtension == "heic" || fileExtension == "mov" || fileExtension == "jpg" || fileExtension == "jpeg" || fileExtension == "png") && !fileName.hasPrefix("temp") {
                shouldCount = false
            }
            
            if shouldCount {
                if let fileSize = resourceValues.fileSize {
                    totalSize += Int64(fileSize)
                }
            }
        }
        
        return totalSize
    }
}
