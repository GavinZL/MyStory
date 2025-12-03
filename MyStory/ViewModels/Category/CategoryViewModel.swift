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
}
