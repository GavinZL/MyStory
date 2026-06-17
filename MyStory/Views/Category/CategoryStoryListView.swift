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
        VStack(spacing: AppTheme.Spacing.l) {
            Image(systemName: "tray")
                .font(.system(size: AppTheme.IconSize.hero, weight: .light))
                .foregroundColor(AppTheme.Colors.primary)
                .accessibilityHidden(true)
            
            VStack(spacing: AppTheme.Spacing.s) {
                Text("categoryStory.empty.title".localized)
                    .font(AppTheme.Typography.title3)
                    .foregroundColor(AppTheme.Colors.textPrimary)

                Text("categoryStory.empty.message".localized)
                    .font(AppTheme.Typography.body)
                    .foregroundColor(AppTheme.Colors.textSecondary)
                    .multilineTextAlignment(.center)
                    .fixedSize(horizontal: false, vertical: true)
            }
            
            Button {
                createNewStory()
            } label: {
                Label("categoryStory.createFirst".localized, systemImage: "plus.circle.fill")
            }
//            .buttonStyle(AppTheme.ButtonStyles.primary)
            .accessibilityLabel("categoryStory.createFirst".localized)
        }
        .frame(maxWidth: .infinity, minHeight: 420)
        .padding(.horizontal, AppTheme.Spacing.xl)
        .padding(.vertical, AppTheme.Spacing.xxl)
    }
    
    /// 故事列表视图
    private var storyListView: some View {
        LazyVStack(alignment: .leading, spacing: AppTheme.Spacing.xl) {
            ForEach(Array(stories.enumerated()), id: \.element.objectID) { index, story in
                storyItemView(story: story, isLast: index == stories.count - 1)
            }
        }
        .padding(.horizontal, AppTheme.Spacing.l)
        .padding(.vertical, AppTheme.Spacing.m)
    }
    
    /// 单个故事项视图
    private func storyItemView(story: StoryEntity, isLast: Bool) -> some View {
        HStack(alignment: .top, spacing: AppTheme.Spacing.m) {
            timelineAxisView(isLast: isLast)

            VStack(alignment: .leading, spacing: AppTheme.Spacing.s) {
                dateHeaderView(for: story)
                storyCardButton(for: story)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }

    private func timelineAxisView(isLast: Bool) -> some View {
        VStack(spacing: AppTheme.Spacing.xs) {
            Circle()
                .fill(AppTheme.Colors.primary)
                .frame(width: AppTheme.Metrics.timelineNodeSize, height: AppTheme.Metrics.timelineNodeSize)
                .overlay(
                    Circle()
                        .stroke(AppTheme.Colors.background, lineWidth: 2)
                )

            if !isLast {
                Rectangle()
                    .fill(AppTheme.Surface.timelineAxis)
                    .frame(width: AppTheme.Metrics.timelineLineWidth)
                    .frame(maxHeight: .infinity)
            }
        }
        .frame(width: AppTheme.Metrics.timelineAxisWidth)
        .accessibilityHidden(true)
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
                createdAt: categoryEntity.createdAt ?? Date()
            ),
            children: [],
            isExpanded: false,
            storyCount: (categoryEntity.stories as? Set<StoryEntity>)?.count ?? 0,
            directStoryCount: (categoryEntity.stories as? Set<StoryEntity>)?.count ?? 0
        )
    }
    
    /// 日期头部视图
    private func dateHeaderView(for story: StoryEntity) -> some View {
        let date = story.timestamp ?? Date()
        return HStack(alignment: .center, spacing: AppTheme.Spacing.s) {
            Text(relativeDateLabel(date))
                .font(AppTheme.Typography.headline)
                .foregroundColor(AppTheme.Colors.textPrimary)
            
            Text(formatDayNumber(date))
                .font(AppTheme.Typography.subheadline)
                .foregroundColor(AppTheme.Colors.textSecondary)

            Text(formatTime(date))
                .font(AppTheme.Typography.caption)
                .foregroundColor(AppTheme.Colors.textSecondary)
            
            Spacer()
        }
        .padding(.top, AppTheme.Spacing.xs)
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
            .accessibilityLabel("timeline.create.accessibility".localized)
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
    
    /// 格式化日期数字（月-日格式，与 TimelineView 保持一致）
    private func formatDayNumber(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MM-dd"
        return formatter.string(from: date)
    }

    private func relativeDateLabel(_ date: Date) -> String {
        let calendar = Calendar.current
        if calendar.isDateInToday(date) {
            return "timeline.today".localized
        }
        if calendar.isDateInYesterday(date) {
            return "timeline.yesterday".localized
        }
        return formatYearMonth(date)
    }
    
    /// 格式化年份
    private func formatYearMonth(_ date: Date) -> String {
        let formatter = DateFormatter()
        
        let isChineseLocale = LocalizationManager.shared.currentLanguage == .chinese
        // 根据配置的语言设置 locale
        formatter.locale = Locale(identifier: isChineseLocale ? "zh-Hans" : "en")
        
        if isChineseLocale {
            formatter.dateFormat = "YYYY年"
        } else {
            formatter.dateFormat = "YYYY"
        }
        
        return formatter.string(from: date)
    }
    
    /// 格式化时间和星期
    private func formatTime(_ date: Date) -> String {
        let formatter = DateFormatter()
        
        let isChineseLocale = LocalizationManager.shared.currentLanguage == .chinese
        // 根据配置的语言设置 locale
        formatter.locale = Locale(identifier: isChineseLocale ? "zh-Hans" : "en")
        
        if isChineseLocale {
            formatter.dateFormat = "HH:mm / E"
        } else {
            formatter.dateFormat = "HH:mm / EEE"
        }
        
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
