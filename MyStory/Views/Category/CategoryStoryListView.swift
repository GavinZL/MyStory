import SwiftUI
import CoreData

/// 分类故事列表视图
/// 显示指定分类及其子分类下的所有故事
struct CategoryStoryListView: View {
    // MARK: - Properties
    
    /// 分类节点
    let category: CategoryTreeNode
    
    // MARK: - Environment
    
    @Environment(\.managedObjectContext) private var context
    @EnvironmentObject private var coreData: CoreDataStack
    
    // MARK: - State
    
    @State private var stories: [StoryEntity] = []
    @State private var selectedStory: StoryEntity?
    @State private var showEditor = false
    @State private var navigateToCategoryList = false
    @State private var tappedCategoryNode: CategoryTreeNode?
    
    // MARK: - Services
    
    @State private var mediaService = MediaStorageService()
    
    // MARK: - Initialization
    
    init(category: CategoryTreeNode) {
        self.category = category
    }
    
    // MARK: - Body
    
    var body: some View {
        ScrollView {
            if stories.isEmpty {
                emptyStateView
            } else {
                storyListView
            }
        }
        .background(
            NavigationLink(destination: categoryDestinationView, isActive: $navigateToCategoryList) {
                EmptyView()
            }
            .hidden()
        )
        .navigationTitle(category.category.name)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            toolbarContent
        }
        .sheet(isPresented: $showEditor) {
            editorSheet
        }
        .onAppear {
            loadStories()
        }
    }
    
    // MARK: - View Components
    
    /// 空状态视图
    private var emptyStateView: some View {
        VStack(spacing: 16) {
            Image(systemName: "tray")
                .font(.system(size: 60))
                .foregroundColor(.secondary)
            
            Text("categoryStory.empty".localized)
                .font(.headline)
                .foregroundColor(.secondary)
            
            Button {
                createNewStory()
            } label: {
                Label("categoryStory.createFirst".localized, systemImage: "plus.circle.fill")
                    .font(.body)
                    .padding(.horizontal, 20)
                    .padding(.vertical, 10)
                    .background(Color.accentColor)
                    .foregroundColor(.white)
                    .cornerRadius(AppTheme.Radius.m)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding()
    }
    
    /// 故事列表视图
    private var storyListView: some View {
        LazyVStack(alignment: .leading, spacing: 20) {
            ForEach(stories, id: \ .objectID) { story in
                storyItemView(story: story)
            }
        }
        .padding(.horizontal, AppTheme.Spacing.s)
        .padding(.vertical, AppTheme.Spacing.m)
    }
    
    /// 单个故事项视图
    private func storyItemView(story: StoryEntity) -> some View {
        VStack(alignment: .leading, spacing: 0) {
            solidLineView
            dateHeaderView(for: story)
            
            HStack(spacing: 2) {
                storyCardButton(for: story)
            }.padding(.horizontal, 8)
        }
    }
    
    /// 从 story 推导分类节点，用于跳转 CategoryStoryListView
    private func categoryNode(from story: StoryEntity) -> CategoryTreeNode? {
        guard let categories = story.categories as? Set<CategoryEntity>, let categoryEntity = categories.first else {
            return nil
        }
        return CategoryTreeNode(
            id: categoryEntity.id ?? UUID(),
            category: CategoryModel(
                id: categoryEntity.id ?? UUID(),
                name: categoryEntity.name ?? "",
                iconName: categoryEntity.iconName ?? "folder.fill",
                colorHex: categoryEntity.colorHex ?? "#007AFF",
                level: Int(categoryEntity.level),
                parentId: categoryEntity.parent?.id,
                sortOrder: Int(categoryEntity.sortOrder),
                createdAt: categoryEntity.createdAt
            ),
            children: [],
            isExpanded: false,
            storyCount: (categoryEntity.stories as? Set<StoryEntity>)?.count ?? 0
        )
    }
    
    /// 日期头部视图
    private func dateHeaderView(for story: StoryEntity) -> some View {
        HStack(alignment: .center, spacing: AppTheme.Spacing.s) {
            // 大号日期数字
            Text(formatDayNumber(story.timestamp))
                .font(.system(size: 28, weight: .bold))
                .foregroundColor(AppTheme.Colors.textPrimary)
            
            // 小号年月时分 + 星期
            VStack(alignment: .leading, spacing: 2) {
                Text(formatYearMonth(story.timestamp))
                    .font(AppTheme.Typography.caption)
                    .foregroundColor(AppTheme.Colors.textSecondary)
                
                Text(formatTime(story.timestamp))
                    .font(AppTheme.Typography.caption)
                    .foregroundColor(AppTheme.Colors.textSecondary)
            }
            
            Spacer()
        }
        .padding(.vertical, AppTheme.Spacing.s)
    }
    
    /// 分隔线
    private var solidLineView: some View {
        Rectangle()
            .fill(AppTheme.Colors.border.opacity(0.3))
            .frame(height: 1)
            .padding(.bottom, AppTheme.Spacing.s)
    }
    
    /// 故事卡片按钮
    @ViewBuilder
    private func storyCardButton(for story: StoryEntity) -> some View {
        NavigationLink(destination: fullScreenDestination(for: story)) {
            StoryCardView(story: story, firstImage: loadCoverImage(for: story), hideCategoryDisplay: true) {
                if let node = categoryNode(from: story) {
                    // 如果与当前分类相同，禁止跳转
                    if node.id == category.id { return }
                    tappedCategoryNode = node
                    navigateToCategoryList = true
                }
            }
        }
        .buttonStyle(PlainButtonStyle())
        .contextMenu {
            contextMenuItems(for: story)
        }
    }
    
    /// 上下文菜单项
    @ViewBuilder
    private func contextMenuItems(for story: StoryEntity) -> some View {
        Button {
            editStory(story)
        } label: {
            Label("categoryStory.edit".localized, systemImage: "pencil")
        }
        
        Button(role: .destructive) {
            deleteStory(story)
        } label: {
            Label("categoryStory.delete".localized, systemImage: "trash")
        }
    }
    
    /// 工具栏内容
    @ToolbarContentBuilder
    private var toolbarContent: some ToolbarContent {
        ToolbarItem(placement: .navigationBarTrailing) {
            Button {
                createNewStory()
            } label: {
                Image(systemName: "plus")
            }
        }
    }
    
    /// 编辑器弹窗
    @ViewBuilder
    private var editorSheet: some View {
        if let story = selectedStory {
            NewStoryEditorView(existingStory: story, category: nil) {
                loadStories()
            }
        } else {
            // 传入分类实体（从 CategoryModel 的 ID 查询）
            let categoryService = CoreDataCategoryService(context: context)
            if let categoryEntity = categoryService.fetchCategory(id: category.id) {
                NewStoryEditorView(existingStory: nil, category: categoryEntity) {
                    loadStories()
                }
            } else {
                NewStoryEditorView(existingStory: nil, category: nil) {
                    loadStories()
                }
            }
        }
    }
    
    /// 全屏故事视图目标
    @ViewBuilder
    private func fullScreenDestination(for story: StoryEntity) -> some View {
        if let index = stories.firstIndex(where: { $0.objectID == story.objectID }) {
            FullScreenStoryView(
                stories: stories,
                initialIndex: index,
                onLoadMore: { },
                hasMoreData: false
            )
        }
    }
    
    /// 分类列表跳转目标
    @ViewBuilder
    private var categoryDestinationView: some View {
        if let node = tappedCategoryNode {
            CategoryStoryListView(category: node)
        } else {
            EmptyView()
        }
    }
    
    // MARK: - Helper Methods
    
    /// 加载故事
    private func loadStories() {
        let categoryIds = collectCategoryIds(category)
        
        let request = StoryEntity.fetchRequest()
        request.predicate = NSPredicate(format: "ANY categories.id IN %@", categoryIds as NSArray)
        request.sortDescriptors = [NSSortDescriptor(keyPath: \StoryEntity.timestamp, ascending: false)]
        
        do {
            stories = try context.fetch(request)
        } catch {
            print("Error fetching stories: \(error)")
            stories = []
        }
    }
    
    /// 递归收集分类及其所有子分类的 ID
    private func collectCategoryIds(_ node: CategoryTreeNode) -> [UUID] {
        var ids = [node.id]
        for child in node.children {
            ids.append(contentsOf: collectCategoryIds(child))
        }
        return ids
    }
    
    /// 加载封面图片
    private func loadCoverImage(for story: StoryEntity) -> UIImage? {
        guard let media = (story.media as? Set<MediaEntity>)?.first else { return nil }
        
        // 根据媒体类型选择正确的加载方法
        if media.type == "video" {
            // 视频封面：优先使用thumbnailFileName
            if let thumbFileName = media.thumbnailFileName {
                return mediaService.loadVideoThumbnail(fileName: thumbFileName)
            }
            return nil
        } else {
            // 图片：优先使用缩略图，其次使用原图
            let fileName = (media.thumbnailFileName ?? media.fileName) ?? ""
            return mediaService.loadImage(fileName: fileName)
        }
    }
    
    // MARK: - Date Formatting
    
    /// 格式化日期数字（日）
    private func formatDayNumber(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "dd"
        return formatter.string(from: date)
    }
    
    /// 格式化年月和星期
    private func formatYearMonth(_ date: Date) -> String {
        let formatter = DateFormatter()
        
        let isChineseLocale = LocalizationManager.shared.currentLanguage == .chinese
        // 根据配置的语言设置 locale
        formatter.locale = Locale(identifier: isChineseLocale ? "zh-Hans" : "en")
        
        if isChineseLocale {
            formatter.dateFormat = "YYYY年MM月 / E"
        } else {
            formatter.dateFormat = "MMM / EEE"
        }
        
        return formatter.string(from: date)
    }
    
    /// 格式化时间
    private func formatTime(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm"
        return formatter.string(from: date)
    }
    
    // MARK: - Actions
    
    /// 创建新故事
    private func createNewStory() {
        selectedStory = nil
        showEditor = true
    }
    
    /// 编辑故事
    private func editStory(_ story: StoryEntity) {
        selectedStory = story
        showEditor = true
    }
    
    /// 删除故事
    private func deleteStory(_ story: StoryEntity) {
        context.delete(story)
        stories.removeAll { $0.objectID == story.objectID }
        coreData.save()
    }
}
