//
//  String+Localization.swift
//  MyStory
//
//  字符串本地化扩展
//

import Foundation

extension String {
    /// 获取本地化字符串
    var localized: String {
        return LocalizationManager.shared.localizedString(forKey: self)
    }
    
    /// 获取带参数的本地化字符串
    func localized(with arguments: CVarArg...) -> String {
        let format = LocalizationManager.shared.localizedString(forKey: self)
        return String(format: format, arguments: arguments)
    }
    
    /// 获取本地化字符串（带注释）
    func localized(comment: String) -> String {
        return LocalizationManager.shared.localizedString(forKey: self, comment: comment)
    }
}

// MARK: - Convenience Properties

extension String {
    // MARK: - Common
    static let cancel = "common.cancel".localized
    static let save = "common.save".localized
    static let done = "common.done".localized
    static let delete = "common.delete".localized
    static let edit = "common.edit".localized
    static let add = "common.add".localized
    static let confirm = "common.confirm".localized
    static let error = "common.error".localized
    static let loading = "common.loading".localized
    
    // MARK: - Tab Bar
    static let tabTimeline = "tab.timeline".localized
    static let tabCategory = "tab.category".localized
    static let tabSettings = "tab.settings".localized
}
