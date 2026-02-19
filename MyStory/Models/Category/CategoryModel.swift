import Foundation

public struct CategoryModel: Identifiable, Hashable {
    public let id: UUID
    public var name: String
    public var iconName: String
    public var colorHex: String
    public var level: Int // 1..3
    public var parentId: UUID?
    public var sortOrder: Int
    public var createdAt: Date
    public var iconType: String? // "system" or "custom"
    public var customIconData: Data?
}

public struct CategoryTreeNode: Identifiable, Hashable {
    public let id: UUID
    public var category: CategoryModel
    public var children: [CategoryTreeNode]
    public var isExpanded: Bool
    public var storyCount: Int // 含子分类总数
    public var directStoryCount: Int // 仅该分类直属的故事数（不含子分类）
}
