import SwiftUI
import CoreData
import PhotosUI

// MARK: - Main View
struct TimelineView: View {
    // MARK: - Environment
    @Environment(\.managedObjectContext) private var context
    @EnvironmentObject private var coreData: CoreDataStack
    
    // MARK: - State
    @StateObject private var vm = TimelineViewModel()
    @State private var selectedStory: StoryEntity?
    @State private var showNewStoryEditor = false
    @State private var showSearchView = false
    @State private var navigateToCategoryList = false
    @State private var tappedCategoryNode: CategoryTreeNode?
    
    // MARK: - Services
    @State private var mediaService = MediaStorageService()
    
    // MARK: - Body
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: AppTheme.Spacing.l) {
                    searchEntryView

                    if vm.stories.isEmpty {
                        emptyStateView
                    } else {
                        storyListView
                    }
                }
            }
            .background(AppTheme.Colors.background)
            .background(
                NavigationLink(destination: categoryDestinationView, isActive: $navigateToCategoryList) {
                    EmptyView()
                }
                .hidden()
            )
            .navigationTitle("timeline.title".localized)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                toolbarContent
            }
            .sheet(item: $selectedStory) { story in
                NewStoryEditorView(existingStory: story, category: nil) {
                    reloadStories()
                    selectedStory = nil
                }
            }
            .sheet(isPresented: $showNewStoryEditor) {
                NewStoryEditorView(existingStory: nil, category: nil) {
                    reloadStories()
                }
            }
            .sheet(isPresented: $showSearchView) {
                CategorySearchView(viewModel: CategoryViewModel(service: CoreDataCategoryService(context: context))) { category in
                    tappedCategoryNode = categoryNode(from: category)
                    navigateToCategoryList = tappedCategoryNode != nil
                }
            }
            .onAppear {
                setupViewModel()
            }
        }
    }
    
    // MARK: - View Components
    private var searchEntryView: some View {
        Button {
            showSearchView = true
        } label: {
            HStack(spacing: AppTheme.Spacing.s) {
                Image(systemName: "magnifyingglass")
                    .font(.system(size: AppTheme.IconSize.s, weight: .medium))
                    .foregroundColor(AppTheme.Colors.textSecondary)
                    .accessibilityHidden(true)

                Text("timeline.search.prompt".localized)
                    .font(AppTheme.Typography.subheadline)
                    .foregroundColor(AppTheme.Colors.textSecondary)

                Spacer()
            }
            .frame(minHeight: AppTheme.Metrics.minimumTouchTarget)
            .padding(.horizontal, AppTheme.Spacing.m)
            .background(
                RoundedRectangle(cornerRadius: AppTheme.Radius.m)
                    .fill(AppTheme.Colors.surface)
            )
            .overlay(
                RoundedRectangle(cornerRadius: AppTheme.Radius.m)
                    .stroke(AppTheme.Surface.cardBorder, lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
        .accessibilityLabel("timeline.search.accessibility".localized)
        .padding(.horizontal, AppTheme.Spacing.l)
        .padding(.top, AppTheme.Spacing.m)
    }

    private var emptyStateView: some View {
        VStack(spacing: AppTheme.Spacing.l) {
            Image(systemName: "book.pages")
                .font(.system(size: AppTheme.IconSize.hero, weight: .light))
                .foregroundColor(AppTheme.Colors.primary)
                .accessibilityHidden(true)

            VStack(spacing: AppTheme.Spacing.s) {
                Text("timeline.empty.title".localized)
                    .font(AppTheme.Typography.title2)
                    .foregroundColor(AppTheme.Colors.textPrimary)

                Text("timeline.empty.message".localized)
                    .font(AppTheme.Typography.body)
                    .foregroundColor(AppTheme.Colors.textSecondary)
                    .multilineTextAlignment(.center)
                    .fixedSize(horizontal: false, vertical: true)
            }

            Button {
                createNewStory()
            } label: {
                Label("timeline.empty.create".localized, systemImage: "plus.circle.fill")
            }
//            .buttonStyle(AppTheme.ButtonStyles.primary)
            .accessibilityLabel("timeline.create.accessibility".localized)
        }
        .frame(maxWidth: .infinity, minHeight: 420)
        .padding(.horizontal, AppTheme.Spacing.xl)
        .padding(.vertical, AppTheme.Spacing.xxl)
    }

    private var storyListView: some View {
        LazyVStack(alignment: .leading, spacing: AppTheme.Spacing.xl) {
            ForEach(Array(vm.stories.enumerated()), id: \.element.objectID) { index, story in
                storyItemView(story: story, index: index, isLast: index == vm.stories.count - 1)
            }
        }
        .padding(.horizontal, AppTheme.Spacing.l)
        .padding(.bottom, AppTheme.Spacing.xl)
    }
    
    private func storyItemView(story: StoryEntity, index: Int, isLast: Bool) -> some View {
        HStack(alignment: .top, spacing: AppTheme.Spacing.m) {
            timelineAxisView(isLast: isLast)

            VStack(alignment: .leading, spacing: AppTheme.Spacing.s) {
                dateHeaderView(for: story)
                storyCardButton(for: story)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .onAppear {
            handleItemAppear(index: index)
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
    
    @ViewBuilder
    private func storyCardButton(for story: StoryEntity) -> some View {
        NavigationLink(destination: fullScreenDestination(for: story)) {
            StoryCardView(story: story, firstImage: loadCoverImage(for: story), hideCategoryDisplay: false, onCategoryTap: {
                if let node = categoryNode(from: story) {
                    tappedCategoryNode = node
                    navigateToCategoryList = true
                }
            })
        }
        .buttonStyle(PlainButtonStyle())
        .contextMenu {
            contextMenuItems(for: story)
        }
    }
    
    private func categoryNode(from story: StoryEntity) -> CategoryTreeNode? {
        guard let categories = story.categories as? Set<CategoryEntity>, let categoryEntity = categories.first else {
            return nil
        }
        return categoryNode(from: categoryEntity)
    }

    private func categoryNode(from categoryEntity: CategoryEntity) -> CategoryTreeNode {
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
    
    @ViewBuilder
    private func contextMenuItems(for story: StoryEntity) -> some View {
        Button {
            editStory(story)
        } label: {
            Label("timeline.edit".localized, systemImage: "pencil")
        }
        
        Button(role: .destructive) {
            deleteStory(story)
        } label: {
            Label("timeline.delete".localized, systemImage: "trash")
        }
    }
    
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
    

    
    @ViewBuilder
    private func fullScreenDestination(for story: StoryEntity) -> some View {
        if let index = vm.stories.firstIndex(where: { $0.objectID == story.objectID }) {
            FullScreenStoryView(
                stories: vm.stories,
                initialIndex: index,
                onLoadMore: {
                    vm.loadNextPage()
                },
                hasMoreData: vm.hasMore
            )
        }
    }
    @ViewBuilder
    private var categoryDestinationView: some View {
        if let node = tappedCategoryNode {
            CategoryStoryListView(category: node)
        } else {
            EmptyView()
        }
    }

    // MARK: - Helper Methods
    private func setupViewModel() {
        vm.setContext(context)
        vm.loadFirstPage()
    }
    
    private func handleItemAppear(index: Int) {
        if index >= vm.stories.count - 3 { 
            vm.loadNextPage() 
        }
    }
    
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
    
    // MARK: - Actions
    private func createNewStory() {
        showNewStoryEditor = true
    }
    
    private func editStory(_ story: StoryEntity) {
        selectedStory = story
    }
    
    private func deleteStory(_ story: StoryEntity) {
        context.delete(story)
        vm.stories.removeAll { $0.objectID == story.objectID }
        coreData.save()
    }
    
    private func reloadStories() {
        vm.loadFirstPage()
    }
    
    // MARK: - Date Formatting
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
    
    private static func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        
        let isChineseLocale = LocalizationManager.shared.currentLanguage == .chinese
        // 根据配置的语言设置 locale
        formatter.locale = Locale(identifier: isChineseLocale ? "zh-Hans" : "en")
        
        if isChineseLocale {
            formatter.dateFormat = "MM月 dd, yyyy HH:mm"
        } else {
            formatter.dateFormat = "MMM dd, yyyy HH:mm"
        }
        
        return formatter.string(from: date)
    }
}
