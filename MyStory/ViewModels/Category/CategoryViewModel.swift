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
    @Published public private(set) var hasMoreResults: Bool = false
    @Published public private(set) var totalResultCount: Int = 0
    @Published public private(set) var searchHistory: [SearchHistoryItem] = []

    private let service: CategoryService
    private var cancellables = Set<AnyCancellable>()
    private var allSearchResults: [CategorySearchResult] = []
    private let pageSize = 15
    private let searchHistoryKey = "com.mystory.searchHistory"
    private let maxHistoryCount = 10

    public init(service: CategoryService) {
        self.service = service
        load()
        loadSearchHistory()
        setupSearchDebounce()
    }

    public func load() {
        tree = service.fetchTree()
    }

    public func toggleMode() {
        displayMode = (displayMode == .card) ? .list : .card
    }
    
    // MARK: - Category Management
    
    public func createCategory(name: String, level: Int, parentId: UUID?, iconName: String, colorHex: String, customIconData: Data? = nil, isCustomIcon: Bool = false) throws {
        try service.addCategory(
            name: name,
            level: level,
            parentId: parentId,
            iconName: iconName,
            colorHex: colorHex,
            customIconData: customIconData,
            isCustomIcon: isCustomIcon
        )
        load()
    }
    
    public func updateCategory(id: UUID, name: String, iconName: String, colorHex: String, customIconData: Data? = nil, isCustomIcon: Bool = false) throws {
        try service.updateCategory(
            id: id,
            name: name,
            iconName: iconName,
            colorHex: colorHex,
            customIconData: customIconData,
            isCustomIcon: isCustomIcon
        )
        load()
    }
    
    public func deleteCategory(id: UUID, mediaService: MediaStorageService) throws {
        try service.deleteCategoryRecursively(id: id, mediaService: mediaService)
        load()
    }
    
    public func moveCategory(id: UUID, newParentId: UUID) throws {
        try service.moveCategory(id: id, newParentId: newParentId)
        load()
    }
    
    public func moveStory(storyId: UUID, toCategoryId: UUID) throws {
        try service.moveStory(storyId: storyId, toCategoryId: toCategoryId)
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
    
    /// 搜索关键词数组（空格分隔）
    public var searchKeywords: [String] {
        searchText.trimmingCharacters(in: .whitespacesAndNewlines)
            .lowercased()
            .split(separator: " ")
            .map { String($0) }
            .filter { !$0.isEmpty }
    }
    
    public func performSearch() {
        executeSearch()
    }
    
    /// 从搜索历史中选择关键词进行搜索
    public func searchFromHistory(_ keyword: String) {
        searchText = keyword
        executeSearch()
    }
    
    /// 加载更多搜索结果
    public func loadMoreResults() {
        let currentCount = searchResults.count
        let nextEnd = min(currentCount + pageSize, allSearchResults.count)
        searchResults = Array(allSearchResults.prefix(nextEnd))
        hasMoreResults = nextEnd < allSearchResults.count
    }
    
    public func clearSearch() {
        searchText = ""
        searchResults = []
        allSearchResults = []
        isSearching = false
        hasMoreResults = false
        totalResultCount = 0
    }
    
    // MARK: - Search History
    
    public func addSearchHistory(keyword: String, resultCount: Int) {
        let trimmed = keyword.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        
        // 去重
        searchHistory.removeAll { $0.keyword == trimmed }
        
        let item = SearchHistoryItem(keyword: trimmed, timestamp: Date(), resultCount: resultCount)
        searchHistory.insert(item, at: 0)
        
        if searchHistory.count > maxHistoryCount {
            searchHistory = Array(searchHistory.prefix(maxHistoryCount))
        }
        
        saveSearchHistory()
    }
    
    public func removeSearchHistoryItem(_ item: SearchHistoryItem) {
        searchHistory.removeAll { $0.keyword == item.keyword }
        saveSearchHistory()
    }
    
    public func clearSearchHistory() {
        searchHistory = []
        saveSearchHistory()
    }
    
    // MARK: - Private Methods
    
    private func setupSearchDebounce() {
        // 当 searchText 变为空时立即清除结果
        $searchText
            .removeDuplicates()
            .sink { [weak self] text in
                let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
                if trimmed.isEmpty {
                    self?.allSearchResults = []
                    self?.searchResults = []
                    self?.isSearching = false
                    self?.hasMoreResults = false
                    self?.totalResultCount = 0
                }
            }
            .store(in: &cancellables)
        
        // 防抖执行搜索
        $searchText
            .removeDuplicates()
            .debounce(for: .milliseconds(300), scheduler: RunLoop.main)
            .sink { [weak self] _ in
                self?.executeSearch()
            }
            .store(in: &cancellables)
    }
    
    private func executeSearch() {
        let keyword = searchText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !keyword.isEmpty else { return }
        
        isSearching = true
        allSearchResults = service.searchStories(keyword: keyword)
        let endIndex = min(pageSize, allSearchResults.count)
        searchResults = Array(allSearchResults.prefix(endIndex))
        hasMoreResults = allSearchResults.count > pageSize
        totalResultCount = allSearchResults.count
        isSearching = false
    }
    
    private func loadSearchHistory() {
        guard let data = UserDefaults.standard.data(forKey: searchHistoryKey),
              let items = try? JSONDecoder().decode([SearchHistoryItem].self, from: data) else {
            return
        }
        searchHistory = items
    }
    
    private func saveSearchHistory() {
        if let data = try? JSONEncoder().encode(searchHistory) {
            UserDefaults.standard.set(data, forKey: searchHistoryKey)
        }
    }
}
