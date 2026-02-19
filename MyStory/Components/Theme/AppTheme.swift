import SwiftUI

// MARK: - Font Scale Type
enum FontScale: String, CaseIterable, Identifiable {
    case small = "small"
    case standard = "standard"
    case large = "large"
    case extraLarge = "extraLarge"
    
    var id: String { rawValue }
    
    var displayName: String {
        switch self {
        case .small:
            return "settings.font.small".localized
        case .standard:
            return "settings.font.standard".localized
        case .large:
            return "settings.font.large".localized
        case .extraLarge:
            return "settings.font.extraLarge".localized
        }
    }
    
    var scale: CGFloat {
        switch self {
        case .small:
            return 0.85
        case .standard:
            return 1.0
        case .large:
            return 1.15
        case .extraLarge:
            return 1.3
        }
    }
    
    var sliderValue: Double {
        switch self {
        case .small:
            return 0.0
        case .standard:
            return 1.0
        case .large:
            return 2.0
        case .extraLarge:
            return 3.0
        }
    }
    
    static func from(sliderValue: Double) -> FontScale {
        let rounded = round(sliderValue)
        switch rounded {
        case 0:
            return .small
        case 1:
            return .standard
        case 2:
            return .large
        case 3:
            return .extraLarge
        default:
            return .standard
        }
    }
}

// MARK: - Font Scale Manager
class FontScaleManager: ObservableObject {
    static let shared = FontScaleManager()
    
    @Published var currentScale: FontScale {
        didSet {
            UserDefaults.standard.set(currentScale.rawValue, forKey: "selectedFontScale")
        }
    }
    
    private init() {
        let savedScale = UserDefaults.standard.string(forKey: "selectedFontScale") ?? FontScale.standard.rawValue
        self.currentScale = FontScale(rawValue: savedScale) ?? .standard
    }
    
    func setScale(_ scale: FontScale) {
        currentScale = scale
    }
    
    var scaleFactor: CGFloat {
        currentScale.scale
    }
}

// MARK: - Theme Type
enum ThemeType: String, CaseIterable, Identifiable {
    case classic = "classic"
    case ocean = "ocean"
    case sunset = "sunset"
    case nightSky = "nightSky"
    case forest = "forest"
    case lavender = "lavender"
    case dark = "dark"
    
    var id: String { rawValue }
    
    /// 是否为深色主题
    var isDarkTheme: Bool {
        switch self {
        case .nightSky, .dark:
            return true
        default:
            return false
        }
    }
    
    var displayName: String {
        switch self {
        case .classic:
            return "settings.theme.classic".localized
        case .ocean:
            return "settings.theme.ocean".localized
        case .sunset:
            return "settings.theme.sunset".localized
        case .nightSky:
            return "settings.theme.nightSky".localized
        case .forest:
            return "settings.theme.forest".localized
        case .lavender:
            return "settings.theme.lavender".localized
        case .dark:
            return "settings.theme.dark".localized
        }
    }
    
    var description: String {
        switch self {
        case .classic:
            return "settings.theme.classic.description".localized
        case .ocean:
            return "settings.theme.ocean.description".localized
        case .sunset:
            return "settings.theme.sunset.description".localized
        case .nightSky:
            return "settings.theme.nightSky.description".localized
        case .forest:
            return "settings.theme.forest.description".localized
        case .lavender:
            return "settings.theme.lavender.description".localized
        case .dark:
            return "settings.theme.dark.description".localized
        }
    }
    
    var previewColors: (primary: Color, surface: Color) {
        switch self {
        case .classic:
            return (primary: Color(hex: "007AFF") ?? .blue, surface: Color(hex: "F2F2F7") ?? .gray)
        case .ocean:
            return (primary: Color(hex: "00B4D8") ?? .cyan, surface: Color(hex: "E8F4F8") ?? .gray)
        case .sunset:
            return (primary: Color(hex: "FF6B6B") ?? .orange, surface: Color(hex: "FFF0E8") ?? .gray)
        case .nightSky:
            return (primary: Color(hex: "5B4E8C") ?? .purple, surface: Color(hex: "25253D") ?? .gray)
        case .forest:
            return (primary: Color(hex: "2D6A4F") ?? .green, surface: Color(hex: "E8F5E9") ?? .gray)
        case .lavender:
            return (primary: Color(hex: "9B8AC4") ?? .purple, surface: Color(hex: "F3E8FF") ?? .gray)
        case .dark:
            return (primary: Color(hex: "6B8AF7") ?? .blue, surface: Color(hex: "1E1E1E") ?? .gray)
        }
    }
}

// MARK: - Theme Manager
class ThemeManager: ObservableObject {
    static let shared = ThemeManager()
    
    @Published var currentTheme: ThemeType {
        didSet {
            UserDefaults.standard.set(currentTheme.rawValue, forKey: "selectedTheme")
        }
    }
    
    private init() {
        let savedTheme = UserDefaults.standard.string(forKey: "selectedTheme") ?? ThemeType.classic.rawValue
        self.currentTheme = ThemeType(rawValue: savedTheme) ?? .classic
    }
    
    func setTheme(_ theme: ThemeType) {
        currentTheme = theme
    }
}

struct AppTheme {
    @MainActor
    struct Colors {
        @MainActor
        static var primary: Color {
            switch ThemeManager.shared.currentTheme {
            case .classic:
                return Color(hex: "007AFF") ?? .blue
            case .ocean:
                return Color(hex: "00B4D8") ?? .cyan
            case .sunset:
                return Color(hex: "FF6B6B") ?? .orange
            case .nightSky:
                return Color(hex: "5B4E8C") ?? .purple
            case .forest:
                return Color(hex: "2D6A4F") ?? .green
            case .lavender:
                return Color(hex: "9B8AC4") ?? .purple
            case .dark:
                return Color(hex: "6B8AF7") ?? .blue
            }
        }
        
        /// 金色强调色（用于 Night Sky 主题）
        @MainActor
        static var accent: Color {
            switch ThemeManager.shared.currentTheme {
            case .nightSky:
                return Color(hex: "F5B041") ?? .yellow
            default:
                return primary
            }
        }
        
        @MainActor
        static var background: Color {
            switch ThemeManager.shared.currentTheme {
            case .classic:
                return Color(hex: "FFFFFF") ?? .white
            case .ocean:
                return Color(hex: "F0F9FF") ?? Color(red: 0.94, green: 0.98, blue: 1.0)
            case .sunset:
                return Color(hex: "FFF5F5") ?? Color(red: 1.0, green: 0.96, blue: 0.96)
            case .nightSky:
                return Color(hex: "1A1A2E") ?? Color(red: 0.10, green: 0.10, blue: 0.18)
            case .forest:
                return Color(hex: "F5FDF5") ?? Color(red: 0.96, green: 0.99, blue: 0.96)
            case .lavender:
                return Color(hex: "FAF5FF") ?? Color(red: 0.98, green: 0.96, blue: 1.0)
            case .dark:
                return Color(hex: "121212") ?? Color(red: 0.07, green: 0.07, blue: 0.07)
            }
        }
        
        @MainActor
        static var surface: Color {
            switch ThemeManager.shared.currentTheme {
            case .classic:
                return Color(hex: "F2F2F7") ?? Color(red: 0.95, green: 0.95, blue: 0.97)
            case .ocean:
                return Color(hex: "E8F4F8") ?? Color(red: 0.91, green: 0.96, blue: 0.97)
            case .sunset:
                return Color(hex: "FFF0E8") ?? Color(red: 1.0, green: 0.94, blue: 0.91)
            case .nightSky:
                return Color(hex: "25253D") ?? Color(red: 0.15, green: 0.15, blue: 0.24)
            case .forest:
                return Color(hex: "E8F5E9") ?? Color(red: 0.91, green: 0.96, blue: 0.91)
            case .lavender:
                return Color(hex: "F3E8FF") ?? Color(red: 0.95, green: 0.91, blue: 1.0)
            case .dark:
                return Color(hex: "1E1E1E") ?? Color(red: 0.12, green: 0.12, blue: 0.12)
            }
        }
        
        @MainActor
        static var textPrimary: Color {
            switch ThemeManager.shared.currentTheme {
            case .nightSky:
                return Color(hex: "E8E8F0") ?? Color(red: 0.91, green: 0.91, blue: 0.94)
            case .forest:
                return Color(hex: "1B4332") ?? Color(red: 0.11, green: 0.26, blue: 0.20)
            case .lavender:
                return Color(hex: "4A3B6B") ?? Color(red: 0.29, green: 0.23, blue: 0.42)
            case .dark:
                return Color(hex: "E0E0E0") ?? Color(red: 0.88, green: 0.88, blue: 0.88)
            default:
                return Color(hex: "1C1C1E") ?? Color(red: 0.11, green: 0.11, blue: 0.12)
            }
        }
        
        @MainActor
        static var textSecondary: Color {
            switch ThemeManager.shared.currentTheme {
            case .nightSky:
                return Color(hex: "9090A8") ?? Color(red: 0.56, green: 0.56, blue: 0.66)
            case .forest:
                return Color(hex: "52796F") ?? Color(red: 0.32, green: 0.47, blue: 0.44)
            case .lavender:
                return Color(hex: "8B7AA8") ?? Color(red: 0.55, green: 0.48, blue: 0.66)
            case .dark:
                return Color(hex: "9E9E9E") ?? Color(red: 0.62, green: 0.62, blue: 0.62)
            default:
                return Color(hex: "8E8E93") ?? .gray
            }
        }
        
        @MainActor
        static var border: Color {
            switch ThemeManager.shared.currentTheme {
            case .nightSky:
                return Color(hex: "3D3D5C") ?? Color(red: 0.24, green: 0.24, blue: 0.36)
            case .dark:
                return Color(hex: "3D3D3D") ?? Color(red: 0.24, green: 0.24, blue: 0.24)
            default:
                return Color(hex: "D1D1D6") ?? Color(red: 0.82, green: 0.82, blue: 0.84)
            }
        }
        
        static var success: Color {
            Color(hex: "34C759") ?? .green
        }
        
        static var warning: Color {
            Color(hex: "FF9500") ?? .orange
        }
        
        static var error: Color {
            Color(hex: "FF3B30") ?? .red
        }
    }

    struct Typography {
        @MainActor
        static var largeTitle: Font {
            let baseSize: CGFloat = 34 // iOS 系统 largeTitle 默认大小
            return Font.system(size: baseSize * FontScaleManager.shared.scaleFactor)
        }
        
        @MainActor
        static var title1: Font {
            let baseSize: CGFloat = 28 // iOS 系统 title 默认大小
            return Font.system(size: baseSize * FontScaleManager.shared.scaleFactor)
        }
        
        @MainActor
        static var title2: Font {
            let baseSize: CGFloat = 22 // iOS 系统 title2 默认大小
            return Font.system(size: baseSize * FontScaleManager.shared.scaleFactor)
        }
        
        @MainActor
        static var title3: Font {
            let baseSize: CGFloat = 20 // iOS 系统 title3 默认大小
            return Font.system(size: baseSize * FontScaleManager.shared.scaleFactor)
        }
        
        @MainActor
        static var headline: Font {
            let baseSize: CGFloat = 17 // iOS 系统 headline 默认大小
            return Font.system(size: baseSize * FontScaleManager.shared.scaleFactor, weight: .semibold)
        }
        
        @MainActor
        static var body: Font {
            let baseSize: CGFloat = 17 // iOS 系统 body 默认大小
            return Font.system(size: baseSize * FontScaleManager.shared.scaleFactor)
        }
        
        @MainActor
        static var callout: Font {
            let baseSize: CGFloat = 16 // iOS 系统 callout 默认大小
            return Font.system(size: baseSize * FontScaleManager.shared.scaleFactor)
        }
        
        @MainActor
        static var subheadline: Font {
            let baseSize: CGFloat = 15 // iOS 系统 subheadline 默认大小
            return Font.system(size: baseSize * FontScaleManager.shared.scaleFactor)
        }
        
        @MainActor
        static var footnote: Font {
            let baseSize: CGFloat = 13 // iOS 系统 footnote 默认大小
            return Font.system(size: baseSize * FontScaleManager.shared.scaleFactor)
        }
        
        @MainActor
        static var caption: Font {
            let baseSize: CGFloat = 12 // iOS 系统 caption 默认大小
            return Font.system(size: baseSize * FontScaleManager.shared.scaleFactor)
        }
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
    
    // MARK: - Icon Size Token
    struct IconSize {
        static let xs: CGFloat = 12    // 装饰性小图标（List 行尾箭头）
        static let s: CGFloat = 16     // 内联图标（文本旁图标、Tag 标记）
        static let m: CGFloat = 20     // 工具栏按钮
        static let l: CGFloat = 24     // 导航栏、主操作
        static let xl: CGFloat = 28    // 强调图标
        static let xxl: CGFloat = 42   // 分类图标
        static let hero: CGFloat = 60  // 空状态大图标
    }
    
    // MARK: - Opacity Token
    struct Opacity {
        static let subtle: Double = 0.05    // 极轻背景叠加
        static let muted: Double = 0.15     // 禁用状态、占位符
        static let medium: Double = 0.3     // 次要内容、辅助背景
        static let strong: Double = 0.6     // 视频播放按钮、蒙层
    }
    
    // MARK: - Gradient Token
    @MainActor
    struct Gradient {
        /// 主色渐变（深→浅）
        static var primary: LinearGradient {
            let theme = ThemeManager.shared.currentTheme
            let colors: [Color]
            switch theme {
            case .classic:
                colors = [Color(hex: "007AFF") ?? .blue, Color(hex: "5AC8FA") ?? .cyan]
            case .ocean:
                colors = [Color(hex: "00B4D8") ?? .cyan, Color(hex: "90E0EF") ?? .teal]
            case .sunset:
                colors = [Color(hex: "FF6B6B") ?? .orange, Color(hex: "FFA07A") ?? .orange]
            case .nightSky:
                colors = [Color(hex: "5B4E8C") ?? .purple, Color(hex: "F5B041") ?? .yellow]
            case .forest:
                colors = [Color(hex: "2D6A4F") ?? .green, Color(hex: "95D5B2") ?? .green]
            case .lavender:
                colors = [Color(hex: "9B8AC4") ?? .purple, Color(hex: "D8B4FE") ?? .purple]
            case .dark:
                colors = [Color(hex: "6B8AF7") ?? .blue, Color(hex: "A5B4FC") ?? .blue]
            }
            return LinearGradient(colors: colors, startPoint: .topLeading, endPoint: .bottomTrailing)
        }
        
        /// 蒙层渐变（底部渐隐）
        static var overlay: LinearGradient {
            LinearGradient(
                colors: [Color.black.opacity(0), Color.black.opacity(Opacity.strong)],
                startPoint: .top,
                endPoint: .bottom
            )
        }
    }
    
    // MARK: - Animation Token
    struct Animation {
        struct Duration {
            static let fast: Double = 0.2      // 微交互（按钮点击、toggle）
            static let normal: Double = 0.3    // 标准过渡（sheet 展开、fade）
            static let slow: Double = 0.5      // 强调动画（删除确认、加载完成）
        }
        
        struct Spring {
            static var snappy: SwiftUI.Animation {
                SwiftUI.Animation.spring(response: 0.3, dampingFraction: 0.7)
            }
            static var smooth: SwiftUI.Animation {
                SwiftUI.Animation.spring(response: 0.5, dampingFraction: 0.8)
            }
            static var gentle: SwiftUI.Animation {
                SwiftUI.Animation.spring(response: 0.8, dampingFraction: 0.9)
            }
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
