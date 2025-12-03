import SwiftUI

// MARK: - Category Form View
struct CategoryFormView: View {
    // MARK: - Environment
    @Environment(\.dismiss) private var dismiss
    
    // MARK: - Properties
    @ObservedObject var viewModel: CategoryViewModel
    
    /// 父级分类节点（可选）
    let parentNode: CategoryTreeNode?
    
    /// 预设层级（可选）
    let presetLevel: Int?
    
    // MARK: - State
    @State private var categoryName: String = ""
    @State private var selectedLevel: Int = 1
    @State private var selectedParent: CategoryTreeNode?
    @State private var selectedIcon: String = "folder.fill"
    @State private var selectedColor: String = "#007AFF"
    @State private var showError: Bool = false
    @State private var errorMessage: String = ""
    
    // MARK: - Icon Options
    private let iconOptions = [
        "folder.fill", "folder", "star.fill", "heart.fill",
        "house.fill", "briefcase.fill", "book.fill", "leaf.fill",
        "tag.fill", "pencil", "camera.fill", "person.fill"
    ]
    
    private let colorOptions = [
        "#007AFF", "#34C759", "#FF9F0A", "#FF375F",
        "#5856D6", "#AF52DE", "#00C7BE", "#FF2D55"
    ]
    
    // MARK: - Initialization
    
    init(
        viewModel: CategoryViewModel,
        parentNode: CategoryTreeNode? = nil,
        presetLevel: Int? = nil
    ) {
        self.viewModel = viewModel
        self.parentNode = parentNode
        self.presetLevel = presetLevel
    }
    
    // MARK: - Body
    
    var body: some View {
        NavigationView {
            Form {
                // 如果有预设层级，不显示层级选择器
                if presetLevel == nil {
                    levelSection
                } else {
                    // 显示当前层级信息
                    currentLevelInfoSection
                }
                
                // 如果有父节点，显示父分类信息
                if let parent = parentNode {
                    parentInfoSection(parent: parent)
                } else if presetLevel == nil {
                    parentSection
                }
                
                nameSection
                iconSection
                colorSection
            }
            .navigationTitle(navigationTitle)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                toolbarContent
            }
            .alert("common.error".localized, isPresented: $showError) {
                Button("common.confirm".localized, role: .cancel) {}
            } message: {
                Text(errorMessage)
            }
            .onAppear {
                setupInitialValues()
            }
        }
    }
    
    // MARK: - View Components
    
    /// 当前层级信息区（不可编辑）
    private var currentLevelInfoSection: some View {
        Section(header: Text("category.level".localized)) {
            HStack {
                Text("category.level".localized)
                Spacer()
                Text(levelDisplayName(for: effectiveLevel))
                    .foregroundColor(.secondary)
            }
        }
    }
    
    /// 父分类信息区（不可编辑）
    private func parentInfoSection(parent: CategoryTreeNode) -> some View {
        Section(header: Text("category.parent".localized)) {
            HStack {
                Image(systemName: parent.category.iconName)
                    .foregroundColor(Color(hex: parent.category.colorHex))
                Text(breadcrumbPath(for: parent))
                    .foregroundColor(.secondary)
            }
        }
    }
    
    private var levelSection: some View {
        Section(header: Text("category.level".localized)) {
            Picker("category.level".localized, selection: $selectedLevel) {
                Text("category.level1".localized).tag(1)
                Text("category.level2".localized).tag(2)
                Text("category.level3".localized).tag(3)
            }
            .pickerStyle(.segmented)
            .onChange(of: selectedLevel) { _ in
                // 切换层级时重置父分类
                selectedParent = nil
            }
        }
    }
    
    private var parentSection: some View {
        Group {
            if selectedLevel > 1 {
                Section(header: Text("category.selectParent".localized)) {
                    if availableParents.isEmpty {
                        Text("category.noParentAvailable".localized)
                            .foregroundColor(.secondary)
                    } else {
                        Picker("category.parent".localized, selection: $selectedParent) {
                            Text("category.pleaseSelect".localized).tag(nil as CategoryTreeNode?)
                            ForEach(availableParents, id: \.id) { node in
                                Text(parentDisplayName(node)).tag(node as CategoryTreeNode?)
                            }
                        }
                        .pickerStyle(.menu)
                    }
                }
            }
        }
    }
    
    private var nameSection: some View {
        Section(header: Text("category.name".localized)) {
            TextField("category.namePlaceholder".localized, text: $categoryName)
        }
    }
    
    private var iconSection: some View {
        Section(header: Text("category.icon".localized)) {
            LazyVGrid(columns: [GridItem(.adaptive(minimum: 60))], spacing: AppTheme.Spacing.l) {
                ForEach(iconOptions, id: \.self) { icon in
                    iconButton(icon: icon)
                }
            }
            .padding(.vertical, AppTheme.Spacing.s)
        }
    }
    
    private var colorSection: some View {
        Section(header: Text("category.color".localized)) {
            LazyVGrid(columns: [GridItem(.adaptive(minimum: 60))], spacing: AppTheme.Spacing.l) {
                ForEach(colorOptions, id: \.self) { color in
                    colorButton(color: color)
                }
            }
            .padding(.vertical, AppTheme.Spacing.s)
        }
    }
    
    private func iconButton(icon: String) -> some View {
        Button {
            selectedIcon = icon
        } label: {
            ZStack {
                Circle()
                    .fill(selectedIcon == icon ? Color.blue.opacity(0.2) : Color.gray.opacity(0.1))
                    .frame(width: 50, height: 50)
                
                Image(systemName: icon)
                    .font(.system(size: 24))
                    .foregroundColor(selectedIcon == icon ? AppTheme.Colors.primary : .primary)
            }
        }
    }
    
    private func colorButton(color: String) -> some View {
        Button {
            selectedColor = color
        } label: {
            ZStack {
                Circle()
                    .fill(Color(hex: color) ?? .blue)
                    .frame(width: 50, height: 50)
                
                if selectedColor == color {
                    Image(systemName: "checkmark")
                        .font(.system(size: 20, weight: .bold))
                        .foregroundColor(.white)
                }
            }
        }
    }
    
    @ToolbarContentBuilder
    private var toolbarContent: some ToolbarContent {
        ToolbarItem(placement: .navigationBarLeading) {
            Button("common.cancel".localized) {
                dismiss()
            }
        }
        
        ToolbarItem(placement: .navigationBarTrailing) {
            Button("common.done".localized) {
                saveCategory()
            }
            .disabled(categoryName.isEmpty)
        }
    }
    
    // MARK: - Actions
    private func saveCategory() {
        // 验证输入
        let effectiveLevelValue = effectiveLevel
        
        if effectiveLevelValue > 1 {
            // 如果有预设父节点，使用它；否则检查是否选择了父分类
            if parentNode == nil && selectedParent == nil {
                errorMessage = "category.error.selectParent".localized
                showError = true
                return
            }
        }
        
        do {
            let parentId = parentNode?.id ?? selectedParent?.id
            try viewModel.createCategory(
                name: categoryName,
                level: effectiveLevelValue,
                parentId: parentId,
                iconName: selectedIcon,
                colorHex: selectedColor
            )
            dismiss()
        } catch {
            errorMessage = error.localizedDescription
            showError = true
        }
    }
    
    // MARK: - Helper Methods
    
    /// 设置初始值
    private func setupInitialValues() {
        if let presetLevel = presetLevel {
            selectedLevel = presetLevel
        }
        
        if let parentNode = parentNode {
            selectedParent = parentNode
        }
    }
    
    /// 获取实际使用的层级
    private var effectiveLevel: Int {
        return presetLevel ?? selectedLevel
    }
    
    /// 获取导航栏标题
    private var navigationTitle: String {
        if let level = presetLevel {
            let levelName = levelDisplayName(for: level)
            return String(format: "category.newLevel".localized, levelName)
        }
        return "category.new".localized
    }
    
    /// 获取层级显示名称
    private func levelDisplayName(for level: Int) -> String {
        switch level {
        case 1:
            return "category.level1".localized
        case 2:
            return "category.level2".localized
        case 3:
            return "category.level3".localized
        default:
            return "category.level.short".localized
        }
    }
    
    /// 生成面包屑路径
    private func breadcrumbPath(for node: CategoryTreeNode) -> String {
        var path = node.category.name
        
        // 如果是二级分类，查找一级父分类
        if node.category.level == 2 {
            if let parent = viewModel.tree.first(where: { $0.children.contains { $0.id == node.id } }) {
                path = "\(parent.category.name) > \(path)"
            }
        }
        
        return path
    }
    
    /// 获取可用的父分类列表
    private var availableParents: [CategoryTreeNode] {
        switch selectedLevel {
        case 2:
            // 二级分类的父分类必须是一级
            return viewModel.tree
        case 3:
            // 三级分类的父分类必须是二级
            return viewModel.tree.flatMap { $0.children }
        default:
            return []
        }
    }
    
    /// 生成父分类的显示名称（包含层级路径）
    private func parentDisplayName(_ node: CategoryTreeNode) -> String {
        if node.category.level == 1 {
            return node.category.name
        } else if node.category.level == 2 {
            // 查找一级父分类
            if let parent = viewModel.tree.first(where: { $0.children.contains { $0.id == node.id } }) {
                return "\(parent.category.name) > \(node.category.name)"
            }
        }
        return node.category.name
    }
}
