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
    @State private var navigateToCategoryList = false
    @State private var tappedCategoryNode: CategoryTreeNode?
    
    // MARK: - Services
    @State private var mediaService = MediaStorageService()
    
    // MARK: - Body
    var body: some View {
        NavigationStack {
            ScrollView {
                storyListView
            }
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
            .onAppear {
                setupViewModel()
            }
        }
    }
    
    // MARK: - View Components
    private var storyListView: some View {
        LazyVStack(alignment: .leading, spacing: 20) {
            ForEach(Array(vm.stories.enumerated()), id: \.element.objectID) { index, story in
                storyItemView(story: story, index: index)
            }
        }
        .padding(.horizontal, AppTheme.Spacing.s)
        .padding(.vertical, AppTheme.Spacing.m)
    }
    
    private func storyItemView(story: StoryEntity, index: Int) -> some View {
        VStack(alignment: .leading, spacing: 0) {
            solidLineView
            dateHeaderView(for: story)
            
            HStack(spacing: 2) {
                storyCardButton(for: story)
            }.padding(.horizontal, 8)
        }
        .onAppear {
            handleItemAppear(index: index)
        }
    }
    
    private func dateHeaderView(for story: StoryEntity) -> some View {
        HStack(alignment: .center, spacing: AppTheme.Spacing.s) {
            // 大号日期数字
            Text(formatDayNumber(story.timestamp!))
                .font(.system(size: 28, weight: .bold))
                .foregroundColor(AppTheme.Colors.textPrimary)
            
            // 小号年月时分 + 星期
            VStack(alignment: .leading, spacing: 2) {
                Text(formatTime(story.timestamp!))
                    .font(AppTheme.Typography.caption)
                    .foregroundColor(AppTheme.Colors.textSecondary)

                Text(formatYearMonth(story.timestamp!))
                    .font(AppTheme.Typography.caption)
                    .foregroundColor(AppTheme.Colors.textSecondary)
                
            }
            
            Spacer()
        }
        .padding(.vertical, AppTheme.Spacing.s)
    }
    
    // 时间下方的细横线
    private var solidLineView: some View {
        Rectangle()
            .fill(AppTheme.Colors.border.opacity(0.3))
            .frame(height: 1)
            .padding(.bottom, AppTheme.Spacing.s)
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
            storyCount: (categoryEntity.stories as? Set<StoryEntity>)?.count ?? 0
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
        if vm.stories.isEmpty { 
            vm.loadFirstPage() 
        }
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
