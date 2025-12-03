import SwiftUI

public struct CategoryView: View {
    @ObservedObject private var viewModel: CategoryViewModel
    
    // MARK: - State
    @State private var showCategoryForm = false
    @State private var showSearchView = false  // 控制搜索视图显示
    @State private var expandedCategories: Set<UUID> = []  // 用于跟踪展开的分类
    @State private var selectedCategory: CategoryEntity?  // 用于搜索结果跳转
    @State private var navigateToStoryList = false  // 控制跳转到故事列表

    public init(viewModel: CategoryViewModel) {
        self.viewModel = viewModel
    }

    public var body: some View {
        VStack(spacing: 12) {
            Picker("category.displayMode".localized, selection: $viewModel.displayMode) {
                ForEach(CategoryDisplayMode.allCases) { mode in
                    Text(mode.title).tag(mode)
                }
            }
            .pickerStyle(.segmented)
            .padding(.horizontal)

            // 显示分类列表
            switch viewModel.displayMode {
            case .card:
                cardGrid
            case .list:
                listTree
            }
        }
        .navigationTitle("category.title".localized)
        .toolbar {
            toolbarContent
        }
        .sheet(isPresented: $showCategoryForm) {
            CategoryFormView(viewModel: viewModel)
        }
        .sheet(isPresented: $showSearchView) {
            CategorySearchView(viewModel: viewModel) { category in
                // 搜索结果点击回调：跳转到故事列表
                handleSearchResultSelection(category)
            }
        }
        .background(
            // 隐藏的 NavigationLink 用于跳转到故事列表
            NavigationLink(
                destination: destinationView,
                isActive: $navigateToStoryList
            ) {
                EmptyView()
            }
            .hidden()
        )
        .onAppear {
            // 重新加载分类树以更新故事计数
            viewModel.load()
        }
    }

    private var cardGrid: some View {
        ScrollView {
            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                // 只显示一级分类
                ForEach(viewModel.tree, id: \.id) { node in
                    NavigationLink(destination: CategoryLevelView(parentNode: node, currentLevel: 2, viewModel: viewModel)) {
                        CategoryCardView(node: node, displayMode: .children)
                    }
                    .buttonStyle(PlainButtonStyle())
                }
            }
            .padding(.horizontal)
        }
    }

    private var listTree: some View {
        List {
            ForEach(viewModel.tree) { level1Node in
                CategoryListItem(
                    node: level1Node,
                    level: 1,
                    expandedCategories: $expandedCategories,
                    viewModel: viewModel  // 传递 viewModel
                )
            }
        }
        .listStyle(.insetGrouped)
    }

    private func row(_ node: CategoryTreeNode) -> some View {
        NavigationLink(destination: CategoryStoryListView(category: node)) {
            HStack {
                Image(systemName: node.category.iconName)
                    .frame(width: 24)
                Text(node.category.name)
                Spacer()
                Text(String(format: "category.storyCount".localized, node.storyCount))
                    .foregroundColor(.secondary)
                    .font(.footnote)
            }
        }
    }

    @ToolbarContentBuilder
    private var toolbarContent: some ToolbarContent {
        ToolbarItem(placement: .navigationBarTrailing) {
            HStack(spacing: 16) {
                Button {
                    showSearchView = true
                } label: {
                    Image(systemName: "magnifyingglass")
                }
                
                Button {
                    showCategoryForm = true
                } label: {
                    Image(systemName: "plus")
                }
            }
        }
    }
    
    // MARK: - Helper Functions
    
    /// 计算分类的子分类数量
    private func childrenCount(_ node: CategoryTreeNode) -> Int {
        return node.children.count
    }
    
    /// 处理搜索结果选择
    private func handleSearchResultSelection(_ category: CategoryEntity) {
        selectedCategory = category
        navigateToStoryList = true
    }
    
    /// 目标视图（TimelineView 按分类筛选）
    @ViewBuilder
    private var destinationView: some View {
        if let category = selectedCategory {
            CategoryStoryListView(category: CategoryTreeNode(
                id: category.id ?? UUID(),
                category: CategoryModel(
                    id: category.id ?? UUID(),
                    name: category.name ?? "",
                    iconName: category.iconName ?? "folder.fill",
                    colorHex: category.colorHex ?? "#007AFF",
                    level: Int(category.level),
                    parentId: category.parent?.id,
                    sortOrder: Int(category.sortOrder),
                    createdAt: category.createdAt ?? Date()
                ),
                children: [],
                isExpanded: false,
                storyCount: category.stories?.count ?? 0
            ))
        } else {
            EmptyView()
        }
    }
}

// MARK: - Category List Item

/// 分类列表项组件
private struct CategoryListItem: View {
    let node: CategoryTreeNode
    let level: Int  // 1, 2, or 3
    @Binding var expandedCategories: Set<UUID>
    @ObservedObject var viewModel: CategoryViewModel  // 新增
    
    var body: some View {
        Group {
            if level == 3 {
                // 三级分类：根据是否有故事决定行为
                CategoryStoryNavigationView(node: node, viewModel: viewModel) {
                    categoryRow
                }
            } else {
                // 一级和二级分类：点击展开/折叠
                Button(action: toggleExpansion) {
                    categoryRow
                }
                .buttonStyle(PlainButtonStyle())
                
                // 如果展开，显示子分类
                if isExpanded && !node.children.isEmpty {
                    ForEach(node.children) { childNode in
                        CategoryListItem(
                            node: childNode,
                            level: level + 1,
                            expandedCategories: $expandedCategories,
                            viewModel: viewModel  // 传递 viewModel
                        )
                        .padding(.leading, 24)  // 缩进显示层级
                    }
                }
            }
        }
    }
    
    // MARK: - View Components
    
    private var categoryRow: some View {
        HStack(spacing: 12) {
            // 展开/折叠指示器（只有一二级且有子分类时显示）
            if level < 3 && !node.children.isEmpty {
                Image(systemName: isExpanded ? "chevron.down" : "chevron.right")
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .frame(width: 16)
            } else if level < 3 {
                // 占位，保持对齐
                Color.clear.frame(width: 16)
            }
            
            // 分类图标
            Image(systemName: node.category.iconName)
                .foregroundColor(Color(hex: node.category.colorHex))
                .frame(width: 24)
            
            // 分类名称
            Text(node.category.name)
                .font(.body)
            
            Spacer()
            
            // 统计信息
            Text(statisticsText)
                .foregroundColor(.secondary)
                .font(.footnote)
            
            // 三级分类显示导航箭头
            if level == 3 {
                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .padding(.vertical, 4)
        .contentShape(Rectangle())  // 确保整个区域可点击
    }
    
    // MARK: - Helper Properties
    
    /// 是否展开
    private var isExpanded: Bool {
        expandedCategories.contains(node.id)
    }
    
    /// 统计信息文本
    private var statisticsText: String {
        switch level {
        case 1:
            // 一级分类：显示子目录数量
            let count = node.children.count
            return String(format: "category.childrenCount".localized, count)
        case 2:
            // 二级分类：显示子目录数量（三级分类数量）
            let count = node.children.count
            return String(format: "category.childrenCount".localized, count)
        case 3:
            // 三级分类：显示故事数量
            return String(format: "category.storyCount".localized, node.storyCount)
        default:
            return ""
        }
    }
    
    // MARK: - Actions
    
    /// 切换展开/折叠状态
    private func toggleExpansion() {
        if expandedCategories.contains(node.id) {
            expandedCategories.remove(node.id)
        } else {
            expandedCategories.insert(node.id)
        }
    }
}

// MARK: - Category Story Navigation View

/// 三级分类导航视图
/// 根据是否有故事决定显示故事列表还是创建故事
private struct CategoryStoryNavigationView<Content: View>: View {
    let node: CategoryTreeNode
    let content: Content
    @ObservedObject var viewModel: CategoryViewModel  // 新增
    
    @Environment(\.managedObjectContext) private var context
    @State private var showEditor = false
    @State private var navigateToStories = false
    
    init(node: CategoryTreeNode, viewModel: CategoryViewModel, @ViewBuilder content: () -> Content) {
        self.node = node
        self.viewModel = viewModel
        self.content = content()
    }
    
    var body: some View {
        Button(action: handleTap) {
            content
        }
        .buttonStyle(PlainButtonStyle())
        .sheet(isPresented: $showEditor) {
            // 从 node 中查询分类实体
            let categoryService = CoreDataCategoryService(context: context)
            if let categoryEntity = categoryService.fetchCategory(id: node.id) {
                StoryEditorView(category: categoryEntity) {
                    // 创建完成后的回调，刷新分类树
                    viewModel.load()
                }
            } else {
                StoryEditorView {
                    // 如果查询失败，不传入分类
                    viewModel.load()
                }
            }
        }
        .background(
            // 隐藏的 NavigationLink，当有故事时使用
            NavigationLink(
                destination: CategoryStoryListView(category: node),
                isActive: $navigateToStories
            ) {
                EmptyView()
            }
            .hidden()
        )
    }
    
    // MARK: - Helper Properties
    
    /// 是否有故事
    private var hasStories: Bool {
        return node.storyCount > 0
    }
    
    // MARK: - Actions
    
    /// 处理点击事件
    private func handleTap() {
        if hasStories {
            // 有故事：跳转到故事列表
            navigateToStories = true
        } else {
            // 没有故事：显示创建故事编辑器
            showEditor = true
        }
    }
}
