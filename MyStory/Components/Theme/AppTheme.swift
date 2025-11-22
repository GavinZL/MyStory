//
//  AppTheme.swift
//  MyStory
//
//  应用主题配置
//

import SwiftUI

// MARK: - 颜色定义

extension Color {
    // 主色调
    static let appPrimary = Color("AppPrimary", bundle: nil) ?? Color.blue
    static let appSecondary = Color("AppSecondary", bundle: nil) ?? Color.gray
    
    // 语义化颜色
    static let appBackground = Color("AppBackground", bundle: nil) ?? Color(uiColor: .systemBackground)
    static let appSecondaryBackground = Color("AppSecondaryBackground", bundle: nil) ?? Color(uiColor: .secondarySystemBackground)
    static let appText = Color("AppText", bundle: nil) ?? Color(uiColor: .label)
    static let appSecondaryText = Color("AppSecondaryText", bundle: nil) ?? Color(uiColor: .secondaryLabel)
    static let appBorder = Color("AppBorder", bundle: nil) ?? Color(uiColor: .separator)
    
    // 状态颜色
    static let appSuccess = Color.green
    static let appWarning = Color.orange
    static let appError = Color.red
    static let appInfo = Color.blue
}

// MARK: - 字体定义

extension Font {
    // 标题字体
    static let appLargeTitle = Font.system(size: 34, weight: .bold, design: .default)
    static let appTitle = Font.system(size: 28, weight: .bold, design: .default)
    static let appTitle2 = Font.system(size: 22, weight: .bold, design: .default)
    static let appTitle3 = Font.system(size: 20, weight: .semibold, design: .default)
    
    // 正文字体
    static let appBody = Font.system(size: 17, weight: .regular, design: .default)
    static let appBodyBold = Font.system(size: 17, weight: .semibold, design: .default)
    static let appCallout = Font.system(size: 16, weight: .regular, design: .default)
    static let appSubheadline = Font.system(size: 15, weight: .regular, design: .default)
    static let appFootnote = Font.system(size: 13, weight: .regular, design: .default)
    static let appCaption = Font.system(size: 12, weight: .regular, design: .default)
    static let appCaption2 = Font.system(size: 11, weight: .regular, design: .default)
}

// MARK: - 间距定义

struct AppSpacing {
    static let xxSmall: CGFloat = 4
    static let xSmall: CGFloat = 8
    static let small: CGFloat = 12
    static let medium: CGFloat = 16
    static let large: CGFloat = 20
    static let xLarge: CGFloat = 24
    static let xxLarge: CGFloat = 32
}

// MARK: - 圆角定义

struct AppCornerRadius {
    static let small: CGFloat = 8
    static let medium: CGFloat = 12
    static let large: CGFloat = 16
    static let xLarge: CGFloat = 20
}

// MARK: - 阴影定义

struct AppShadow {
    static func small() -> some View {
        Color.clear
            .shadow(color: Color.black.opacity(0.1), radius: 4, x: 0, y: 2)
    }
    
    static func medium() -> some View {
        Color.clear
            .shadow(color: Color.black.opacity(0.15), radius: 8, x: 0, y: 4)
    }
    
    static func large() -> some View {
        Color.clear
            .shadow(color: Color.black.opacity(0.2), radius: 16, x: 0, y: 8)
    }
}
