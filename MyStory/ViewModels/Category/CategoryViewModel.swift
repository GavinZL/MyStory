import Foundation
import Combine

public enum CategoryDisplayMode: String, CaseIterable, Identifiable {
    case card
    case list
    public var id: String { rawValue }
    public var title: String { 
        switch self {
        case .card:
            return "category.mode.card".localized
        case .list:
            return "category.mode.list".localized
        }
    }
}

public final class CategoryViewModel: ObservableObject {
    @Published public private(set) var tree: [CategoryTreeNode] = []
    @Published public var displayMode: CategoryDisplayMode = .card
    @Published public var searchText: String = ""
    @Published public private(set) var searchResults: [CategorySearchResult] = []
    @Published public private(set) var isSearching: Bool = false

    private let service: CategoryService

    public init(service: CategoryService) {
        self.service = service
        load()
    }

    public func load() {
        tree = service.fetchTree()
    }

    public func toggleMode() {
        displayMode = (displayMode == .card) ? .list : .card
    }
    
    // MARK: - Category Management
    
    public func createCategory(name: String, level: Int, parentId: UUID?, iconName: String, colorHex: String) throws {
        try service.addCategory(name: name, level: level, parentId: parentId, iconName: iconName, colorHex: colorHex)
        load()
    }
    
    public func updateCategory(id: UUID, name: String, iconName: String, colorHex: String) throws {
        try service.updateCategory(id: id, name: name, iconName: iconName, colorHex: colorHex)
        load()
    }
    
    public func deleteCategory(id: UUID, mediaService: MediaStorageService) throws {
        try service.deleteCategoryRecursively(id: id, mediaService: mediaService)
        load()
    }
    
    public func getCategoryForEdit(id: UUID) -> CategoryEntity? {
        return service.fetchCategory(id: id)
    }
    
    public func getCategoryStatistics(id: UUID) -> (childrenCount: Int, storyCount: Int) {
        let children = service.childrenCount(for: id)
        let stories = service.totalStoryCount(for: id)
        return (children, stories)
    }
    
    // MARK: - Search
    
    public func performSearch() {
        let keyword = searchText.trimmingCharacters(in: .whitespacesAndNewlines)
        
        guard !keyword.isEmpty else {
            searchResults = []
            isSearching = false
            return
        }
        
        isSearching = true
        searchResults = service.searchStories(keyword: keyword)
    }
    
    public func clearSearch() {
        searchText = ""
        searchResults = []
        isSearching = false
    }
}
