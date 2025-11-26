import SwiftUI

// MARK: - Category Form View
struct CategoryFormView: View {
    // MARK: - Environment
    @Environment(\.dismiss) private var dismiss
    
    // MARK: - Properties
    @ObservedObject var viewModel: CategoryViewModel
    
    // MARK: - State
    @State private var categoryName: String = ""
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
    
    // MARK: - Body
    var body: some View {
        NavigationView {
            Form {
                nameSection
                iconSection
                colorSection
            }
            .navigationTitle("新建分类")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                toolbarContent
            }
            .alert("错误", isPresented: $showError) {
                Button("确定", role: .cancel) {}
            } message: {
                Text(errorMessage)
            }
        }
    }
    
    // MARK: - View Components
    private var nameSection: some View {
        Section(header: Text("分类名称")) {
            TextField("请输入分类名称", text: $categoryName)
        }
    }
    
    private var iconSection: some View {
        Section(header: Text("选择图标")) {
            LazyVGrid(columns: [GridItem(.adaptive(minimum: 60))], spacing: 16) {
                ForEach(iconOptions, id: \.self) { icon in
                    iconButton(icon: icon)
                }
            }
            .padding(.vertical, 8)
        }
    }
    
    private var colorSection: some View {
        Section(header: Text("选择颜色")) {
            LazyVGrid(columns: [GridItem(.adaptive(minimum: 60))], spacing: 16) {
                ForEach(colorOptions, id: \.self) { color in
                    colorButton(color: color)
                }
            }
            .padding(.vertical, 8)
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
                    .foregroundColor(selectedIcon == icon ? .blue : .primary)
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
            Button("取消") {
                dismiss()
            }
        }
        
        ToolbarItem(placement: .navigationBarTrailing) {
            Button("完成") {
                saveCategory()
            }
            .disabled(categoryName.isEmpty)
        }
    }
    
    // MARK: - Actions
    private func saveCategory() {
        do {
            try viewModel.createCategory(
                name: categoryName,
                level: 1,
                parentId: nil,
                iconName: selectedIcon,
                colorHex: selectedColor
            )
            dismiss()
        } catch {
            errorMessage = error.localizedDescription
            showError = true
        }
    }
}

// MARK: - Color Extension
extension Color {
    init?(hex: String) {
        var hexSanitized = hex.trimmingCharacters(in: .whitespacesAndNewlines)
        hexSanitized = hexSanitized.replacingOccurrences(of: "#", with: "")
        
        var rgb: UInt64 = 0
        
        guard Scanner(string: hexSanitized).scanHexInt64(&rgb) else {
            return nil
        }
        
        self.init(
            red: Double((rgb & 0xFF0000) >> 16) / 255.0,
            green: Double((rgb & 0x00FF00) >> 8) / 255.0,
            blue: Double(rgb & 0x0000FF) / 255.0
        )
    }
}
