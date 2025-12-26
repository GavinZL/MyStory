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
    @State private var editingCategory: CategoryEntity?  // 编辑的分类
    @State private var categoryToDelete: CategoryTreeNode?  // 要删除的分类
    @State private var showDeleteConfirm = false  // 显示删除确认对话框
    @State private var deleteErrorMessage = ""  // 删除错误消息
    @State private var showDeleteError = false  // 显示删除错误
    
    // MARK: - Services
    @State private var mediaService = MediaStorageService()
    
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
            if let editing = editingCategory {
                // 编辑模式
                CategoryFormView(viewModel: viewModel, editingCategory: editing)
            } else {
                // 创建模式
                CategoryFormView(
                    viewModel: viewModel,
                    parentNode: parentNode,
                    presetLevel: currentLevel
                )
            }
        }
        .alert("category.deleteConfirm.title".localized, isPresented: $showDeleteConfirm) {
            Button("common.cancel".localized, role: .cancel) {}
            Button("common.delete".localized, role: .destructive) {
                performDelete()
            }
        } message: {
            if let category = categoryToDelete {
                let stats = viewModel.getCategoryStatistics(id: category.id)
                Text(String(format: "category.deleteConfirm.message".localized, category.category.name, stats.childrenCount, stats.storyCount))
            }
        }
        .alert("category.deleteFailed".localized, isPresented: $showDeleteError) {
            Button("common.confirm".localized, role: .cancel) {}
        } message: {
            Text(deleteErrorMessage)
        }
    }
    
    // MARK: - Actions
    
    /// 执行删除操作
    private func performDelete() {
        guard let category = categoryToDelete else { return }
        
        do {
            try viewModel.deleteCategory(id: category.id, mediaService: mediaService)
            categoryToDelete = nil
        } catch {
            deleteErrorMessage = error.localizedDescription
            showDeleteError = true
        }
    }
    
    /// 编辑分类
    private func editCategory(_ node: CategoryTreeNode) {
        editingCategory = viewModel.getCategoryForEdit(id: node.id)
        showCategoryForm = true
    }
    
    /// 准备删除分类
    private func prepareDeleteCategory(_ node: CategoryTreeNode) {
        categoryToDelete = node
        showDeleteConfirm = true
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
            .contextMenu {
                contextMenuItems(for: node)
            }
        } else {
            // 第三级：点击进入故事列表
            NavigationLink(destination: CategoryStoryListView(category: node)) {
                CategoryCardView(node: node, displayMode: .stories)
            }
            .buttonStyle(PlainButtonStyle())
            .contextMenu {
                contextMenuItems(for: node)
            }
        }
    }
    
    /// 上下文菜单项
    @ViewBuilder
    private func contextMenuItems(for node: CategoryTreeNode) -> some View {
        Button {
            editCategory(node)
        } label: {
            Label("category.edit".localized, systemImage: "pencil")
        }
        
        Button(role: .destructive) {
            prepareDeleteCategory(node)
        } label: {
            Label("category.delete".localized, systemImage: "trash")
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
