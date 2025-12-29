import SwiftUI
import UIKit

// MARK: - Image Cropper View Model
class ImageCropperViewModel: ObservableObject {
    
    // MARK: - Published Properties
    
    /// 原始图片
    @Published var originalImage: UIImage
    
    /// 选中的裁剪形状
    @Published var selectedShape: CropShape = .rectangle
    
    /// 裁剪框的位置和尺寸
    @Published var cropRect: CGRect
    
    /// 图片显示尺寸（在视图中的尺寸）
    @Published var displayImageSize: CGSize = .zero
    
    /// 图片显示位置（在视图中的位置）
    @Published var displayImageOffset: CGSize = .zero
    
    // MARK: - Private Properties
    
    /// 最小裁剪框尺寸
    private let minCropSize: CGFloat = 60
    
    /// 裁剪框初始尺寸比例（相对于图片）
    private let initialCropSizeRatio: CGFloat = 0.6
    
    // MARK: - Initialization
    
    init(image: UIImage) {
        self.originalImage = image
        
        // 初始化裁剪框（居中，占图片60%）
        let imageSize = image.size
        let cropSize = min(imageSize.width, imageSize.height) * initialCropSizeRatio
        self.cropRect = CGRect(
            x: (imageSize.width - cropSize) / 2,
            y: (imageSize.height - cropSize) / 2,
            width: cropSize,
            height: cropSize
        )
    }
    
    // MARK: - Public Methods
    
    /// 更新显示图片的尺寸和位置
    /// - Parameters:
    ///   - containerSize: 容器尺寸
    func updateDisplayInfo(containerSize: CGSize) {
        // 计算图片在容器中的显示尺寸（保持宽高比）
        displayImageSize = CustomIconHelper.calculateFitSize(for: originalImage, in: containerSize)
        
        // 计算图片居中偏移
        displayImageOffset = CGSize(
            width: (containerSize.width - displayImageSize.width) / 2,
            height: (containerSize.height - displayImageSize.height) / 2
        )
    }
    
    /// 更新裁剪框位置
    /// - Parameter translation: 拖动偏移量（在显示坐标系中）
    func updateCropPosition(translation: CGSize) {
        let scale = getScale()
        
        // 将显示坐标系的偏移转换为原始图片坐标系
        let imageTranslation = CGSize(
            width: translation.width / scale,
            height: translation.height / scale
        )
        
        // 更新裁剪框位置
        var newRect = cropRect
        newRect.origin.x += imageTranslation.width
        newRect.origin.y += imageTranslation.height
        
        // 限制裁剪框不超出图片边界
        newRect.origin.x = max(0, min(newRect.origin.x, originalImage.size.width - newRect.width))
        newRect.origin.y = max(0, min(newRect.origin.y, originalImage.size.height - newRect.height))
        
        cropRect = newRect
    }
    
    /// 更新裁剪框尺寸
    /// - Parameter scale: 缩放比例
    func updateCropSize(scale: CGFloat) {
        let displayScale = getScale()
        
        // 计算新尺寸（在原始图片坐标系中）
        var newSize = cropRect.size.width * scale
        
        // 限制最小尺寸
        let minSize = minCropSize / displayScale
        newSize = max(newSize, minSize)
        
        // 限制最大尺寸（不超过图片）
        let maxSize = min(originalImage.size.width, originalImage.size.height)
        newSize = min(newSize, maxSize)
        
        // 计算新的裁剪框
        var newRect = cropRect
        let sizeDiff = newSize - cropRect.size.width
        
        // 从中心扩展/收缩
        newRect.origin.x -= sizeDiff / 2
        newRect.origin.y -= sizeDiff / 2
        newRect.size.width = newSize
        newRect.size.height = newSize
        
        // 调整位置确保不超出边界
        if newRect.origin.x < 0 {
            newRect.origin.x = 0
        }
        if newRect.origin.y < 0 {
            newRect.origin.y = 0
        }
        if newRect.maxX > originalImage.size.width {
            newRect.origin.x = originalImage.size.width - newRect.width
        }
        if newRect.maxY > originalImage.size.height {
            newRect.origin.y = originalImage.size.height - newRect.height
        }
        
        cropRect = newRect
    }
    
    /// 切换裁剪形状
    /// - Parameter shape: 新的裁剪形状
    func changeShape(_ shape: CropShape) {
        selectedShape = shape
    }
    
    /// 执行裁剪并返回处理后的图标数据
    /// - Returns: 图标数据
    func cropAndProcess() -> Data? {
        return CustomIconHelper.processCustomIcon(
            from: originalImage,
            cropRect: cropRect,
            shape: selectedShape
        )
    }
    
    /// 获取裁剪框在显示坐标系中的位置和尺寸
    /// - Returns: 显示坐标系中的裁剪框
    func getDisplayCropRect() -> CGRect {
        let scale = getScale()
        
        return CGRect(
            x: cropRect.origin.x * scale + displayImageOffset.width,
            y: cropRect.origin.y * scale + displayImageOffset.height,
            width: cropRect.size.width * scale,
            height: cropRect.size.height * scale
        )
    }
    
    // MARK: - Private Methods
    
    /// 获取显示缩放比例（显示尺寸 / 原始尺寸）
    /// - Returns: 缩放比例
    private func getScale() -> CGFloat {
        return displayImageSize.width / originalImage.size.width
    }
}
