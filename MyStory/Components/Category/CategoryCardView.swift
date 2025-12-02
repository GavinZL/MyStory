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
        VStack(spacing: 8) {
            ZStack {
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color(UIColor.secondarySystemBackground))
                    .frame(height: 100)
                Image(systemName: node.category.iconName)
                    .font(.system(size: 42))
                    .foregroundColor(.accentColor)
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
                Text("共 \(node.storyCount) 个故事")
                    .font(.footnote)
                    .foregroundColor(.secondary)
            }
        }
        .padding(12)
        .background(RoundedRectangle(cornerRadius: 12).strokeBorder(.gray.opacity(0.2)))
    }
    
    // MARK: - Helper Properties
    
    /// 子分类数量文本
    private var childrenCountText: String {
        let count = node.children.count
        if node.category.level == 1 {
            return "共 \(count) 个二级分类"
        } else if node.category.level == 2 {
            return "共 \(count) 个三级分类"
        } else {
            return "共 \(count) 个子分类"
        }
    }
}
