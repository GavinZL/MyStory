//
//  ToastView.swift
//  MyStory
//
//  Toast提示组件
//

import SwiftUI

/// Toast提示类型
enum ToastType {
    case success
    case error
    case info
    case warning
    
    var icon: String {
        switch self {
        case .success: return "checkmark.circle.fill"
        case .error: return "xmark.circle.fill"
        case .info: return "info.circle.fill"
        case .warning: return "exclamationmark.triangle.fill"
        }
    }
    
    var color: Color {
        switch self {
        case .success: return .green
        case .error: return .red
        case .info: return .blue
        case .warning: return .orange
        }
    }
}

/// Toast消息模型
struct ToastMessage: Equatable {
    let type: ToastType
    let message: String
    let duration: TimeInterval
    
    init(type: ToastType, message: String, duration: TimeInterval = 5.0) {
        self.type = type
        self.message = message
        self.duration = duration
    }
    
    static func == (lhs: ToastMessage, rhs: ToastMessage) -> Bool {
        lhs.message == rhs.message && lhs.type.icon == rhs.type.icon
    }
}

/// Toast视图修饰符
struct ToastModifier: ViewModifier {
    @Binding var toast: ToastMessage?
    @State private var workItem: DispatchWorkItem?
    
    func body(content: Content) -> some View {
        content
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .overlay(
                ZStack {
                    mainToastView()
                        .offset(y: -30)
                }
            )
            .animation(.spring(response: 0.3, dampingFraction: 0.7), value: toast)
            .onChange(of: toast) { newValue in
                showToast()
            }
    }
    
    @ViewBuilder func mainToastView() -> some View {
        if let toast = toast {
            VStack {
                Spacer()
                ToastView(
                    type: toast.type,
                    message: toast.message
                ) {
                    dismissToast()
                }
            }
            .transition(.move(edge: .bottom).combined(with: .opacity))
        }
    }
    
    private func showToast() {
        guard let toast = toast else { return }
        
        UIImpactFeedbackGenerator(style: .medium).impactOccurred()
        
        if toast.duration > 0 {
            workItem?.cancel()
            
            let task = DispatchWorkItem {
                dismissToast()
            }
            
            workItem = task
            DispatchQueue.main.asyncAfter(deadline: .now() + toast.duration, execute: task)
        }
    }
    
    private func dismissToast() {
        withAnimation {
            toast = nil
        }
        workItem?.cancel()
        workItem = nil
    }
}

/// Toast视图
struct ToastView: View {
    let type: ToastType
    let message: String
    let onDismiss: () -> Void
    
    var body: some View {
        HStack(alignment: .center, spacing: 12) {
            Image(systemName: type.icon)
                .foregroundColor(type.color)
                .font(.system(size: 24))
            
            Text(message)
                .font(.subheadline)
                .foregroundColor(.primary)
                .multilineTextAlignment(.leading)
            
            Spacer(minLength: 10)
            
            Button {
                onDismiss()
            } label: {
                Image(systemName: "xmark")
                    .foregroundColor(.secondary)
                    .font(.system(size: 14, weight: .bold))
            }
        }
        .padding()
        .frame(minWidth: 0, maxWidth: .infinity)
        .background(
            Color(.systemBackground)
                .cornerRadius(12)
                .shadow(color: Color.black.opacity(0.1), radius: 10, x: 0, y: 5)
        )
        .padding(.horizontal, 16)
    }
}

/// View扩展，用于显示Toast
extension View {
    func toast(_ toast: Binding<ToastMessage?>) -> some View {
        self.modifier(ToastModifier(toast: toast))
    }
}
