import SwiftUI

/// 移动目标类型
enum MoveTargetType {
    /// 移动分类：只能选择符合层级的父分类
    case category(movingNode: CategoryTreeNode)
    /// 移动故事：可以选择任意分类
    case story
}

/// 分类移动选择器（树形展示）
/// 用于选择目标分类，支持移动分类或移动故事
struct CategoryMovePicker: View {
    // MARK: - Properties
    
    /// 移动目标类型
    let moveType: MoveTargetType
    
    /// 移动完成回调（返回选中的目标分类 ID）
    let onMove: (UUID) -> Void
    
    /// 取消回调
    let onDismiss: () -> Void
    
    // MARK: - Convenience Init for Category Move
    
    /// 兼容旧接口：移动分类
    init(movingNode: CategoryTreeNode, onMove: @escaping (UUID) -> Void, onDismiss: @escaping () -> Void) {
        self.moveType = .category(movingNode: movingNode)
        self.onMove = onMove
        self.onDismiss = onDismiss
    }
    
    /// 移动故事
    init(moveStory: Bool = true, onMove: @escaping (UUID) -> Void, onDismiss: @escaping () -> Void) {
        self.moveType = .story
        self.onMove = onMove
        self.onDismiss = onDismiss
    }
    
    // MARK: - Environment
    
    @Environment(\.managedObjectContext) private var context
    
    // MARK: - State
    
    @State private var categoryTree: [CategoryTreeNode] = []
    @State private var selectedTargetId: UUID?
    
    // MARK: - Body
    
    var body: some View {
        NavigationView {
            List {
                if categoryTree.isEmpty {
                    emptyStateView
                } else {
                    treeView
                }
            }
            .navigationTitle("category.moveTo".localized)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                toolbarContent
            }
            .onAppear {
                loadCategories()
            }
        }
    }
    
    // MARK: - View Components
    
    /// 空状态
    private var emptyStateView: some View {
        VStack(spacing: AppTheme.Spacing.l) {
            Image(systemName: "folder.badge.questionmark")
                .font(.system(size: 50))
                .foregroundColor(.secondary)
            
            Text("category.moveNoTarget".localized)
                .font(.headline)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
    
    /// 树形视图
    private var treeView: some View {
        ForEach(filteredTree) { level1Node in
            MovePickerSection(
                node: level1Node,
                selectedTargetId: $selectedTargetId,
                isSelectable: isNodeSelectable(level1Node),
                excludeIds: excludeIds
            )
        }
    }
    
    /// 工具栏
    @ToolbarContentBuilder
    private var toolbarContent: some ToolbarContent {
        ToolbarItem(placement: .navigationBarLeading) {
            Button("common.cancel".localized) {
                onDismiss()
            }
        }
        
        ToolbarItem(placement: .navigationBarTrailing) {
            Button("common.done".localized) {
                if let targetId = selectedTargetId {
                    onMove(targetId)
                }
            }
            .disabled(selectedTargetId == nil)
        }
    }
    
    // MARK: - Helper Methods
    
    /// 加载分类树
    private func loadCategories() {
        let service = CoreDataCategoryService(context: context)
        categoryTree = service.fetchTree()
    }
    
    /// 需要排除的节点 ID 集合
    private var excludeIds: Set<UUID> {
        switch moveType {
        case .category(let movingNode):
            return collectDescendantIds(movingNode)
        case .story:
            return []
        }
    }
    
    /// 过滤后的树（排除正在移动的节点及其后代所在的顶级分类不需要排除，只在子级排除）
    private var filteredTree: [CategoryTreeNode] {
        categoryTree
    }
    
    /// 判断节点是否可选
    private func isNodeSelectable(_ node: CategoryTreeNode) -> Bool {
        if excludeIds.contains(node.id) { return false }
        
        switch moveType {
        case .category(let movingNode):
            let targetLevel = movingNode.category.level - 1
            if node.category.level != targetLevel { return false }
            // 排除当前父分类
            if node.id == movingNode.category.parentId { return false }
            return true
        case .story:
            return true
        }
    }
    
    /// 递归收集节点及其所有后代的 ID
    private func collectDescendantIds(_ node: CategoryTreeNode) -> Set<UUID> {
        var ids: Set<UUID> = [node.id]
        for child in node.children {
            ids.formUnion(collectDescendantIds(child))
        }
        return ids
    }
}

// MARK: - Move Picker Section (Level 1)

private struct MovePickerSection: View {
    let node: CategoryTreeNode
    @Binding var selectedTargetId: UUID?
    let isSelectable: Bool
    let excludeIds: Set<UUID>
    
    @State private var isExpanded: Bool = true
    
    var body: some View {
        Section(header: sectionHeader) {
            if isExpanded {
                ForEach(node.children) { level2Node in
                    if !excludeIds.contains(level2Node.id) {
                        MovePickerItem(
                            node: level2Node,
                            level: 2,
                            selectedTargetId: $selectedTargetId,
                            excludeIds: excludeIds
                        )
                    }
                }
            }
        }
    }
    
    private var sectionHeader: some View {
        HStack {
            Button {
                if isSelectable {
                    selectedTargetId = node.id
                }
            } label: {
                HStack {
                    CategoryIconView(
                        model: node.category,
                        size: 20,
                        color: Color(hex: node.category.colorHex)
                    )
                    
                    Text(node.category.name)
                        .font(.headline)
                        .foregroundColor(isSelectable ? .primary : .secondary)
                    
                    if selectedTargetId == node.id {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundColor(AppTheme.Colors.primary)
                            .font(.subheadline)
                    }
                }
            }
            .buttonStyle(PlainButtonStyle())
            .disabled(!isSelectable)
            
            Spacer()
            
            if !node.children.isEmpty {
                Button {
                    withAnimation {
                        isExpanded.toggle()
                    }
                } label: {
                    Image(systemName: isExpanded ? "chevron.down" : "chevron.right")
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .frame(width: 30, height: 30)
                        .contentShape(Rectangle())
                }
                .buttonStyle(PlainButtonStyle())
            }
        }
    }
}

// MARK: - Move Picker Item (Level 2/3)

private struct MovePickerItem: View {
    let node: CategoryTreeNode
    let level: Int
    @Binding var selectedTargetId: UUID?
    let excludeIds: Set<UUID>
    
    @State private var isExpanded: Bool = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            itemRow
            
            if level == 2 && isExpanded && !node.children.isEmpty {
                ForEach(node.children) { level3Node in
                    if !excludeIds.contains(level3Node.id) {
                        MovePickerItem(
                            node: level3Node,
                            level: 3,
                            selectedTargetId: $selectedTargetId,
                            excludeIds: excludeIds
                        )
                        .padding(.leading, AppTheme.Spacing.xl)
                    }
                }
            }
        }
    }
    
    private var itemRow: some View {
        HStack(spacing: AppTheme.Spacing.m) {
            // 展开按钮（Level 2 有子分类时）
            if level == 2 && !node.children.isEmpty {
                Button {
                    withAnimation {
                        isExpanded.toggle()
                    }
                } label: {
                    Image(systemName: isExpanded ? "chevron.down" : "chevron.right")
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .frame(width: 16, height: 30)
                        .contentShape(Rectangle())
                }
                .buttonStyle(PlainButtonStyle())
            }
            
            // 选择按钮
            Button {
                selectedTargetId = node.id
            } label: {
                HStack(spacing: AppTheme.Spacing.m) {
                    CategoryIconView(
                        model: node.category,
                        size: 20,
                        color: Color(hex: node.category.colorHex)
                    )
                    .frame(width: 24)
                    
                    Text(node.category.name)
                        .font(.body)
                        .foregroundColor(.primary)
                    
                    Spacer()
                    
                    if selectedTargetId == node.id {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundColor(AppTheme.Colors.primary)
                    }
                }
                .contentShape(Rectangle())
            }
            .buttonStyle(PlainButtonStyle())
        }
        .padding(.vertical, AppTheme.Spacing.s)
    }
}
