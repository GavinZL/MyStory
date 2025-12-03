import SwiftUI

/// 分类卡片显示模式
public enum CategoryCardDisplayMode {
    case children  // 显示子分类数量
    case stories   // 显示故事数量
}

public struct CategoryCardView: View {
    public let node: CategoryTreeNode
    public let displayMode: CategoryCardDisplayMode

    public init(node: CategoryTreeNode, displayMode: CategoryCardDisplayMode = .stories) {
        self.node = node
        self.displayMode = displayMode
    }

    public var body: some View {
        VStack(spacing: AppTheme.Spacing.s) {
            ZStack {
                RoundedRectangle(cornerRadius: AppTheme.Radius.m)
                    .fill(Color(UIColor.secondarySystemBackground))
                    .frame(height: 100)
                Image(systemName: node.category.iconName)
                    .font(.system(size: 42))
                    .foregroundColor(AppTheme.Colors.primary)
            }
            Text(node.category.name)
                .font(.headline)
            
            // 根据显示模式显示不同的统计信息
            switch displayMode {
            case .children:
                Text(childrenCountText)
                    .font(.footnote)
                    .foregroundColor(.secondary)
            case .stories:
                Text(String(format: "category.storyCount".localized, node.storyCount))
                    .font(.footnote)
                    .foregroundColor(.secondary)
            }
        }
        .padding(AppTheme.Spacing.m)
        .background(RoundedRectangle(cornerRadius: AppTheme.Radius.m).strokeBorder(AppTheme.Colors.border.opacity(0.2)))
    }
    
    // MARK: - Helper Properties
    
    /// 子分类数量文本
    private var childrenCountText: String {
        let count = node.children.count
        if node.category.level == 1 {
            return String(format: "category.secondLevelCount".localized, count)
        } else if node.category.level == 2 {
            return String(format: "category.thirdLevelCount".localized, count)
        } else {
            return String(format: "category.childrenCount".localized, count)
        }
    }
}
