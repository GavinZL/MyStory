import SwiftUI

/// 分类层级导航视图
/// 用于显示第二级和第三级分类
struct CategoryLevelView: View {
    // MARK: - Properties
    
    /// 父级分类节点
    let parentNode: CategoryTreeNode
    
    /// 当前层级（2 或 3）
    let currentLevel: Int
    
    /// CategoryViewModel
    @ObservedObject var viewModel: CategoryViewModel
    
    // MARK: - State
    
    @State private var showCategoryForm = false
    
    // MARK: - Initialization
    
    init(parentNode: CategoryTreeNode, currentLevel: Int, viewModel: CategoryViewModel) {
        self.parentNode = parentNode
        self.currentLevel = currentLevel
        self.viewModel = viewModel
    }
    
    // MARK: - Body
    
    var body: some View {
        ScrollView {
            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                ForEach(parentNode.children, id: \.id) { childNode in
                    navigationLink(for: childNode)
                }
            }
            .padding(.horizontal)
        }
        .navigationTitle(navigationTitle)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            toolbarContent
        }
        .sheet(isPresented: $showCategoryForm) {
            CategoryFormView(
                viewModel: viewModel,
                parentNode: parentNode,
                presetLevel: currentLevel
            )
        }
    }
    
    // MARK: - View Components
    
    /// 根据当前层级决定导航链接目标
    @ViewBuilder
    private func navigationLink(for node: CategoryTreeNode) -> some View {
        if currentLevel == 2 {
            // 第二级：点击进入第三级分类列表
            NavigationLink(destination: CategoryLevelView(parentNode: node, currentLevel: 3, viewModel: viewModel)) {
                CategoryCardView(node: node, displayMode: .children)
            }
            .buttonStyle(PlainButtonStyle())
        } else {
            // 第三级：点击进入故事列表
            NavigationLink(destination: CategoryStoryListView(category: node)) {
                CategoryCardView(node: node, displayMode: .stories)
            }
            .buttonStyle(PlainButtonStyle())
        }
    }
    
    @ToolbarContentBuilder
    private var toolbarContent: some ToolbarContent {
        ToolbarItem(placement: .navigationBarTrailing) {
            Button {
                showCategoryForm = true
            } label: {
                Image(systemName: "plus")
            }
        }
    }
    
    // MARK: - Helper Properties
    
    /// 导航栏标题
    private var navigationTitle: String {
        return parentNode.category.name
    }
}

// MARK: - Preview

#Preview {
    NavigationStack {
        CategoryLevelView(
            parentNode: CategoryTreeNode(
                id: UUID(),
                category: CategoryModel(
                    id: UUID(),
                    name: "生活",
                    iconName: "house.fill",
                    colorHex: "#34C759",
                    level: 1,
                    parentId: nil,
                    sortOrder: 0,
                    createdAt: Date()
                ),
                children: [],
                isExpanded: false,
                storyCount: 0
            ),
            currentLevel: 2,
            viewModel: CategoryViewModel(service: InMemoryCategoryService.sample())
        )
    }
}
