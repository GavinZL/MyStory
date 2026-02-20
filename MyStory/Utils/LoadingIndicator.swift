import SwiftUI

/// 全局加载进度指示器管理器
class LoadingIndicatorManager: ObservableObject {
    static let shared = LoadingIndicatorManager()
    
    @Published var isLoading = false
    @Published var message: String = "加载中..."
    @Published var progress: Double? = nil  // nil 表示不确定进度
    @Published var showCancelButton = false
    
    private var cancelHandler: (() -> Void)?
    
    private init() {}
    
    /// 显示加载指示器（不确定进度）
    func show(message: String = "加载中...") {
        DispatchQueue.main.async {
            self.message = message
            self.progress = nil
            self.showCancelButton = false
            self.cancelHandler = nil
            self.isLoading = true
        }
    }
    
    /// 显示带进度的加载指示器
    func showWithProgress(message: String, progress: Double, cancelHandler: (() -> Void)? = nil) {
        DispatchQueue.main.async {
            self.message = message
            self.progress = max(0, min(1, progress))
            self.showCancelButton = cancelHandler != nil
            self.cancelHandler = cancelHandler
            self.isLoading = true
        }
    }
    
    /// 更新进度
    func updateProgress(_ progress: Double, message: String? = nil) {
        DispatchQueue.main.async {
            self.progress = max(0, min(1, progress))
            if let msg = message {
                self.message = msg
            }
        }
    }
    
    /// 隐藏加载指示器
    func hide() {
        DispatchQueue.main.async {
            self.isLoading = false
            self.progress = nil
            self.cancelHandler = nil
        }
    }
    
    /// 取消操作
    func cancel() {
        cancelHandler?()
        hide()
    }
}

/// 全局加载进度指示器视图
struct LoadingIndicatorView: View {
    @ObservedObject var manager = LoadingIndicatorManager.shared
    
    var body: some View {
        ZStack {
            if manager.isLoading {
                Color.black.opacity(0.4)
                    .ignoresSafeArea()
                    .transition(.opacity)
                
                VStack(spacing: AppTheme.Spacing.l) {
                    if let progress = manager.progress {
                        // 带进度的指示器
                        ZStack {
                            Circle()
                                .stroke(Color.white.opacity(0.3), lineWidth: 4)
                                .frame(width: 50, height: 50)
                            
                            Circle()
                                .trim(from: 0, to: progress)
                                .stroke(Color.white, style: StrokeStyle(lineWidth: 4, lineCap: .round))
                                .frame(width: 50, height: 50)
                                .rotationEffect(.degrees(-90))
                                .animation(.linear(duration: 0.2), value: progress)
                            
                            Text("\(Int(progress * 100))%")
                                .font(AppTheme.Typography.caption)
                                .foregroundColor(.white)
                                .fontWeight(.medium)
                        }
                    } else {
                        // 不确定进度的指示器
                        ProgressView()
                            .scaleEffect(1.5)
                            .progressViewStyle(CircularProgressViewStyle(tint: .white))
                    }
                    
                    Text(manager.message)
                        .font(AppTheme.Typography.body)
                        .foregroundColor(.white)
                        .multilineTextAlignment(.center)
                    
                    if manager.showCancelButton {
                        Button {
                            manager.cancel()
                        } label: {
                            Text("common.cancel".localized)
                                .font(AppTheme.Typography.footnote)
                                .foregroundColor(.white.opacity(0.8))
                                .padding(.horizontal, AppTheme.Spacing.l)
                                .padding(.vertical, AppTheme.Spacing.s)
                                .background(Color.white.opacity(0.2))
                                .cornerRadius(AppTheme.Radius.s)
                        }
                    }
                }
                .padding(AppTheme.Spacing.xl)
                .background(
                    RoundedRectangle(cornerRadius: AppTheme.Radius.l)
                        .fill(Color.black.opacity(0.8))
                )
                .transition(.scale.combined(with: .opacity))
            }
        }
        .animation(.easeInOut(duration: 0.2), value: manager.isLoading)
    }
}

/// View扩展，方便添加全局加载指示器
extension View {
    func withLoadingIndicator() -> some View {
        ZStack {
            self
            LoadingIndicatorView()
        }
    }
}
