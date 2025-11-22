import SwiftUI
import PhotosUI

struct TimelineView: View {
    @Environment(\.managedObjectContext) private var context
    @EnvironmentObject private var coreData: CoreDataStack

    @State private var mediaService = MediaStorageService()
    @State private var locationService = LocationService()

    @StateObject private var vm = TimelineViewModel()
    @State private var selectedStory: StoryEntity?
    @State private var showFullScreen = false
    @State private var showEditor = false

    var body: some View {
        NavigationView {
            ScrollView {
                LazyVStack(alignment: .leading, spacing: 20) {
                    ForEach(Array(vm.stories.enumerated()), id: \.element.objectID) { index, story in
                        let media = story.medias?.first
                        let imgName = media?.thumbnailFileName ?? media?.fileName
                        // 加载封面图：视频用封面，图片用缩略图或原图
                        let img = imgName.flatMap { mediaService.loadImage(fileName: $0) }
                        
                        VStack(alignment: .leading, spacing: 12) {
                            HStack(spacing: 8) {
                                Circle()
                                    .stroke(Color.red, lineWidth: 2)
                                    .frame(width: 16, height: 16)
                                Text(Self.formatDate(story.timestamp))
                                    .font(.subheadline)
                                    .foregroundColor(.red)
                            }
                            
                            Button {
                                // 点击进入全屏预览
                                navigateToFullScreen(story: story)
                            } label: {
                                StoryCardView(story: story, firstImage: img)
                            }
                            .buttonStyle(PlainButtonStyle())
                            .contextMenu {
                                Button {
                                    editStory(story)
                                } label: {
                                    Label("编辑", systemImage: "pencil")
                                }
                                Button(role: .destructive) {
                                    delete(story)
                                } label: {
                                    Label("删除", systemImage: "trash")
                                }
                            }
                        }
                        .onAppear {
                            if index >= vm.stories.count - 3 { vm.loadNextPage() }
                        }
                    }
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 12)
            }
            .navigationTitle("时间轴")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        selectedStory = nil
                        showEditor = true
                    } label: {
                        Image(systemName: "plus")
                    }
                }
                ToolbarItem(placement: .navigationBarLeading) {
                    Button {
                        if let first = vm.stories.first {
                            selectedStory = first
                            showFullScreen = true
                        }
                    } label: {
                        Image(systemName: "rectangle.portrait.and.arrow.right")
                    }
                }
            }
            .sheet(isPresented: $showEditor) {
                if let story = selectedStory {
                    StoryEditorView(existingStory: story) {
                        reloadStories()
                    }
                } else {
                    StoryEditorView { reloadStories() }
                }
            }
            .fullScreenCover(isPresented: $showFullScreen) {
                if let story = selectedStory, let index = vm.stories.firstIndex(where: { $0.objectID == story.objectID }) {
                    FullScreenStoryView(stories: vm.stories, initialIndex: index)
                }
            }
            .onAppear {
                vm.setContext(context)
                if vm.stories.isEmpty { vm.loadFirstPage() }
            }
        }
    }

    private func delete(_ story: StoryEntity) {
        context.delete(story)
        vm.stories.removeAll { $0.objectID == story.objectID }
        coreData.save()
    }
    
    private func editStory(_ story: StoryEntity) {
        selectedStory = story
        showEditor = true
    }
    
    private func navigateToFullScreen(story: StoryEntity) {
        selectedStory = story
        showFullScreen = true
    }
    
    private func reloadStories() {
        vm.loadFirstPage()
    }
    
    private static func formatDate(_ date: Date) -> String {
        let f = DateFormatter()
        f.dateFormat = "yyyy年MM月dd日"
        return f.string(from: date)
    }
}
