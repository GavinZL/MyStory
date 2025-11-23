import Foundation
import Combine

public enum CategoryDisplayMode: String, CaseIterable, Identifiable {
    case card
    case list
    public var id: String { rawValue }
    public var title: String { self == .card ? "卡片" : "列表" }
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
}
