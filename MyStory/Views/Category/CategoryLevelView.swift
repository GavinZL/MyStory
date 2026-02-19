import SwiftUI
import CoreData

/// 分类层级导航视图
/// 用于显示第二级和第三级分类，同时展示该级别的直属故事
struct CategoryLevelView: View {
    // MARK: - Properties
    
    /// 父级分类节点
    let parentNode: CategoryTreeNode
    
    /// 当前层级（2 或 3）
    let currentLevel: Int
    
    /// CategoryViewModel
    @ObservedObject var viewModel: CategoryViewModel
    
    // MARK: - Environment
    
    @Environment(\.managedObjectContext) private var context
    
    // MARK: - State
    
    @State private var showCategoryForm = false
    @State private var showStoryEditor = false
    @State private var editingCategory: CategoryEntity?
    @State private var categoryToDelete: CategoryTreeNode?
    @State private var showDeleteConfirm = false
    @State private var deleteErrorMessage = ""
    @State private var showDeleteError = false
    @State private var directStories: [StoryEntity] = []
    @State private var navigateToAllStories = false
    
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
            VStack(spacing: AppTheme.Spacing.l) {
                // 分区 1：子分类卡片网格
                if !parentNode.children.isEmpty {
                    subcategoriesSection
                }
                
                // 分区 2：直属故事预览
                if !directStories.isEmpty {
                    directStoriesSection
                }
                
                // 空状态
                if parentNode.children.isEmpty && directStories.isEmpty {
                    emptyStateView
                }
            }
            .padding(.vertical, AppTheme.Spacing.s)
        }
        .background(
            NavigationLink(
                destination: CategoryStoryListView(category: parentNode),
                isActive: $navigateToAllStories
            ) {
                EmptyView()
            }
            .hidden()
        )
        .navigationTitle(navigationTitle)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            toolbarContent
        }
        .sheet(isPresented: $showCategoryForm) {
            if let editing = editingCategory {
                CategoryFormView(viewModel: viewModel, editingCategory: editing)
            } else {
                CategoryFormView(
                    viewModel: viewModel,
                    parentNode: parentNode,
                    presetLevel: currentLevel
                )
            }
        }
        .sheet(isPresented: $showStoryEditor) {
            let categoryService = CoreDataCategoryService(context: context)
            if let categoryEntity = categoryService.fetchCategory(id: parentNode.id) {
                NewStoryEditorView(existingStory: nil, category: categoryEntity) {
                    viewModel.load()
                    loadDirectStories()
                }
            } else {
                NewStoryEditorView(existingStory: nil, category: nil) {
                    viewModel.load()
                    loadDirectStories()
                }
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
        .onAppear {
            loadDirectStories()
        }
    }
    
    // MARK: - View Components
    
    /// 子分类网格区域
    private var subcategoriesSection: some View {
        VStack(alignment: .leading, spacing: AppTheme.Spacing.s) {
            Text("category.subcategoriesTitle".localized)
                .font(AppTheme.Typography.headline)
                .padding(.horizontal)
            
            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                ForEach(parentNode.children, id: \.id) { childNode in
                    navigationLink(for: childNode)
                }
            }
            .padding(.horizontal)
        }
    }
    
    /// 直属故事预览区域
    private var directStoriesSection: some View {
        VStack(alignment: .leading, spacing: AppTheme.Spacing.s) {
            HStack {
                Text("category.directStoriesTitle".localized)
                    .font(AppTheme.Typography.headline)
                
                Spacer()
                
                if directStories.count > 3 {
                    Button {
                        navigateToAllStories = true
                    } label: {
                        Text("category.viewAll".localized)
                            .font(AppTheme.Typography.subheadline)
                            .foregroundColor(AppTheme.Colors.primary)
                    }
                }
            }
            .padding(.horizontal)
            
            LazyVStack(spacing: AppTheme.Spacing.s) {
                ForEach(directStories.prefix(3), id: \.objectID) { story in
                    NavigationLink(destination: storyDetailView(for: story)) {
                        StoryCardView(
                            story: story,
                            firstImage: loadCoverImage(for: story),
                            hideCategoryDisplay: true
                        ) { }
                    }
                    .buttonStyle(PlainButtonStyle())
                }
            }
            .padding(.horizontal, AppTheme.Spacing.s)
        }
    }
    
    /// 空状态视图
    private var emptyStateView: some View {
        VStack(spacing: AppTheme.Spacing.m) {
            Image(systemName: "tray")
                .font(.system(size: 60))
                .foregroundColor(.secondary)
            
            Text("categoryStory.empty".localized)
                .font(.headline)
                .foregroundColor(.secondary)
            
            Button {
                showStoryEditor = true
            } label: {
                Label("category.createStory".localized, systemImage: "plus.circle.fill")
                    .font(.body)
                    .padding(.horizontal, 20)
                    .padding(.vertical, 10)
                    .background(Color.accentColor)
                    .foregroundColor(.white)
                    .cornerRadius(AppTheme.Radius.m)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding(.top, 80)
    }
    
    // MARK: - Navigation Links
    
    /// 根据当前层级决定导航链接目标
    @ViewBuilder
    private func navigationLink(for node: CategoryTreeNode) -> some View {
        if currentLevel == 2 {
            // 第二级：点击进入第三级分类列表
            NavigationLink(destination: CategoryLevelView(parentNode: node, currentLevel: 3, viewModel: viewModel)) {
                CategoryCardView(node: node, displayMode: .hybrid)
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
    
    /// 故事详情视图
    @ViewBuilder
    private func storyDetailView(for story: StoryEntity) -> some View {
        if let index = directStories.firstIndex(where: { $0.objectID == story.objectID }) {
            FullScreenStoryView(
                stories: directStories,
                initialIndex: index,
                onLoadMore: { },
                hasMoreData: false
            )
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
            HStack(spacing: AppTheme.Spacing.m) {
                Button {
                    showStoryEditor = true
                } label: {
                    Image(systemName: "square.and.pencil")
                }
                
                Button {
                    editingCategory = nil
                    showCategoryForm = true
                } label: {
                    Image(systemName: "folder.badge.plus")
                }
            }
        }
    }
    
    // MARK: - Helper Properties
    
    /// 导航栏标题
    private var navigationTitle: String {
        return parentNode.category.name
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
    
    // MARK: - Data Loading
    
    /// 加载当前分类的直属故事
    private func loadDirectStories() {
        let request = StoryEntity.fetchRequest()
        request.predicate = NSPredicate(format: "ANY categories.id == %@", parentNode.id as CVarArg)
        request.sortDescriptors = [NSSortDescriptor(keyPath: \StoryEntity.timestamp, ascending: false)]
        
        do {
            directStories = try context.fetch(request)
        } catch {
            print("Error loading direct stories: \(error)")
            directStories = []
        }
    }
    
    /// 加载封面图片
    private func loadCoverImage(for story: StoryEntity) -> UIImage? {
        guard let media = (story.media as? Set<MediaEntity>)?.first else { return nil }
        
        if media.type == "video" {
            if let thumbFileName = media.thumbnailFileName {
                return mediaService.loadVideoThumbnail(fileName: thumbFileName)
            }
            return nil
        } else {
            let fileName = (media.thumbnailFileName ?? media.fileName) ?? ""
            return mediaService.loadImage(fileName: fileName)
        }
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
                storyCount: 0,
                directStoryCount: 0
            ),
            currentLevel: 2,
            viewModel: CategoryViewModel(service: InMemoryCategoryService.sample())
        )
    }
}
