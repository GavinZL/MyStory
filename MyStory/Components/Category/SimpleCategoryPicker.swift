import SwiftUI

/// 简单的分类选择器
/// 用于故事编辑器中选择分类
struct SimpleCategoryPicker: View {
    // MARK: - Properties
    
    @Binding var selectedCategories: Set<UUID>
    let onDismiss: () -> Void
    
    // MARK: - Environment
    
    @Environment(\.managedObjectContext) private var context
    
    // MARK: - State
    
    @State private var categoryTree: [CategoryTreeNode] = []
    
    // MARK: - Initialization
    
    init(selectedCategories: Binding<Set<UUID>>, onDismiss: @escaping () -> Void) {
        self._selectedCategories = selectedCategories
        self.onDismiss = onDismiss
    }
    
    // MARK: - Body
    
    var body: some View {
        NavigationView {
            List {
                if categoryTree.isEmpty {
                    emptyStateView
                } else {
                    categoryTreeView
                }
            }
            .navigationTitle("categoryPicker.title".localized)
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
    
    /// 空状态视图
    private var emptyStateView: some View {
        VStack(spacing: AppTheme.Spacing.l) {
            Image(systemName: "folder.badge.plus")
                .font(.system(size: 50))
                .foregroundColor(.secondary)
            
            Text("categoryPicker.empty".localized)
                .font(.headline)
                .foregroundColor(.secondary)
            
            Text("categoryPicker.createHint".localized)
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
    
    /// 分类树视图
    private var categoryTreeView: some View {
        ForEach(categoryTree) { level1Node in
            CategoryPickerSection(
                node: level1Node,
                selectedCategories: $selectedCategories
            )
        }
    }
    
    /// 工具栏内容
    @ToolbarContentBuilder
    private var toolbarContent: some ToolbarContent {
        ToolbarItem(placement: .navigationBarLeading) {
            Button("common.cancel".localized) {
                onDismiss()
            }
        }
        
        ToolbarItem(placement: .navigationBarTrailing) {
            Button("common.done".localized) {
                onDismiss()
            }
        }
    }
    
    // MARK: - Helper Methods
    
    /// 加载分类树
    private func loadCategories() {
        let service = CoreDataCategoryService(context: context)
        categoryTree = service.fetchTree()
    }
}

// MARK: - Category Picker Section

/// 分类选择器的一个区域（对应一级分类）
private struct CategoryPickerSection: View {
    let node: CategoryTreeNode
    @Binding var selectedCategories: Set<UUID>
    
    @State private var isExpanded: Bool = true
    
    var body: some View {
        Section(header: sectionHeader) {
            if isExpanded {
                // 显示二级分类
                ForEach(node.children) { level2Node in
                    CategoryPickerItem(
                        node: level2Node,
                        level: 2,
                        selectedCategories: $selectedCategories
                    )
                }
            }
        }
    }
    
    /// 区域头部
    private var sectionHeader: some View {
        Button {
            withAnimation {
                isExpanded.toggle()
            }
        } label: {
            HStack {
                Image(systemName: node.category.iconName)
                    .foregroundColor(Color(hex: node.category.colorHex))
                
                Text(node.category.name)
                    .font(.headline)
                    .foregroundColor(.primary)
                
                Spacer()
                
                Image(systemName: isExpanded ? "chevron.down" : "chevron.right")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// MARK: - Category Picker Item

/// 分类选择器的单个项目（二级或三级分类）
private struct CategoryPickerItem: View {
    let node: CategoryTreeNode
    let level: Int  // 2 or 3
    @Binding var selectedCategories: Set<UUID>
    
    @State private var isExpanded: Bool = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // 当前分类项
            categoryItemButton
            
            // 如果是二级分类且展开，显示三级分类
            if level == 2 && isExpanded && !node.children.isEmpty {
                ForEach(node.children) { level3Node in
                    CategoryPickerItem(
                        node: level3Node,
                        level: 3,
                        selectedCategories: $selectedCategories
                    )
                    .padding(.leading, AppTheme.Spacing.xl)
                }
            }
        }
    }
    
    /// 分类项按钮
    private var categoryItemButton: some View {
        Button {
            if level == 2 && !node.children.isEmpty {
                // 二级分类：切换展开状态
                withAnimation {
                    isExpanded.toggle()
                }
            } else {
                // 三级分类或无子分类的二级分类：切换选中状态
                toggleSelection()
            }
        } label: {
            HStack(spacing: AppTheme.Spacing.m) {
                // 展开/折叠图标（仅二级分类有子分类时显示）
                if level == 2 && !node.children.isEmpty {
                    Image(systemName: isExpanded ? "chevron.down" : "chevron.right")
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .frame(width: 16)
                }
                
                // 分类图标
                Image(systemName: node.category.iconName)
                    .foregroundColor(Color(hex: node.category.colorHex))
                    .frame(width: 24)
                
                // 分类名称
                Text(node.category.name)
                    .font(.body)
                    .foregroundColor(.primary)
                
                Spacer()
                
                // 选中状态指示器
                if isSelected {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(AppTheme.Colors.primary)
                }
            }
            .padding(.vertical, AppTheme.Spacing.s)
            .contentShape(Rectangle())
        }
        .buttonStyle(PlainButtonStyle())
    }
    
    /// 是否选中
    private var isSelected: Bool {
        selectedCategories.contains(node.id)
    }
    
    /// 切换选中状态
    private func toggleSelection() {
        if isSelected {
            selectedCategories.remove(node.id)
        } else {
            selectedCategories.insert(node.id)
        }
    }
}

// MARK: - Preview

#Preview {
    SimpleCategoryPicker(
        selectedCategories: .constant([]),
        onDismiss: {}
    )
    .environment(\.managedObjectContext, PersistenceController.preview.container.viewContext)
}
