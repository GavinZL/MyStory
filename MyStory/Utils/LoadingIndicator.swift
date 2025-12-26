import SwiftUI

/// 全局加载进度指示器管理器
class LoadingIndicatorManager: ObservableObject {
    static let shared = LoadingIndicatorManager()
    
    @Published var isLoading = false
    @Published var message: String = "加载中..."
    
    private init() {}
    
    /// 显示加载指示器
    func show(message: String = "加载中...") {
        DispatchQueue.main.async {
            self.message = message
            self.isLoading = true
        }
    }
    
    /// 隐藏加载指示器
    func hide() {
        DispatchQueue.main.async {
            self.isLoading = false
        }
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
                
                VStack(spacing: 16) {
                    ProgressView()
                        .scaleEffect(1.5)
                        .progressViewStyle(CircularProgressViewStyle(tint: .white))
                    
                    Text(manager.message)
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(.white)
                }
                .padding(32)
                .background(
                    RoundedRectangle(cornerRadius: 16)
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
