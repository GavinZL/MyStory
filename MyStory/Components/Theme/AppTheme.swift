import SwiftUI

// MARK: - Theme Type
enum ThemeType: String, CaseIterable, Identifiable {
    case classic = "classic"
    case ocean = "ocean"
    case sunset = "sunset"
    
    var id: String { rawValue }
    
    var displayName: String {
        switch self {
        case .classic:
            return "settings.theme.classic".localized
        case .ocean:
            return "settings.theme.ocean".localized
        case .sunset:
            return "settings.theme.sunset".localized
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
            }
        }
        
        static var textPrimary: Color {
            Color(hex: "1C1C1E") ?? Color(red: 0.11, green: 0.11, blue: 0.12)
        }
        
        static var textSecondary: Color {
            Color(hex: "8E8E93") ?? .gray
        }
        
        static var border: Color {
            Color(hex: "D1D1D6") ?? Color(red: 0.82, green: 0.82, blue: 0.84)
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
