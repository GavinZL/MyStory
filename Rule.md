

要求：
1. 阅读整个项目工程，在熟悉整个工程的情况下，继续问题的解答
2. 工程中组件公用化 [在需要实现新的组件是，先看看工程中是否存在对应组件]
3. 工程中涉及到多语言相关字符串时需统一管理， 区分中英文
4. 工程文件处理需要遵守基本的设计原则，如SOLID，可以参考 @StoryEditorView.swift 的组织方式
    如：
        MVVM 架构：视图与业务逻辑分离
        组合模式：大视图拆分为小组件
        单一职责：每个方法只做一件事
        依赖注入：通过初始化器注入依赖

### 主题（Theme）设置规范与 `AppTheme.swift` 结构

目标：
- 将字体、颜色、间距、圆角、阴影等所有主题变量集中在 `AppTheme.swift` 管理，保证一致性与可维护性。
- 支持浅色/深色模式与动态字体，无障碍优先。
- 所有组件禁止使用魔法数字，统一引用主题 Token。
- 支持用户自定义主题，预设三套主题方案供用户选择。

命名与结构约定：
- 文件：`AppTheme.swift`
- 结构：
  - `ThemeType` 主题类型枚举（classic/ocean/sunset）
  - `ThemeManager` 主题管理器（单例，支持 UserDefaults 持久化）
  - `AppTheme.Colors` 颜色 Token（优先使用 Assets.xcassets 的动态颜色）
  - `AppTheme.Typography` 字体与字号 Token
  - `AppTheme.Spacing` 间距 Token
  - `AppTheme.Radius` 圆角 Token
  - `AppTheme.Shadow` 阴影 Token

用户可自定义的主题项：
- **主色调（Primary Color）**：应用的主要强调色，用于按钮、链接、选中状态
- **背景色（Background Color）**：页面主背景色
- **表面色（Surface Color）**：卡片、列表项背景色

三套预设主题：
1. **经典主题（Classic）**：蓝色系 (#007AFF)，经典 iOS 风格
2. **海洋主题（Ocean）**：青蓝色系 (#00B4D8)，清新自然
3. **晚霞主题（Sunset）**：暖橙色系 (#FF6B6B)，温暖柔和

不可自定义的项目（保持一致性）：
- 文本主色/次色（textPrimary/textSecondary）
- 边框颜色（border）
- 语义颜色（success/warning/error）
- 字体大小与间距
- 圆角与阴影

颜色管理：
- 在 `Assets.xcassets` 中维护动态颜色（Light/Dark），命名统一以 `App` 前缀：
  - `AppPrimary`、`AppBackground`、`AppSurface`、`AppTextPrimary`、`AppTextSecondary`、`AppBorder`、`AppSuccess`、`AppWarning`、`AppError`
- SwiftUI 使用方式：
  - 直接调用 `Color("AppPrimary")`，或通过 `AppTheme.Colors.primary`
- 主题颜色通过 `Color(hex:)` 扫展方法支持 Hex 颜色值

字体与字号：
- 遵循动态字体，提供统一 Token：
  - `largeTitle`、`title1`、`title2`、`title3`、`headline`、`body`、`callout`、`subheadline`、`footnote`、`caption`
- 如需自定义字体家族，统一在 `AppTheme.Typography` 内封装。

间距与圆角：
- 间距 Token（单位：pt）：
  - `xs=4`、`s=8`、`m=12`、`l=16`、`xl=24`、`xxl=32`
- 圆角 Token（单位：pt）：
  - `s=8`、`m=12`、`l=16`

阴影：
- 阴影 Token：`small`、`medium`、`large`，统一配置颜色、半径、偏移。

`AppTheme.swift` 最小示例：
```swift
import SwiftUI

struct AppTheme {
    struct Colors {
        static let primary = Color("AppPrimary")
        static let background = Color("AppBackground")
        static let surface = Color("AppSurface")
        static let textPrimary = Color("AppTextPrimary")
        static let textSecondary = Color("AppTextSecondary")
        static let border = Color("AppBorder")
        static let success = Color("AppSuccess")
        static let warning = Color("AppWarning")
        static let error = Color("AppError")
    }

    struct Typography {
        static let largeTitle = Font.largeTitle
        static let title1 = Font.title
        static let title2 = Font.title2
        static let title3 = Font.title3
        static let headline = Font.headline
        static let body = Font.body
        static let callout = Font.callout
        static let subheadline = Font.subheadline
        static let footnote = Font.footnote
        static let caption = Font.caption
    }

    struct Spacing {
        static let xs: CGFloat = 4
        static let s: CGFloat = 8
        static let m: CGFloat = 12
        static let l: CGFloat = 16
        static let xl: CGFloat = 24
        static let xxl: CGFloat = 32
    }

    struct Radius {
        static let s: CGFloat = 8
        static let m: CGFloat = 12
        static let l: CGFloat = 16
    }

    struct ShadowToken {
        let color: Color
        let radius: CGFloat
        let x: CGFloat
        let y: CGFloat
    }

    struct Shadow {
        static let small = ShadowToken(color: Color.black.opacity(0.08), radius: 4, x: 0, y: 2)
        static let medium = ShadowToken(color: Color.black.opacity(0.12), radius: 8, x: 0, y: 4)
        static let large = ShadowToken(color: Color.black.opacity(0.16), radius: 12, x: 0, y: 8)
    }
}
```

使用示例（统一引用主题 Token）：
```swift
VStack(alignment: .leading, spacing: AppTheme.Spacing.m) {
    Text("标题")
        .font(AppTheme.Typography.title2)
        .foregroundColor(AppTheme.Colors.textPrimary)

    Text("正文内容")
        .font(AppTheme.Typography.body)
        .foregroundColor(AppTheme.Colors.textSecondary)
}
.padding(AppTheme.Spacing.l)
.background(AppTheme.Colors.surface)
.cornerRadius(AppTheme.Radius.m)
.shadow(color: AppTheme.Shadow.small.color,
        radius: AppTheme.Shadow.small.radius,
        x: AppTheme.Shadow.small.x,
        y: AppTheme.Shadow.small.y)
```

暗黑模式与无障碍：
- 所有颜色必须通过 `Assets.xcassets` 提供 Light/Dark 变体或 `ColorScheme` 动态适配。
- 字体字号遵循系统动态字体；如需固定字号，需评估无障碍影响并在评审中说明。

团队协作规范：
- 新增主题变量必须先在 `AppTheme.swift` 添加 Token，再在组件中使用；禁止在视图内直接写死数值。
- 代码评审需检查：是否统一引用 `AppTheme`、是否支持暗黑模式、是否符合无障碍要求。

迁移建议：
- 盘点现有视图的颜色/间距/圆角/阴影的硬编码，逐步替换为 `AppTheme` 引用。
- 先从公共组件与高频页面开始替换，减少回归风险。
