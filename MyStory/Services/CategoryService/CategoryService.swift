import Foundation

public enum CategoryError: Error, LocalizedError {
    case levelOutOfRange
    case overLimit
    case hasStories
    case notFound
    case invalidParentLevel

    public var errorDescription: String? {
        switch self {
        case .levelOutOfRange: return "分类层级必须在 1-3 范围内"
        case .overLimit: return "该层级或父分类已达到数量上限"
        case .hasStories: return "该分类或其子分类仍有关联故事，无法删除"
        case .notFound: return "未找到分类"
        case .invalidParentLevel: return "父分类层级不匹配"
        }
    }
}

public protocol CategoryService {
    func fetchTree() -> [CategoryTreeNode]
    func addCategory(name: String, level: Int, parentId: UUID?, iconName: String, colorHex: String) throws
    func deleteCategory(id: UUID) throws
    func storyCount(for id: UUID) -> Int
}

public final class InMemoryCategoryService: CategoryService {
    private var categories: [UUID: CategoryModel] = [:]
    private var childrenMap: [UUID: [UUID]] = [:]
    private var storyCounts: [UUID: Int] = [:]

    public init() {}

    public static func sample() -> InMemoryCategoryService {
        let svc = InMemoryCategoryService()
        // 初始化时只创建一个 Default 分类
        let defaultCategory = CategoryModel(
            id: UUID(),
            name: "Default",
            iconName: "folder.fill",
            colorHex: "#007AFF",
            level: 1,
            parentId: nil,
            sortOrder: 0,
            createdAt: Date()
        )
        
        svc.categories[defaultCategory.id] = defaultCategory
        svc.childrenMap[defaultCategory.id] = []
        svc.storyCounts[defaultCategory.id] = 0
        return svc
    }

    public func fetchTree() -> [CategoryTreeNode] {
        let roots = categories.values.filter { $0.level == 1 }
            .sorted { $0.sortOrder < $1.sortOrder }
        return roots.map { buildNode(for: $0.id) }
    }

    public func addCategory(name: String, level: Int, parentId: UUID?, iconName: String, colorHex: String) throws {
        guard (1...3).contains(level) else { throw CategoryError.levelOutOfRange }
        let id = UUID()
        let new = CategoryModel(id: id, name: name, iconName: iconName, colorHex: colorHex, level: level, parentId: parentId, sortOrder: 0, createdAt: Date())

        switch level {
        case 1:
            let l1Count = categories.values.filter { $0.level == 1 }.count
            guard l1Count < 10 else { throw CategoryError.overLimit }
        case 2:
            guard let pid = parentId, let parent = categories[pid], parent.level == 1 else {
                throw CategoryError.invalidParentLevel
            }
            let childCount = (childrenMap[pid] ?? []).count
            guard childCount < 20 else { throw CategoryError.overLimit }
            childrenMap[pid, default: []].append(id)
        case 3:
            guard let pid = parentId, let parent = categories[pid], parent.level == 2 else {
                throw CategoryError.invalidParentLevel
            }
            let childCount = (childrenMap[pid] ?? []).count
            guard childCount < 30 else { throw CategoryError.overLimit }
            childrenMap[pid, default: []].append(id)
        default:
            throw CategoryError.levelOutOfRange
        }

        categories[id] = new
        if childrenMap[id] == nil { childrenMap[id] = [] }
        storyCounts[id] = 0
    }

    public func deleteCategory(id: UUID) throws {
        guard let cat = categories[id] else { throw CategoryError.notFound }
        let total = aggregatedStoryCount(for: id)
        guard total == 0 else { throw CategoryError.hasStories }
        // 不能有子分类
        guard (childrenMap[id] ?? []).isEmpty else { throw CategoryError.hasStories }
        // 从父节点移除
        if let pid = cat.parentId {
            childrenMap[pid] = (childrenMap[pid] ?? []).filter { $0 != id }
        }
        childrenMap[id] = nil
        storyCounts[id] = nil
        categories[id] = nil
    }

    public func storyCount(for id: UUID) -> Int {
        storyCounts[id] ?? 0
    }

    private func buildNode(for id: UUID) -> CategoryTreeNode {
        guard let cat = categories[id] else { fatalError("Category not found") }
        let childIds = childrenMap[id] ?? []
        let childNodes = childIds.map { buildNode(for: $0) }
        let total = aggregatedStoryCount(for: id)
        return CategoryTreeNode(id: id, category: cat, children: childNodes, isExpanded: false, storyCount: total)
    }

    private func aggregatedStoryCount(for id: UUID) -> Int {
        let selfCount = storyCounts[id] ?? 0
        let childIds = childrenMap[id] ?? []
        return selfCount + childIds.reduce(0) { $0 + aggregatedStoryCount(for: $1) }
    }
}
