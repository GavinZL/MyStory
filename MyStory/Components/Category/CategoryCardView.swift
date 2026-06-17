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
        VStack(alignment: .leading, spacing: AppTheme.Spacing.m) {
            ZStack {
                RoundedRectangle(cornerRadius: AppTheme.Radius.m)
                    .fill(AppTheme.Surface.subtleFill)
                    .frame(height: AppTheme.Metrics.cardMediaCompactHeight)
                CategoryIconView(
                    model: node.category,
                    size: AppTheme.IconSize.xxl
                )
            }

            Text("category.collection".localized)
                .font(AppTheme.Typography.caption)
                .foregroundColor(AppTheme.Colors.primary)
                .lineLimit(1)

            Text(node.category.name)
                .font(AppTheme.Typography.headline)
                .foregroundColor(AppTheme.Colors.textPrimary)
                .lineLimit(2)
            
            // 根据显示模式显示不同的统计信息
            switch displayMode {
            case .children:
                Text(childrenCountText)
                    .font(AppTheme.Typography.footnote)
                    .foregroundColor(AppTheme.Colors.textSecondary)
            case .stories:
                Text(String(format: "category.storyCount".localized, node.storyCount))
                    .font(AppTheme.Typography.footnote)
                    .foregroundColor(AppTheme.Colors.textSecondary)
            case .hybrid:
                hybridStatisticsView
            }
        }
        .padding(AppTheme.Spacing.l)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: AppTheme.Radius.m)
                .fill(AppTheme.Colors.surface)
        )
        .overlay(
            RoundedRectangle(cornerRadius: AppTheme.Radius.m)
                .stroke(AppTheme.Surface.cardBorder, lineWidth: 1)
        )
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
            .font(AppTheme.Typography.footnote)
            .foregroundColor(AppTheme.Colors.textSecondary)
        } else if hasChildren {
            Text(childrenCountText)
                .font(AppTheme.Typography.footnote)
                .foregroundColor(AppTheme.Colors.textSecondary)
        } else if hasStories {
            Text(String(format: "category.storyCount".localized, node.directStoryCount))
                .font(AppTheme.Typography.footnote)
                .foregroundColor(AppTheme.Colors.textSecondary)
        } else {
            Text(childrenCountText)
                .font(AppTheme.Typography.footnote)
                .foregroundColor(AppTheme.Colors.textSecondary)
        }
    }
}
