//
//  LocalizationManager.swift
//  MyStory
//
//  语言管理器 - 管理应用的多语言切换
//

import Foundation
import SwiftUI

/// 支持的语言类型
enum AppLanguage: String, CaseIterable {
    case chinese = "zh-Hans"
    case english = "en"
    
    var displayName: String {
        switch self {
        case .chinese:
            return "简体中文"
        case .english:
            return "English"
        }
    }
    
    var code: String {
        return self.rawValue
    }
}

/// 语言管理器 - 单例模式
class LocalizationManager: ObservableObject {
    static let shared = LocalizationManager()
    
    // MARK: - Properties
    
    /// 当前选择的语言
    @Published var currentLanguage: AppLanguage {
        didSet {
            UserDefaults.standard.set(currentLanguage.rawValue, forKey: "AppLanguage")
            // 发送语言变更通知
            NotificationCenter.default.post(name: .languageDidChange, object: nil)
        }
    }
    
    /// 当前语言的 Bundle
    private var languageBundle: Bundle?
    
    // MARK: - Initialization
    
    private init() {
        // 从 UserDefaults 读取保存的语言设置
        if let savedLanguage = UserDefaults.standard.string(forKey: "AppLanguage"),
           let language = AppLanguage(rawValue: savedLanguage) {
            self.currentLanguage = language
        } else {
            // 默认使用系统语言
            let systemLanguage = Locale.preferredLanguages.first ?? "en"
            if systemLanguage.hasPrefix("zh") {
                self.currentLanguage = .chinese
            } else {
                self.currentLanguage = .english
            }
        }
        
        updateLanguageBundle()
    }
    
    // MARK: - Public Methods
    
    /// 切换语言
    func setLanguage(_ language: AppLanguage) {
        currentLanguage = language
        updateLanguageBundle()
    }
    
    /// 获取本地化字符串
    func localizedString(forKey key: String, comment: String = "") -> String {
        if let bundle = languageBundle {
            return NSLocalizedString(key, bundle: bundle, comment: comment)
        }
        return NSLocalizedString(key, comment: comment)
    }
    
    /// 获取带参数的本地化字符串
    func localizedString(forKey key: String, arguments: CVarArg...) -> String {
        let format = localizedString(forKey: key)
        return String(format: format, arguments: arguments)
    }
    
    // MARK: - Private Methods
    
    private func updateLanguageBundle() {
        if let path = Bundle.main.path(forResource: currentLanguage.rawValue, ofType: "lproj"),
           let bundle = Bundle(path: path) {
            self.languageBundle = bundle
        } else {
            self.languageBundle = Bundle.main
        }
    }
}

// MARK: - Notification Name Extension

extension Notification.Name {
    static let languageDidChange = Notification.Name("languageDidChange")
}
