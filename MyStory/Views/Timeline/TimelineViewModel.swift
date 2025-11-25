import Foundation
import CoreData

final class TimelineViewModel: ObservableObject {
    @Published var stories: [StoryEntity] = []
    @Published var hasMore: Bool = true

    private var context: NSManagedObjectContext?
    private(set) var pageSize: Int = 20
    private(set) var currentPage: Int = 0
    private(set) var isLoading: Bool = false

    func setContext(_ context: NSManagedObjectContext) {
        if self.context == nil { self.context = context }
    }

    func loadFirstPage() {
        stories.removeAll()
        currentPage = 0
        hasMore = true
        loadNextPage()
    }

    func loadNextPage() {
        guard !isLoading, hasMore, let ctx = context else { return }
        isLoading = true
        let request = NSFetchRequest<StoryEntity>(entityName: "StoryEntity")
        request.fetchLimit = pageSize
        request.fetchOffset = currentPage * pageSize
        request.sortDescriptors = [NSSortDescriptor(key: "timestamp", ascending: false)]
        do {
            let result = try ctx.fetch(request)
            stories.append(contentsOf: result)
            if result.count < pageSize { hasMore = false }
            currentPage += 1
        } catch {
            print("分页加载失败: \(error)")
            hasMore = false
        }
        isLoading = false
    }
}
