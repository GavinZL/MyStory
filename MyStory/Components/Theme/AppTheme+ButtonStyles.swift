//
//  AppTheme+ButtonStyles.swift
//  MyStory
//
//  统一的按钮样式定义
//

import SwiftUI

// MARK: - Button Styles Extension
extension AppTheme {
    struct ButtonStyles {
        // MARK: - Primary Button Style
        /// 主要按钮样式 - 用于保存、确认等主操作
        struct PrimaryButtonStyle: SwiftUI.ButtonStyle {
            @Environment(\.isEnabled) private var isEnabled
            
            func makeBody(configuration: Configuration) -> some View {
                configuration.label
                    .font(AppTheme.Typography.headline)
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, AppTheme.Spacing.m)
                    .padding(.horizontal, AppTheme.Spacing.l)
                    .background(
                        RoundedRectangle(cornerRadius: AppTheme.Radius.m)
                            .fill(isEnabled ? AppTheme.Colors.primary : AppTheme.Colors.border)
                    )
                    .opacity(configuration.isPressed ? 0.8 : 1.0)
                    .scaleEffect(configuration.isPressed ? 0.98 : 1.0)
                    .animation(.easeInOut(duration: AppTheme.Animation.Duration.fast), value: configuration.isPressed)
            }
        }
        
        // MARK: - Secondary Button Style
        /// 次要按钮样式 - 用于取消、次要操作
        struct SecondaryButtonStyle: SwiftUI.ButtonStyle {
            @Environment(\.isEnabled) private var isEnabled
            
            func makeBody(configuration: Configuration) -> some View {
                configuration.label
                    .font(AppTheme.Typography.headline)
                    .foregroundColor(isEnabled ? AppTheme.Colors.primary : AppTheme.Colors.textSecondary)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, AppTheme.Spacing.m)
                    .padding(.horizontal, AppTheme.Spacing.l)
                    .background(
                        RoundedRectangle(cornerRadius: AppTheme.Radius.m)
                            .stroke(isEnabled ? AppTheme.Colors.primary : AppTheme.Colors.border, lineWidth: 1.5)
                    )
                    .opacity(configuration.isPressed ? 0.8 : 1.0)
                    .scaleEffect(configuration.isPressed ? 0.98 : 1.0)
                    .animation(.easeInOut(duration: AppTheme.Animation.Duration.fast), value: configuration.isPressed)
            }
        }
        
        // MARK: - Destructive Button Style
        /// 危险按钮样式 - 用于删除、危险操作
        struct DestructiveButtonStyle: SwiftUI.ButtonStyle {
            @Environment(\.isEnabled) private var isEnabled
            
            func makeBody(configuration: Configuration) -> some View {
                configuration.label
                    .font(AppTheme.Typography.headline)
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, AppTheme.Spacing.m)
                    .padding(.horizontal, AppTheme.Spacing.l)
                    .background(
                        RoundedRectangle(cornerRadius: AppTheme.Radius.m)
                            .fill(isEnabled ? AppTheme.Colors.error : AppTheme.Colors.border)
                    )
                    .opacity(configuration.isPressed ? 0.8 : 1.0)
                    .scaleEffect(configuration.isPressed ? 0.98 : 1.0)
                    .animation(.easeInOut(duration: AppTheme.Animation.Duration.fast), value: configuration.isPressed)
            }
        }
        
        // MARK: - Text Button Style
        /// 文本按钮样式 - 用于内联链接
        struct TextButtonStyle: SwiftUI.ButtonStyle {
            @Environment(\.isEnabled) private var isEnabled
            
            func makeBody(configuration: Configuration) -> some View {
                configuration.label
                    .font(AppTheme.Typography.body)
                    .foregroundColor(isEnabled ? AppTheme.Colors.primary : AppTheme.Colors.textSecondary)
                    .opacity(configuration.isPressed ? 0.6 : 1.0)
                    .animation(.easeInOut(duration: AppTheme.Animation.Duration.fast), value: configuration.isPressed)
            }
        }
        
        // MARK: - Icon Button Style
        /// 图标按钮样式 - 用于工具栏图标按钮
        struct IconButtonStyle: SwiftUI.ButtonStyle {
            @Environment(\.isEnabled) private var isEnabled
            
            func makeBody(configuration: Configuration) -> some View {
                configuration.label
                    .foregroundColor(isEnabled ? AppTheme.Colors.primary : AppTheme.Colors.textSecondary)
                    .frame(width: 44, height: 44)
                    .background(
                        Circle()
                            .fill(configuration.isPressed ? AppTheme.Colors.surface : Color.clear)
                    )
                    .opacity(configuration.isPressed ? 0.8 : 1.0)
                    .animation(.easeInOut(duration: AppTheme.Animation.Duration.fast), value: configuration.isPressed)
            }
        }
        
        // MARK: - Static Accessors
        static var primary: PrimaryButtonStyle { PrimaryButtonStyle() }
        static var secondary: SecondaryButtonStyle { SecondaryButtonStyle() }
        static var destructive: DestructiveButtonStyle { DestructiveButtonStyle() }
        static var text: TextButtonStyle { TextButtonStyle() }
        static var icon: IconButtonStyle { IconButtonStyle() }
    }
}

// MARK: - Preview
#Preview {
    VStack(spacing: AppTheme.Spacing.l) {
        Button("Primary Button") {}
            .buttonStyle(AppTheme.ButtonStyles.primary)
        
        Button("Secondary Button") {}
            .buttonStyle(AppTheme.ButtonStyles.secondary)
        
        Button("Destructive Button") {}
            .buttonStyle(AppTheme.ButtonStyles.destructive)
        
        Button("Text Button") {}
            .buttonStyle(AppTheme.ButtonStyles.text)
        
        Button {} label: {
            Image(systemName: "plus")
                .font(.system(size: AppTheme.IconSize.l))
        }
        .buttonStyle(AppTheme.ButtonStyles.icon)
        
        // Disabled state
        Button("Disabled Primary") {}
            .buttonStyle(AppTheme.ButtonStyles.primary)
            .disabled(true)
    }
    .padding()
}
