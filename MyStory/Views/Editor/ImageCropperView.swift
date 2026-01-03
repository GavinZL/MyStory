import SwiftUI
import PhotosUI

// MARK: - Image Cropper View
struct ImageCropperView: View {
    
    // MARK: - Environment
    @Environment(\.dismiss) private var dismiss
    
    // MARK: - Properties
    @StateObject private var viewModel: ImageCropperViewModel
    
    /// 完成回调
    let onComplete: (Data) -> Void
    
    // MARK: - State
    @State private var showError = false
    @State private var errorMessage = ""
    @GestureState private var dragOffset: CGSize = .zero
    @GestureState private var cornerDragOffset: CGSize = .zero
    @State private var isDraggingCorner = false
    @State private var initialCropRect: CGRect? = nil
    
    // MARK: - Initialization
    init(image: UIImage, onComplete: @escaping (Data) -> Void) {
        _viewModel = StateObject(wrappedValue: ImageCropperViewModel(image: image))
        self.onComplete = onComplete
    }
    
    // MARK: - Body
    var body: some View {
       NavigationView {
            VStack(spacing: 0) {
                // 图片裁剪区域
                imageEditorSection
                    .background(Color.black)
                
                Divider()
                
                // 形状选择器
                shapePickerSection
                    .padding(.vertical, AppTheme.Spacing.m)
                    .background(Color(uiColor: .systemBackground))
                
                Divider()
                
                // 确定按钮
                confirmButtonSection
                    .padding(AppTheme.Spacing.m)
                    .background(Color(uiColor: .systemBackground))
            }
            .navigationTitle("自定义图标")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("common.cancel".localized) {
                        dismiss()
                    }
                }
            }
            .alert("common.error".localized, isPresented: $showError) {
                Button("common.confirm".localized, role: .cancel) {}
            } message: {
                Text(errorMessage)
            }
       }
    }
    
    // MARK: - View Components
    
    /// 图片编辑区域
    private var imageEditorSection: some View {
        GeometryReader { geometry in
            ZStack {
                // 背景图片
                Image(uiImage: viewModel.originalImage)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .onAppear {
                        viewModel.updateDisplayInfo(containerSize: geometry.size)
                    }
                
                // 遮罩层（裁剪框外的半透明区域）
                cropMaskOverlay
                
                // 裁剪框
                cropFrameView
                    .gesture(dragGesture)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
    }
    
    /// 裁剪遮罩层
    private var cropMaskOverlay: some View {
        GeometryReader { geometry in
            let cropRect = viewModel.getDisplayCropRect()
            
            ZStack {
                // 全屏半透明遮罩
                Color.black.opacity(0.5)
                
                // 裁剪框区域（透明）
                Rectangle()
                    .frame(width: cropRect.width, height: cropRect.height)
                    .position(
                        x: cropRect.midX,
                        y: cropRect.midY
                    )
                    .blendMode(.destinationOut)
            }
            .compositingGroup()
            .allowsHitTesting(false)
        }
    }
    
    /// 裁剪框视图
    private var cropFrameView: some View {
        GeometryReader { geometry in
            let cropRect = viewModel.getDisplayCropRect()
            let effectiveOffset = isDraggingCorner ? .zero : dragOffset
            
            ZStack {
                // 透明交互层（用于捕获框内拖拽手势）
                if viewModel.selectedShape == .rectangle {
                    Rectangle()
                        .fill(Color.white.opacity(0.001))
                        .contentShape(Rectangle())
                } else {
                    Circle()
                        .fill(Color.white.opacity(0.001))
                        .contentShape(Circle())
                }
                
                // 裁剪框边框
                if viewModel.selectedShape == .rectangle {
                    Rectangle()
                        .stroke(Color.white, lineWidth: 2)
                } else {
                    Circle()
                        .stroke(Color.white, lineWidth: 2)
                }
                
                // 四个角的拖拽指示器
                cornerIndicators
            }
            .frame(width: cropRect.width, height: cropRect.height)
            .position(
                x: cropRect.midX + effectiveOffset.width,
                y: cropRect.midY + effectiveOffset.height
            )
        }
    }
    
    /// 角落指示器
    private var cornerIndicators: some View {
        GeometryReader { geo in
            let size: CGFloat = 20
            
            Group {
                // 左上角
                cornerIndicator(size: size)
                    .position(x: 0, y: 0)
                    .highPriorityGesture(cornerDragGesture)
                
                // 右下角
                cornerIndicator(size: size)
                    .position(x: geo.size.width, y: geo.size.height)
                    .highPriorityGesture(cornerDragGesture)
            }
        }
    }
    
    /// 单个角落指示器
    private func cornerIndicator(size: CGFloat) -> some View {
        Circle()
            .fill(Color.white)
            .frame(width: size, height: size)
    }
    
    /// 形状选择器
    private var shapePickerSection: some View {
        HStack(spacing: AppTheme.Spacing.xl) {
            ForEach(CropShape.allCases, id: \.self) { shape in
                shapeButton(shape: shape)
            }
        }
    }
    
    /// 形状按钮
    private func shapeButton(shape: CropShape) -> some View {
        Button {
            withAnimation(.easeInOut(duration: 0.2)) {
                viewModel.changeShape(shape)
            }
        } label: {
            VStack(spacing: AppTheme.Spacing.s) {
                Image(systemName: shape.iconName)
                    .font(.system(size: 30))
                    .foregroundColor(viewModel.selectedShape == shape ? AppTheme.Colors.primary : .secondary)
                    .frame(width: 60, height: 60)
                    .background(
                        RoundedRectangle(cornerRadius: AppTheme.Radius.m)
                            .fill(viewModel.selectedShape == shape ? AppTheme.Colors.primary.opacity(0.1) : Color.clear)
                    )
                
                Text(shape.displayName)
                    .font(.caption)
                    .foregroundColor(viewModel.selectedShape == shape ? AppTheme.Colors.primary : .secondary)
            }
        }
    }
    
    /// 确定按钮区域
    private var confirmButtonSection: some View {
        Button {
            confirmCrop()
        } label: {
            Text("common.confirm".localized)
                .font(.headline)
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, AppTheme.Spacing.m)
                .background(AppTheme.Colors.primary)
                .cornerRadius(AppTheme.Radius.m)
        }
    }
    
    // MARK: - Gestures
    
    /// 拖拽手势（移动裁剪框）
    private var dragGesture: some Gesture {
        DragGesture()
            .updating($dragOffset) { value, state, _ in
                if !isDraggingCorner {
                    state = value.translation
                }
            }
            .onEnded { value in
                if !isDraggingCorner {
                    viewModel.updateCropPosition(translation: value.translation)
                }
            }
    }
    
    /// 角点拖拽手势（缩放裁剪框）
    private var cornerDragGesture: some Gesture {
        DragGesture()
            .onChanged { value in
                isDraggingCorner = true
                
                // 记录初始状态
                if initialCropRect == nil {
                    initialCropRect = viewModel.cropRect
                }
                
                // 计算缩放比例
                let displayScale = viewModel.displayImageSize.width / viewModel.originalImage.size.width
                let dragDistance = (value.translation.width + value.translation.height) / 2
                let scale = 1.0 + (dragDistance / (initialCropRect!.width * displayScale))
                
                // 应用缩放
                viewModel.scaleCropRect(from: initialCropRect!, scale: scale)
            }
            .onEnded { _ in
                isDraggingCorner = false
                initialCropRect = nil
            }
    }
    
    // MARK: - Actions
    
    /// 确认裁剪
    private func confirmCrop() {
        guard let iconData = viewModel.cropAndProcess() else {
            errorMessage = "图片处理失败，请重试"
            showError = true
            return
        }
        
        onComplete(iconData)
        dismiss()
    }
}

// MARK: - Preview
#Preview {
    ImageCropperView(image: UIImage(systemName: "photo")!) { _ in
        print("Completed")
    }
}
