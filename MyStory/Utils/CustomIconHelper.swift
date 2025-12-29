import UIKit
import SwiftUI

// MARK: - Custom Icon Helper
/// 自定义图标处理工具类
class CustomIconHelper {
    
    // MARK: - Image Cropping
    
    /// 裁剪图片
    /// - Parameters:
    ///   - image: 原始图片
    ///   - cropRect: 裁剪区域（在原始图片坐标系中）
    ///   - shape: 裁剪形状
    /// - Returns: 裁剪后的图片
    static func cropImage(_ image: UIImage, to cropRect: CGRect, shape: CropShape) -> UIImage? {
        guard let cgImage = image.cgImage else { return nil }
        
        // 计算实际裁剪区域（考虑图片缩放）
        let scale = image.scale
        let scaledCropRect = CGRect(
            x: cropRect.origin.x * scale,
            y: cropRect.origin.y * scale,
            width: cropRect.size.width * scale,
            height: cropRect.size.height * scale
        )
        
        // 裁剪图片
        guard let croppedCGImage = cgImage.cropping(to: scaledCropRect) else { return nil }
        let croppedImage = UIImage(cgImage: croppedCGImage, scale: image.scale, orientation: image.imageOrientation)
        
        // 根据形状进行处理
        switch shape {
        case .rectangle:
            return croppedImage
        case .circle:
            return createCircularImage(from: croppedImage)
        }
    }
    
    /// 创建圆形图片
    /// - Parameter image: 原始图片
    /// - Returns: 圆形图片
    private static func createCircularImage(from image: UIImage) -> UIImage? {
        let size = min(image.size.width, image.size.height)
        let rect = CGRect(x: 0, y: 0, width: size, height: size)
        
        UIGraphicsBeginImageContextWithOptions(rect.size, false, image.scale)
        defer { UIGraphicsEndImageContext() }
        
        guard let context = UIGraphicsGetCurrentContext() else { return nil }
        
        // 创建圆形路径
        let path = UIBezierPath(ovalIn: rect)
        context.addPath(path.cgPath)
        context.clip()
        
        // 绘制图片
        image.draw(in: rect)
        
        return UIGraphicsGetImageFromCurrentImageContext()
    }
    
    // MARK: - Image Resizing
    
    /// 调整图片尺寸
    /// - Parameters:
    ///   - image: 原始图片
    ///   - targetSize: 目标尺寸
    /// - Returns: 调整后的图片
    static func resizeImage(_ image: UIImage, to targetSize: CGSize) -> UIImage? {
        let size = image.size
        
        let widthRatio  = targetSize.width  / size.width
        let heightRatio = targetSize.height / size.height
        
        // 选择较小的比例，确保图片完全适应目标尺寸
        let ratio = min(widthRatio, heightRatio)
        
        let newSize = CGSize(width: size.width * ratio, height: size.height * ratio)
        let rect = CGRect(x: 0, y: 0, width: newSize.width, height: newSize.height)
        
        UIGraphicsBeginImageContextWithOptions(newSize, false, 0.0)
        defer { UIGraphicsEndImageContext() }
        
        image.draw(in: rect)
        
        return UIGraphicsGetImageFromCurrentImageContext()
    }
    
    // MARK: - Data Conversion
    
    /// 将图片转换为PNG数据
    /// - Parameter image: 图片
    /// - Returns: PNG数据
    static func imageToData(_ image: UIImage) -> Data? {
        return image.pngData()
    }
    
    /// 将数据转换为图片
    /// - Parameter data: 图片数据
    /// - Returns: UIImage
    static func dataToImage(_ data: Data) -> UIImage? {
        return UIImage(data: data)
    }
    
    // MARK: - Icon Processing
    
    /// 处理自定义图标（裁剪并调整到标准尺寸）
    /// - Parameters:
    ///   - image: 原始图片
    ///   - cropRect: 裁剪区域
    ///   - shape: 裁剪形状
    ///   - iconSize: 图标尺寸（默认60x60）
    /// - Returns: 处理后的图标数据
    static func processCustomIcon(
        from image: UIImage,
        cropRect: CGRect,
        shape: CropShape,
        iconSize: CGSize = CGSize(width: 60, height: 60)
    ) -> Data? {
        // 1. 裁剪图片
        guard let croppedImage = cropImage(image, to: cropRect, shape: shape) else {
            return nil
        }
        
        // 2. 调整尺寸
        guard let resizedImage = resizeImage(croppedImage, to: iconSize) else {
            return nil
        }
        
        // 3. 转换为数据
        return imageToData(resizedImage)
    }
    
    // MARK: - Image Validation
    
    /// 验证图片是否有效
    /// - Parameter image: 图片
    /// - Returns: 是否有效
    static func isValidImage(_ image: UIImage) -> Bool {
        return image.cgImage != nil && image.size.width > 0 && image.size.height > 0
    }
    
    /// 计算适合显示的图片尺寸（保持宽高比）
    /// - Parameters:
    ///   - image: 原始图片
    ///   - containerSize: 容器尺寸
    /// - Returns: 适合的显示尺寸
    static func calculateFitSize(for image: UIImage, in containerSize: CGSize) -> CGSize {
        let imageSize = image.size
        let widthRatio = containerSize.width / imageSize.width
        let heightRatio = containerSize.height / imageSize.height
        let ratio = min(widthRatio, heightRatio)
        
        return CGSize(
            width: imageSize.width * ratio,
            height: imageSize.height * ratio
        )
    }
}
