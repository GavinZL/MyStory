import Foundation

// MARK: - Crop Shape
/// 图片裁剪形状
enum CropShape: String, CaseIterable {
    case rectangle = "rectangle"
    case circle = "circle"
    
    var displayName: String {
        switch self {
        case .rectangle:
            return "方框"
        case .circle:
            return "圆形"
        }
    }
    
    var iconName: String {
        switch self {
        case .rectangle:
            return "square"
        case .circle:
            return "circle"
        }
    }
}

// MARK: - Icon Type
/// 图标类型
enum IconType: String {
    case system = "system"
    case custom = "custom"
}
