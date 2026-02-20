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
    func addCategory(name: String, level: Int, parentId: UUID?, iconName: String, colorHex: String, customIconData: Data?, isCustomIcon: Bool) throws
    func updateCategory(id: UUID, name: String, iconName: String, colorHex: String, customIconData: Data?, isCustomIcon: Bool) throws
    func moveCategory(id: UUID, newParentId: UUID) throws
    func deleteCategory(id: UUID) throws
    func deleteCategoryRecursively(id: UUID, mediaService: MediaStorageService) throws
    
    // 故事操作
    func moveStory(storyId: UUID, toCategoryId: UUID) throws
    
    // 统计
    func storyCount(for id: UUID) -> Int
    func totalStoryCount(for id: UUID) -> Int
    func childrenCount(for id: UUID) -> Int
    
    // 搜索
    func searchStories(keyword: String) -> [CategorySearchResult]
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

    public func addCategory(name: String, level: Int, parentId: UUID?, iconName: String, colorHex: String, customIconData: Data? = nil, isCustomIcon: Bool = false) throws {
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
    
    public func updateCategory(id: UUID, name: String, iconName: String, colorHex: String, customIconData: Data? = nil, isCustomIcon: Bool = false) throws {
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
    
    public func moveCategory(id: UUID, newParentId: UUID) throws {
        // InMemory 服务：简单更新 parentId
        guard var cat = categories[id] else { throw CategoryError.notFound }
        guard categories[newParentId] != nil else { throw CategoryError.notFound }
        if let oldPid = cat.parentId {
            childrenMap[oldPid] = (childrenMap[oldPid] ?? []).filter { $0 != id }
        }
        cat = CategoryModel(id: cat.id, name: cat.name, iconName: cat.iconName, colorHex: cat.colorHex, level: cat.level, parentId: newParentId, sortOrder: cat.sortOrder, createdAt: cat.createdAt)
        categories[id] = cat
        childrenMap[newParentId] = (childrenMap[newParentId] ?? []) + [id]
    }
    
    public func deleteCategoryRecursively(id: UUID, mediaService: MediaStorageService) throws {
        // InMemory 服务不支持此功能
        throw CategoryError.notFound
    }
    
    public func moveStory(storyId: UUID, toCategoryId: UUID) throws {
        // InMemory 服务不支持此功能
        throw CategoryError.notFound
    }
    
    public func childrenCount(for id: UUID) -> Int {
        return (childrenMap[id] ?? []).count
    }

    public func storyCount(for id: UUID) -> Int {
        storyCounts[id] ?? 0
    }
    
    public func totalStoryCount(for id: UUID) -> Int {
        aggregatedStoryCount(for: id)
    }
    
    public func searchStories(keyword: String) -> [CategorySearchResult] {
        // InMemory 服务不实现搜索功能
        return []
    }

    private func buildNode(for id: UUID) -> CategoryTreeNode {
        guard let cat = categories[id] else { fatalError("Category not found") }
        let childIds = childrenMap[id] ?? []
        let childNodes = childIds.map { buildNode(for: $0) }
        let total = aggregatedStoryCount(for: id)
        return CategoryTreeNode(id: id, category: cat, children: childNodes, isExpanded: false, storyCount: total, directStoryCount: storyCounts[id] ?? 0)
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
    
    public func addCategory(name: String, level: Int, parentId: UUID?, iconName: String, colorHex: String, customIconData: Data? = nil, isCustomIcon: Bool = false) throws {
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
        
        // 设置自定义图标
        if isCustomIcon {
            category.iconType = "custom"
            category.customIconData = customIconData
        } else {
            category.iconType = "system"
            category.customIconData = nil
        }
        
        // 保存
        try context.save()
    }
    
    public func updateCategory(id: UUID, name: String, iconName: String, colorHex: String, customIconData: Data? = nil, isCustomIcon: Bool = false) throws {
        guard let category = fetchCategory(id: id) else {
            throw CategoryError.notFound
        }
        
        category.name = name
        category.iconName = iconName
        category.colorHex = colorHex
        
        // 更新自定义图标
        if isCustomIcon {
            category.iconType = "custom"
            category.customIconData = customIconData
        } else {
            category.iconType = "system"
            category.customIconData = nil
        }
        
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
    
    public func moveCategory(id: UUID, newParentId: UUID) throws {
        guard let category = fetchCategory(id: id) else {
            throw CategoryError.notFound
        }
        guard let newParent = fetchCategory(id: newParentId) else {
            throw CategoryError.notFound
        }
        
        // 验证目标父分类层级正确性
        let expectedParentLevel = category.level - 1
        guard newParent.level == expectedParentLevel else {
            throw CategoryError.invalidParentLevel
        }
        
        // 验证不能移动到自身
        guard id != newParentId else {
            throw CategoryError.invalidParentLevel
        }
        
        // 验证目标父分类的子分类数量限制
        let targetChildrenCount = fetchChildren(parentId: newParentId).count
        if category.level == 2 && targetChildrenCount >= 20 {
            throw CategoryError.overLimit
        } else if category.level == 3 && targetChildrenCount >= 30 {
            throw CategoryError.overLimit
        }
        
        // 执行移动：更新 parent 关系
        category.parent = newParent
        try context.save()
    }
    
    /// 递归删除分类、所有子分类、关联故事及媒体文件
    public func deleteCategoryRecursively(id: UUID, mediaService: MediaStorageService) throws {
        guard let category = fetchCategory(id: id) else {
            throw CategoryError.notFound
        }
        
        // 1. 递归删除所有子分类
        let children = fetchChildren(parentId: id)
        for child in children {
            if let childId = child.id {
                try deleteCategoryRecursively(id: childId, mediaService: mediaService)
            }
        }
        
        // 2. 删除该分类下的所有故事及其媒体文件
        if let stories = category.stories as? Set<StoryEntity> {
            for story in stories {
                // 删除故事的媒体文件
                if let media = story.media as? Set<MediaEntity> {
                    for mediaEntity in media {
                        deleteMediaFiles(for: mediaEntity, using: mediaService)
                    }
                }
                
                // 删除故事实体
                context.delete(story)
            }
        }
        
        // 3. 删除分类本身
        context.delete(category)
        
        // 4. 保存更改
        try context.save()
    }
    
    /// 移动故事到指定分类
    /// 将故事从所有当前分类中移除，添加到新分类
    public func moveStory(storyId: UUID, toCategoryId: UUID) throws {
        // 查询故事
        let storyRequest = StoryEntity.fetchRequest()
        storyRequest.predicate = NSPredicate(format: "id == %@", storyId as CVarArg)
        storyRequest.fetchLimit = 1
        
        guard let story = try context.fetch(storyRequest).first else {
            throw CategoryError.notFound
        }
        
        // 查询目标分类
        guard let targetCategory = fetchCategory(id: toCategoryId) else {
            throw CategoryError.notFound
        }
        
        // 移除故事当前的所有分类关联
        if let currentCategories = story.categories as? Set<CategoryEntity> {
            for category in currentCategories {
                story.removeFromCategories(category)
            }
        }
        
        // 添加到新分类
        story.addToCategories(targetCategory)
        
        // 保存更改
        try context.save()
    }
    
    public func childrenCount(for id: UUID) -> Int {
        return fetchChildren(parentId: id).count
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
    
    // MARK: - Search
    
    public func searchStories(keyword: String) -> [CategorySearchResult] {
        guard !keyword.isEmpty else { return [] }
        
        let trimmedKeyword = keyword.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        var results: [CategorySearchResult] = []
        
        // 获取所有有故事的分类，并预加载 stories 关系数据
        let request = CategoryEntity.fetchRequest()
        request.predicate = NSPredicate(format: "stories.@count > 0")
        request.sortDescriptors = [NSSortDescriptor(keyPath: \CategoryEntity.sortOrder, ascending: true)]
        // ⚠️ 关键：预加载 stories 关系数据，避免 fault 导致数据为空
        request.relationshipKeyPathsForPrefetching = ["stories", "parent", "parent.parent"]
        
        var categoriesWithStories: [CategoryEntity] = []
        do {
            categoriesWithStories = try context.fetch(request)
        } catch {
            print("⚠️ [CategoryService] Error fetching categories for search: \(error)")
            return []
        }
        
        for category in categoriesWithStories {
            var matchedStories: [StoryMatch] = []
            
            // 1. 搜索分类名称
            let categoryNameMatch = (category.name ?? "").lowercased().contains(trimmedKeyword)
            
            // 2. 搜索该分类下的所有故事
            if let stories = category.stories as? Set<StoryEntity> {
                for story in stories {
                    // ⚠️ 异常处理：检查故事对象是否有效
                    guard !story.isFault, let storyId = story.id else {
                        print("⚠️ [CategoryService] Skipping invalid story in category '\(category.name ?? "Unknown")'")
                        continue
                    }
                    
                    let titleLower = (story.title ?? "").lowercased()
                    let contentLower = (story.plainTextContent ?? "").lowercased()
                    
                    var matchScore = 0
                    var matchType: StoryMatch.MatchType? = nil
                    var snippet = ""
                    
                    // 标题匹配（更高分数）
                    if titleLower.contains(trimmedKeyword) {
                        matchScore = 100
                        matchType = .title
                        snippet = story.title ?? ""
                    }
                    // 内容匹配
                    else if contentLower.contains(trimmedKeyword) {
                        matchScore = 50
                        matchType = .content
                        // 提取匹配的文本片段
                        snippet = extractSnippet(from: story.plainTextContent ?? "", keyword: trimmedKeyword)
                    }
                    
                    // 如果有匹配，添加到结果
                    if let type = matchType {
                        let match = StoryMatch(
                            story: story,
                            matchType: type,
                            matchSnippet: snippet,
                            matchScore: matchScore
                        )
                        matchedStories.append(match)
                    }
                }
            }
            
            // 如果分类名称匹配或有故事匹配，添加到结果
            if categoryNameMatch || !matchedStories.isEmpty {
                // ⚠️ 异常处理：检查分类对象是否有效
                guard category.id != nil else {
                    print("⚠️ [CategoryService] Skipping category with nil id")
                    continue
                }
                
                // 按匹配分数排序故事
                matchedStories.sort { $0.matchScore > $1.matchScore }
                
                // 构建分类路径
                let categoryPath = buildCategoryPath(for: category)
                
                // 如果分类名称匹配但没有故事匹配，也要显示（但分数较低）
                let result = CategorySearchResult(
                    category: category,
                    categoryPath: categoryPath,
                    matchedStories: matchedStories
                )
                
                results.append(result)
            }
        }
        
        // 按总分排序
        results.sort { $0.totalScore > $1.totalScore }
        
        return results
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
            createdAt: entity.createdAt ?? Date(),
            iconType: entity.iconType,
            customIconData: entity.customIconData
        )
        
        // 递归构建子节点
        let childEntities = (entity.children?.allObjects as? [CategoryEntity]) ?? []
        let sortedChildren = childEntities.sorted { $0.sortOrder < $1.sortOrder }
        let childNodes = sortedChildren.map { buildNode(from: $0) }
        
        // 计算直属故事数
        let directCount = entity.stories?.count ?? 0
        
        // 计算总故事数（包含子分类）
        let storyCount = entity.id.map { totalStoryCount(for: $0) } ?? 0
        
        return CategoryTreeNode(
            id: categoryModel.id,
            category: categoryModel,
            children: childNodes,
            isExpanded: false,
            storyCount: storyCount,
            directStoryCount: directCount
        )
    }
    
    /// 构建分类路径（例如：“生活 > 旅行 > 日本之旅”）
    private func buildCategoryPath(for category: CategoryEntity) -> String {
        var pathComponents: [String] = []
        var currentCategory: CategoryEntity? = category
        var visitedCategories: Set<NSManagedObjectID> = []  // 防止循环引用
        
        while let cat = currentCategory {
            // ⚠️ 异常处理：防止循环引用
            guard !visitedCategories.contains(cat.objectID) else {
                print("⚠️ [CategoryService] Circular reference detected in category hierarchy")
                break
            }
            visitedCategories.insert(cat.objectID)
            
            // ⚠️ 异常处理：检查分类名称是否有效
            let categoryName = cat.name ?? "Unknown"
            pathComponents.insert(categoryName, at: 0)
            
            // 移动到父分类
            currentCategory = cat.parent
            
            // ⚠️ 异常处理：防止无限循环（最多3级）
            if pathComponents.count >= 3 {
                break
            }
        }
        
        return pathComponents.joined(separator: " > ")
    }
    
    /// 删除媒体实体对应的文件
    private func deleteMediaFiles(for media: MediaEntity, using mediaService: MediaStorageService) {
        // 删除主文件
        if let fileName = media.fileName {
            if let url = mediaService.url(for: fileName, type: media.type == "video" ? .video : .image) {
                try? FileManager.default.removeItem(at: url)
            }
        }
        
        // 删除缩略图文件
        if let thumbFileName = media.thumbnailFileName {
            let type: MediaStorageService.MediaType = media.type == "video" ? .video : .image
            if let url = mediaService.url(for: thumbFileName, type: type) {
                try? FileManager.default.removeItem(at: url)
            }
        }
    }
    
    /// 提取包含关键字的文本片段
    private func extractSnippet(from text: String, keyword: String) -> String {
        // ⚠️ 异常处理：检查输入是否为空
        guard !text.isEmpty, !keyword.isEmpty else {
            return String(text.prefix(50))
        }
        
        let lowerText = text.lowercased()
        let lowerKeyword = keyword.lowercased()
        
        guard let range = lowerText.range(of: lowerKeyword) else {
            return String(text.prefix(50))
        }
        
        // 计算片段范围（关键字前后各取20个字符）
        let startDistance = text.distance(from: text.startIndex, to: range.lowerBound)
        let snippetStart = max(0, startDistance - 20)
        let snippetEnd = min(text.count, startDistance + keyword.count + 20)
        
        // ⚠️ 异常处理：防止索引越界
        guard snippetStart < text.count, snippetEnd <= text.count, snippetStart < snippetEnd else {
            return String(text.prefix(50))
        }
        
        let start = text.index(text.startIndex, offsetBy: snippetStart)
        let end = text.index(text.startIndex, offsetBy: snippetEnd)
        
        var snippet = String(text[start..<end])
        
        // 添加省略号
        if snippetStart > 0 {
            snippet = "..." + snippet
        }
        if snippetEnd < text.count {
            snippet = snippet + "..."
        }
        
        return snippet
    }
}
