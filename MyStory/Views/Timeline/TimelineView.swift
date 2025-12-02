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
    @State private var showEditor = false
    
    // MARK: - Services
    @State private var mediaService = MediaStorageService()
    
    // MARK: - Body
    var body: some View {
        NavigationStack {
            ScrollView {
                storyListView
            }
            .navigationTitle("时间轴")
            .toolbar {
                toolbarContent
            }
            .sheet(isPresented: $showEditor) {
                editorSheet
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
        .padding(.horizontal, 8)
        .padding(.vertical, 12)
    }
    
    private func storyItemView(story: StoryEntity, index: Int) -> some View {
        VStack(alignment: .leading, spacing: 0) {
            dateHeaderView(for: story)
            solidLineView
            
            HStack(spacing: 2) {
                storyCardButton(for: story)
            }.padding(.horizontal, 8)
        }
        .onAppear {
            handleItemAppear(index: index)
        }
    }
    
    private func dateHeaderView(for story: StoryEntity) -> some View {
        HStack(spacing: 8) {
            Text(Self.formatDate(story.timestamp ?? Date(timeIntervalSinceNow: 0)))
                .font(.headline)
                .foregroundColor(.black)
        }
        .padding(.vertical, 8)
    }
    
    // 时间下方的细横线
    private var solidLineView: some View {
        Rectangle()
            .fill(Color.gray.opacity(0.3))
            .frame(height: 1)
            .padding(.bottom, 8)
    }
    
    @ViewBuilder
    private func storyCardButton(for story: StoryEntity) -> some View {
        NavigationLink(destination: fullScreenDestination(for: story)) {
            StoryCardView(story: story, firstImage: loadCoverImage(for: story))
        }
        .buttonStyle(PlainButtonStyle())
        .contextMenu {
            contextMenuItems(for: story)
        }
    }
    
    @ViewBuilder
    private func contextMenuItems(for story: StoryEntity) -> some View {
        Button {
            editStory(story)
        } label: {
            Label("编辑", systemImage: "pencil")
        }
        
        Button(role: .destructive) {
            deleteStory(story)
        } label: {
            Label("删除", systemImage: "trash")
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
    private var editorSheet: some View {
        if let story = selectedStory {
            StoryEditorView(existingStory: story) {
                reloadStories()
            }
        } else {
            StoryEditorView { 
                reloadStories() 
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
        selectedStory = nil
        showEditor = true
    }
    
    private func editStory(_ story: StoryEntity) {
        selectedStory = story
        showEditor = true
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
    private static func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy年MM月dd日 HH:MM"
        return formatter.string(from: date)
    }
}
