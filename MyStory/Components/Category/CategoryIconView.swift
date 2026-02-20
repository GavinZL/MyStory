import SwiftUI

// MARK: - Category Icon View
/// 分类图标视图，支持系统图标和自定义图标
struct CategoryIconView: View {
    
    // MARK: - Constants
    
    /// Assets 中的预置图标列表
    private static let assetIconNames: Set<String> = [
        "hand_up", "heart_balloon", "idea", "landscape",
        "love", "people", "map", "present",
        "running", "sales", "school", "shopping"
    ]
    
    // MARK: - Properties
    
    /// 分类实体（可选）
    let categoryEntity: CategoryEntity?
    
    /// 分类模型（可选）
    let categoryModel: CategoryModel?
    
    /// 图标尺寸
    let size: CGFloat
    
    /// 图标颜色
    let color: Color
    
    // MARK: - Initialization
    
    /// 使用 CategoryEntity 初始化
    init(entity: CategoryEntity, size: CGFloat = 42, color: Color? = nil) {
        self.categoryEntity = entity
        self.categoryModel = nil
        self.size = size
        self.color = color ?? (entity.colorHex.flatMap { Color(hex: $0) } ?? AppTheme.Colors.primary)
    }
    
    /// 使用 CategoryModel 初始化
    init(model: CategoryModel, size: CGFloat = 42, color: Color? = nil) {
        self.categoryEntity = nil
        self.categoryModel = model
        self.size = size
        self.color = color ?? Color(hex: model.colorHex) ?? AppTheme.Colors.primary
    }
    
    // MARK: - Body
    
    var body: some View {
        Group {
            if isCustomIcon {
                // 显示用户上传的自定义图标
                if let iconData = customIconData,
                   let uiImage = UIImage(data: iconData) {
                    Image(uiImage: uiImage)
                        .resizable()
                        .scaledToFill()
                        .frame(width: size, height: size)
                        .clipShape(Circle())
                } else {
                    // 降级处理：显示默认系统图标
                    sfSymbolIconView(name: "folder.fill")
                }
            } else if Self.assetIconNames.contains(iconName) {
                // 显示 Assets 中的预置图标
                assetIconView
            } else {
                // 显示 SF Symbols 系统图标
                sfSymbolIconView(name: iconName)
            }
        }
    }
    
    // MARK: - Private Views
    
    /// SF Symbols 系统图标视图
    private func sfSymbolIconView(name: String) -> some View {
        Image(systemName: name)
            .font(.system(size: size))
            .foregroundColor(color)
    }
    
    /// Assets 预置图标视图
    private var assetIconView: some View {
        Image(iconName)
            .renderingMode(.template)
            .resizable()
            .scaledToFit()
            .frame(width: size, height: size)
            .foregroundColor(color)
    }
    
    // MARK: - Helper Properties
    
    /// 是否为自定义图标
    private var isCustomIcon: Bool {
        if let entity = categoryEntity {
            return entity.iconType == "custom"
        } else if let model = categoryModel {
            return model.iconType == "custom"
        }
        return false
    }
    
    /// 自定义图标数据
    private var customIconData: Data? {
        if let entity = categoryEntity {
            return entity.customIconData
        } else if let model = categoryModel {
            return model.customIconData
        }
        return nil
    }
    
    /// 图标名称（系统图标）
    private var iconName: String {
        if let entity = categoryEntity {
            return entity.iconName ?? "folder.fill"
        } else if let model = categoryModel {
            return model.iconName
        }
        return "folder.fill"
    }
}

// MARK: - Preview
#Preview {
    VStack(spacing: 20) {
        // 系统图标示例
        CategoryIconView(
            model: CategoryModel(
                id: UUID(),
                name: "Test",
                iconName: "star.fill",
                colorHex: "#007AFF",
                level: 1,
                parentId: nil,
                sortOrder: 0,
                createdAt: Date()
            ),
            size: 60
        )
    }
    .padding()
}
