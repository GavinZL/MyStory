import SwiftUI

public struct CategoryCardView: View {
    public let node: CategoryTreeNode

    public init(node: CategoryTreeNode) {
        self.node = node
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
            Text("共 \(node.storyCount) 个故事")
                .font(.footnote)
                .foregroundColor(.secondary)
        }
        .padding(12)
        .background(RoundedRectangle(cornerRadius: 12).strokeBorder(.gray.opacity(0.2)))
    }
}
