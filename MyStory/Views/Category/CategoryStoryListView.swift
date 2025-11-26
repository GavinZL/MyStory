import SwiftUI
import CoreData

// MARK: - Category Story List View
struct CategoryStoryListView: View {
    // MARK: - Properties
    let category: CategoryTreeNode
    
    // MARK: - Environment
    @Environment(\.managedObjectContext) private var context
    @EnvironmentObject private var coreData: CoreDataStack
    
    // MARK: - FetchRequest
    @FetchRequest private var stories: FetchedResults<StoryEntity>
    
    // MARK: - State
    @State private var showEditor = false
    @State private var selectedStory: StoryEntity?
    
    // MARK: - Initializer
    init(category: CategoryTreeNode) {
        self.category = category
        
        // 初始化 FetchRequest（目前获取所有故事，后续可按分类过滤）
        _stories = FetchRequest<StoryEntity>(
            sortDescriptors: [NSSortDescriptor(keyPath: \StoryEntity.timestamp, ascending: false)],
            animation: .default
        )
    }
    
    // MARK: - Body
    var body: some View {
        Group {
            if stories.isEmpty {
                emptyStateView
            } else {
                storyListView
            }
        }
        .navigationTitle(category.category.name)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            toolbarContent
        }
        .sheet(isPresented: $showEditor) {
            editorSheet
        }
    }
    
    // MARK: - View Components
    private var emptyStateView: some View {
        VStack(spacing: 20) {
            Image(systemName: "doc.text")
                .font(.system(size: 60))
                .foregroundColor(.secondary)
            
            Text("暂无故事")
                .font(.title2)
                .fontWeight(.medium)
            
            Text("点击右上角 + 按钮创建新故事")
                .font(.body)
                .foregroundColor(.secondary)
            
            Button {
                createNewStory()
            } label: {
                Label("创建新故事", systemImage: "plus.circle.fill")
                    .font(.headline)
                    .padding(.horizontal, 24)
                    .padding(.vertical, 12)
                    .background(Color.accentColor)
                    .foregroundColor(.white)
                    .cornerRadius(10)
            }
        }
    }
    
    private var storyListView: some View {
        List {
            ForEach(stories, id: \.objectID) { story in
                storyRow(story: story)
                    .contentShape(Rectangle())
                    .onTapGesture {
                        selectedStory = story
                        showEditor = true
                    }
            }
        }
        .listStyle(.plain)
    }
    
    private func storyRow(story: StoryEntity) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(story.title)
                .font(.headline)
            
            if let content = story.content, !content.isEmpty {
                Text(content)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .lineLimit(2)
            }
            
            HStack {
                if let city = story.locationCity {
                    Label(city, systemImage: "mappin.circle")
                        .font(.caption)
                        .foregroundColor(.blue)
                }
                
                Spacer()
                
                Text(formatDate(story.timestamp))
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .padding(.vertical, 8)
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
                selectedStory = nil
            }
        } else {
            StoryEditorView {
                selectedStory = nil
            }
        }
    }
    
    // MARK: - Actions
    private func createNewStory() {
        selectedStory = nil
        showEditor = true
    }
    
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy年MM月dd日"
        return formatter.string(from: date)
    }
}
