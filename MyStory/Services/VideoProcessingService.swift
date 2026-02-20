//
//  VideoProcessingService.swift
//  MyStory
//
//  Optimized video processing service with async thumbnail generation,
//  progress tracking, and streaming support.
//

import Foundation
@preconcurrency import AVFoundation
import UIKit
import Photos

// MARK: - Video Processing State

enum VideoProcessingState {
    case idle
    case importing(progress: Double)
    case generatingThumbnail
    case completed(url: URL, thumbnail: UIImage?)
    case failed(VideoProcessingError)
}

enum VideoProcessingError: Error, LocalizedError {
    case accessDenied
    case assetNotFound
    case thumbnailGenerationFailed
    case importFailed(Error)
    case cancelled
    case timeout
    
    var errorDescription: String? {
        switch self {
        case .accessDenied: return "video.error.accessDenied".localized
        case .assetNotFound: return "video.error.notFound".localized
        case .thumbnailGenerationFailed: return "video.error.thumbnailFailed".localized
        case .importFailed(let error): return error.localizedDescription
        case .cancelled: return "video.error.cancelled".localized
        case .timeout: return "video.error.timeout".localized
        }
    }
}

// MARK: - Video Metadata

struct VideoMetadata {
    let duration: TimeInterval
    let fileSize: Int64
    let resolution: CGSize
    let codec: String?
    let frameRate: Float?
    
    var formattedDuration: String {
        let minutes = Int(duration) / 60
        let seconds = Int(duration) % 60
        return String(format: "%d:%02d", minutes, seconds)
    }
    
    var formattedFileSize: String {
        let formatter = ByteCountFormatter()
        formatter.allowedUnits = [.useMB, .useGB]
        formatter.countStyle = .file
        return formatter.string(fromByteCount: fileSize)
    }
}

// MARK: - Video Processing Service

final class VideoProcessingService: ObservableObject {
    
    @Published private(set) var state: VideoProcessingState = .idle
    
    private var currentTask: Task<Void, Never>?
    private var isCancelled = false
    
    // Configuration
    private let thumbnailMaxSize: CGSize = CGSize(width: 800, height: 800)
    private let timeoutDuration: TimeInterval = 60  // 60秒超时
    
    // MARK: - Public Methods
    
    /// 快速获取视频元数据（不需要完整加载视频）
    func fetchMetadata(from url: URL) async -> VideoMetadata? {
        let asset = AVURLAsset(url: url, options: [
            AVURLAssetPreferPreciseDurationAndTimingKey: false  // 使用近似值，更快
        ])
        
        do {
            let duration = try await asset.load(.duration)
            let tracks = try await asset.loadTracks(withMediaType: .video)
            
            var resolution: CGSize = .zero
            var frameRate: Float?
            
            if let videoTrack = tracks.first {
                let naturalSize = try await videoTrack.load(.naturalSize)
                let transform = try await videoTrack.load(.preferredTransform)
                
                // 处理视频旋转
                if transform.a == 0 && abs(transform.b) == 1.0 {
                    resolution = CGSize(width: naturalSize.height, height: naturalSize.width)
                } else {
                    resolution = naturalSize
                }
                
                frameRate = try await videoTrack.load(.nominalFrameRate)
            }
            
            // 获取文件大小
            let fileSize: Int64
            if let attributes = try? FileManager.default.attributesOfItem(atPath: url.path),
               let size = attributes[.size] as? Int64 {
                fileSize = size
            } else {
                fileSize = 0
            }
            
            return VideoMetadata(
                duration: CMTimeGetSeconds(duration),
                fileSize: fileSize,
                resolution: resolution,
                codec: nil,
                frameRate: frameRate
            )
        } catch {
            print("获取视频元数据失败: \(error)")
            return nil
        }
    }
    
    /// 快速生成小尺寸缩略图（用于导入后立即显示，<0.5秒）
    /// 使用小尺寸 + 大时间容差，在后台线程同步执行
    func generateQuickThumbnail(from url: URL) async -> UIImage? {
        await Task.detached(priority: .userInitiated) {
            let asset = AVURLAsset(url: url, options: [
                AVURLAssetPreferPreciseDurationAndTimingKey: false
            ])
            let generator = AVAssetImageGenerator(asset: asset)
            generator.appliesPreferredTrackTransform = true
            generator.maximumSize = CGSize(width: 300, height: 300)
            
            // 大时间容差：允许从最近的关键帧取，避免解码耗时
            generator.requestedTimeToleranceBefore = CMTime(seconds: 5, preferredTimescale: 1)
            generator.requestedTimeToleranceAfter = CMTime(seconds: 5, preferredTimescale: 1)
            
            let time = CMTime(seconds: 0.0, preferredTimescale: 1)
            guard let cgImage = try? generator.copyCGImage(at: time, actualTime: nil) else {
                return nil
            }
            return UIImage(cgImage: cgImage)
        }.value
    }
    
    /// 异步生成视频缩略图（使用优化的异步 API）
    func generateThumbnailAsync(from url: URL) async -> UIImage? {
        await MainActor.run {
            state = .generatingThumbnail
        }
        
        let asset = AVURLAsset(url: url, options: [
            AVURLAssetPreferPreciseDurationAndTimingKey: false
        ])
        
        let generator = AVAssetImageGenerator(asset: asset)
        generator.appliesPreferredTrackTransform = true
        generator.maximumSize = thumbnailMaxSize
        
        // 设置时间容差以加快生成速度
        generator.requestedTimeToleranceBefore = CMTime(seconds: 2, preferredTimescale: 60)
        generator.requestedTimeToleranceAfter = CMTime(seconds: 2, preferredTimescale: 60)
        
        let time = CMTime(seconds: 0.5, preferredTimescale: 60)
        
        return await withCheckedContinuation { continuation in
            generator.generateCGImagesAsynchronously(forTimes: [NSValue(time: time)]) { requestedTime, cgImage, actualTime, result, error in
                if let cgImage = cgImage {
                    continuation.resume(returning: UIImage(cgImage: cgImage))
                } else {
                    // 如果异步失败，尝试同步方式作为备选
                    if let syncImage = try? generator.copyCGImage(at: time, actualTime: nil) {
                        continuation.resume(returning: UIImage(cgImage: syncImage))
                    } else {
                        continuation.resume(returning: nil)
                    }
                }
            }
        }
    }
    
    /// 从 PHAsset 导入视频（带进度）
    func importVideo(from asset: PHAsset, progressHandler: @escaping (Double) -> Void) async throws -> URL {
        guard asset.mediaType == .video else {
            throw VideoProcessingError.assetNotFound
        }
        
        isCancelled = false
        
        let options = PHVideoRequestOptions()
        options.version = .current
        options.deliveryMode = .highQualityFormat
        options.isNetworkAccessAllowed = true
        
        // 进度回调
        options.progressHandler = { progress, error, stop, info in
            if self.isCancelled {
                stop.pointee = true
                return
            }
            DispatchQueue.main.async {
                progressHandler(progress)
            }
        }
        
        return try await withCheckedThrowingContinuation { continuation in
            PHImageManager.default().requestAVAsset(forVideo: asset, options: options) { avAsset, audioMix, info in
                if self.isCancelled {
                    continuation.resume(throwing: VideoProcessingError.cancelled)
                    return
                }
                
                guard let urlAsset = avAsset as? AVURLAsset else {
                    // 如果是 AVComposition，需要导出
                    if let composition = avAsset as? AVComposition {
                        Task {
                            do {
                                let url = try await self.exportComposition(composition, progressHandler: progressHandler)
                                continuation.resume(returning: url)
                            } catch {
                                continuation.resume(throwing: error)
                            }
                        }
                        return
                    }
                    continuation.resume(throwing: VideoProcessingError.assetNotFound)
                    return
                }
                
                // 复制到临时目录
                let tempURL = URL.documentsDirectory.appendingPathComponent("temp_\(UUID().uuidString).mov")
                do {
                    try FileManager.default.copyItem(at: urlAsset.url, to: tempURL)
                    continuation.resume(returning: tempURL)
                } catch {
                    continuation.resume(throwing: VideoProcessingError.importFailed(error))
                }
            }
        }
    }
    
    /// 取消当前操作
    func cancel() {
        isCancelled = true
        currentTask?.cancel()
        currentTask = nil
        Task { @MainActor in
            state = .idle
        }
    }
    
    // MARK: - Private Methods
    
    private func exportComposition(_ composition: AVComposition, progressHandler: @escaping (Double) -> Void) async throws -> URL {
        guard let exportSession = AVAssetExportSession(asset: composition, presetName: AVAssetExportPresetHighestQuality) else {
            throw VideoProcessingError.importFailed(NSError(domain: "VideoProcessing", code: -1, userInfo: nil))
        }
        
        let tempURL = URL.documentsDirectory.appendingPathComponent("temp_\(UUID().uuidString).mov")
        exportSession.outputURL = tempURL
        exportSession.outputFileType = .mov
        
        // 进度监控
        let progressTask = Task {
            while exportSession.status == .exporting {
                try? await Task.sleep(nanoseconds: 100_000_000)  // 0.1秒
                await MainActor.run {
                    progressHandler(Double(exportSession.progress))
                }
            }
        }
        
        await exportSession.export()
        progressTask.cancel()
        
        if exportSession.status == .completed {
            return tempURL
        } else if let error = exportSession.error {
            throw VideoProcessingError.importFailed(error)
        } else {
            throw VideoProcessingError.importFailed(NSError(domain: "VideoProcessing", code: -2, userInfo: nil))
        }
    }
}

// MARK: - Video Thumbnail Cache

final class VideoThumbnailCache {
    static let shared = VideoThumbnailCache()
    
    private let cache = NSCache<NSString, UIImage>()
    private let queue = DispatchQueue(label: "com.mystory.thumbnailcache", attributes: .concurrent)
    
    private init() {
        cache.countLimit = 50
        cache.totalCostLimit = 50 * 1024 * 1024  // 50MB
    }
    
    func get(for key: String) -> UIImage? {
        cache.object(forKey: key as NSString)
    }
    
    func set(_ image: UIImage, for key: String) {
        let cost = Int(image.size.width * image.size.height * 4)  // 估算内存占用
        cache.setObject(image, forKey: key as NSString, cost: cost)
    }
    
    func remove(for key: String) {
        cache.removeObject(forKey: key as NSString)
    }
    
    func clearAll() {
        cache.removeAllObjects()
    }
}
