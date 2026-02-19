import SwiftUI

/// 分类卡片显示模式
public enum CategoryCardDisplayMode {
    case children  // 显示子分类数量
    case stories   // 显示故事数量
    case hybrid    // 混合模式：同时显示子目录数和直属故事数
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
                CategoryIconView(
                    model: node.category,
                    size: 42
                )
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
            case .hybrid:
                hybridStatisticsView
            }
        }
        .padding(AppTheme.Spacing.m)
        .background(RoundedRectangle(cornerRadius: AppTheme.Radius.m).strokeBorder(AppTheme.Colors.border.opacity(0.2)))
    }
    
    // MARK: - Helper Properties
    
    /// 子分类数量文本
    private var childrenCountText: String {
        String(format: "category.childrenCount".localized, node.children.count)
    }
    
    /// 混合模式统计视图
    @ViewBuilder
    private var hybridStatisticsView: some View {
        let hasChildren = !node.children.isEmpty
        let hasStories = node.directStoryCount > 0
        
        if hasChildren && hasStories {
            HStack(spacing: AppTheme.Spacing.xs) {
                Text(childrenCountText)
                Text("·")
                Text(String(format: "category.storyCount".localized, node.directStoryCount))
            }
            .font(.footnote)
            .foregroundColor(.secondary)
        } else if hasChildren {
            Text(childrenCountText)
                .font(.footnote)
                .foregroundColor(.secondary)
        } else if hasStories {
            Text(String(format: "category.storyCount".localized, node.directStoryCount))
                .font(.footnote)
                .foregroundColor(.secondary)
        } else {
            Text(childrenCountText)
                .font(.footnote)
                .foregroundColor(.secondary)
        }
    }
}
