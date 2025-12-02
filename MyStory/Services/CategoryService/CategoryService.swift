import Foundation
import CoreData

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
    // 查询
    func fetchTree() -> [CategoryTreeNode]
    func fetchCategory(id: UUID) -> CategoryEntity?
    func fetchCategories(level: Int) -> [CategoryEntity]
    func fetchChildren(parentId: UUID) -> [CategoryEntity]
    
    // 增删改
    func addCategory(name: String, level: Int, parentId: UUID?, iconName: String, colorHex: String) throws
    func updateCategory(id: UUID, name: String, iconName: String, colorHex: String) throws
    func deleteCategory(id: UUID) throws
    
    // 统计
    func storyCount(for id: UUID) -> Int
    func totalStoryCount(for id: UUID) -> Int
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
    
    public func fetchCategory(id: UUID) -> CategoryEntity? {
        // InMemory 服务返回 nil，因为没有 CategoryEntity
        return nil
    }
    
    public func fetchCategories(level: Int) -> [CategoryEntity] {
        // InMemory 服务返回空数组
        return []
    }
    
    public func fetchChildren(parentId: UUID) -> [CategoryEntity] {
        // InMemory 服务返回空数组
        return []
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
    
    public func updateCategory(id: UUID, name: String, iconName: String, colorHex: String) throws {
        guard var category = categories[id] else {
            throw CategoryError.notFound
        }
        
        category.name = name
        category.iconName = iconName
        category.colorHex = colorHex
        categories[id] = category
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
    
    public func totalStoryCount(for id: UUID) -> Int {
        aggregatedStoryCount(for: id)
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

// MARK: - Core Data Category Service

/// Core Data实现的分类服务
public final class CoreDataCategoryService: CategoryService {
    
    // MARK: - Properties
    
    private let context: NSManagedObjectContext
    
    // MARK: - Initialization
    
    public init(context: NSManagedObjectContext) {
        self.context = context
    }
    
    // MARK: - Public Methods
    
    public func fetchTree() -> [CategoryTreeNode] {
        let request = CategoryEntity.fetchRequest()
        request.predicate = NSPredicate(format: "level == 1")
        request.sortDescriptors = [NSSortDescriptor(keyPath: \CategoryEntity.sortOrder, ascending: true)]
        
        // ⚠️ 关键修复：预加载 stories 关系数据，避免 fault 导致计数错误
        request.relationshipKeyPathsForPrefetching = ["stories", "children", "children.stories", "children.children", "children.children.stories"]
        
        do {
            let rootCategories = try context.fetch(request)
            return rootCategories.map { buildNode(from: $0) }
        } catch {
            print("Error fetching category tree: \(error)")
            return []
        }
    }
    
    public func fetchCategory(id: UUID) -> CategoryEntity? {
        let request = CategoryEntity.fetchRequest()
        request.predicate = NSPredicate(format: "id == %@", id as CVarArg)
        request.fetchLimit = 1
        
        // ⚠️ 预加载 stories 关系数据
        request.relationshipKeyPathsForPrefetching = ["stories"]
        
        do {
            return try context.fetch(request).first
        } catch {
            print("Error fetching category \(id): \(error)")
            return nil
        }
    }
    
    public func fetchCategories(level: Int) -> [CategoryEntity] {
        let request = CategoryEntity.fetchRequest()
        request.predicate = NSPredicate(format: "level == %d", level)
        request.sortDescriptors = [NSSortDescriptor(keyPath: \CategoryEntity.sortOrder, ascending: true)]
        
        do {
            return try context.fetch(request)
        } catch {
            print("Error fetching categories at level \(level): \(error)")
            return []
        }
    }
    
    public func fetchChildren(parentId: UUID) -> [CategoryEntity] {
        let request = CategoryEntity.fetchRequest()
        request.predicate = NSPredicate(format: "parent.id == %@", parentId as CVarArg)
        request.sortDescriptors = [NSSortDescriptor(keyPath: \CategoryEntity.sortOrder, ascending: true)]
        
        // ⚠️ 预加载 stories 关系数据
        request.relationshipKeyPathsForPrefetching = ["stories", "children", "children.stories"]
        
        do {
            return try context.fetch(request)
        } catch {
            print("Error fetching children for parent \(parentId): \(error)")
            return []
        }
    }
    
    public func addCategory(name: String, level: Int, parentId: UUID?, iconName: String, colorHex: String) throws {
        // 验证层级
        guard (1...3).contains(level) else {
            throw CategoryError.levelOutOfRange
        }
        
        // 验证父分类
        var parentEntity: CategoryEntity?
        if let parentId = parentId {
            guard let parent = fetchCategory(id: parentId) else {
                throw CategoryError.notFound
            }
            
            // 验证父分类层级正确性
            if level == 2 && parent.level != 1 {
                throw CategoryError.invalidParentLevel
            } else if level == 3 && parent.level != 2 {
                throw CategoryError.invalidParentLevel
            }
            
            parentEntity = parent
            
            // 检查父分类下的子分类数量限制
            let childrenCount = fetchChildren(parentId: parentId).count
            if level == 2 && childrenCount >= 20 {
                throw CategoryError.overLimit
            } else if level == 3 && childrenCount >= 30 {
                throw CategoryError.overLimit
            }
        } else if level != 1 {
            // Level 2和3必须有父分类
            throw CategoryError.invalidParentLevel
        }
        
        // 检查一级分类数量限制
        if level == 1 {
            let level1Count = fetchCategories(level: 1).count
            guard level1Count < 10 else {
                throw CategoryError.overLimit
            }
        }
        
        // 创建新分类
        let category = CategoryEntity(context: context)
        category.id = UUID()
        category.name = name
        category.iconName = iconName
        category.colorHex = colorHex
        category.level = Int16(level)
        category.sortOrder = 0
        category.createdAt = Date()
        category.parent = parentEntity
        
        // 保存
        try context.save()
    }
    
    public func updateCategory(id: UUID, name: String, iconName: String, colorHex: String) throws {
        guard let category = fetchCategory(id: id) else {
            throw CategoryError.notFound
        }
        
        category.name = name
        category.iconName = iconName
        category.colorHex = colorHex
        
        try context.save()
    }
    
    public func deleteCategory(id: UUID) throws {
        guard let category = fetchCategory(id: id) else {
            throw CategoryError.notFound
        }
        
        // 检查是否有子分类
        let children = fetchChildren(parentId: id)
        guard children.isEmpty else {
            throw CategoryError.hasStories
        }
        
        // 检查是否有关联的故事
        let storyCount = self.storyCount(for: id)
        guard storyCount == 0 else {
            throw CategoryError.hasStories
        }
        
        // 删除分类
        context.delete(category)
        try context.save()
    }
    
    public func storyCount(for id: UUID) -> Int {
        guard let category = fetchCategory(id: id) else {
            print("⚠️ [CategoryService] Category not found for id: \(id)")
            return 0
        }
        
        let count = category.stories?.count ?? 0
        print("📊 [CategoryService] storyCount for '\(category.name ?? "Unknown")': \(count)")
        return count
    }
    
    public func totalStoryCount(for id: UUID) -> Int {
        guard let category = fetchCategory(id: id) else {
            print("⚠️ [CategoryService] Category not found for id: \(id)")
            return 0
        }
        
        // 自身的故事数
        let selfCount = category.stories?.count ?? 0
        print("📊 [CategoryService] '\(category.name ?? "Unknown")' self stories: \(selfCount)")
        
        // 递归计算所有子分类的故事数
        var total = selfCount
        let children = fetchChildren(parentId: id)
        
        for child in children {
            if let childId = child.id {
                let childTotal = totalStoryCount(for: childId)
                total += childTotal
            }
        }
        
        print("📊 [CategoryService] '\(category.name ?? "Unknown")' total stories (with children): \(total)")
        return total
    }
    
    // MARK: - Private Methods
    
    private func buildNode(from entity: CategoryEntity) -> CategoryTreeNode {
        let categoryModel = CategoryModel(
            id: entity.id ?? UUID(),
            name: entity.name ?? "",
            iconName: entity.iconName ?? "folder.fill",
            colorHex: entity.colorHex ?? "#007AFF",
            level: Int(entity.level),
            parentId: entity.parent?.id,
            sortOrder: Int(entity.sortOrder),
            createdAt: entity.createdAt ?? Date()
        )
        
        // 递归构建子节点
        let childEntities = (entity.children?.allObjects as? [CategoryEntity]) ?? []
        let sortedChildren = childEntities.sorted { $0.sortOrder < $1.sortOrder }
        let childNodes = sortedChildren.map { buildNode(from: $0) }
        
        // 计算总故事数（包含子分类）
        let storyCount = entity.id.map { totalStoryCount(for: $0) } ?? 0
        
        return CategoryTreeNode(
            id: categoryModel.id,
            category: categoryModel,
            children: childNodes,
            isExpanded: false,
            storyCount: storyCount
        )
    }
}
