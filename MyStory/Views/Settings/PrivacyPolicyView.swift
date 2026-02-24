//
//  PrivacyPolicyView.swift
//  MyStory
//
//  隐私政策页面
//

import SwiftUI

struct PrivacyPolicyView: View {
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: AppTheme.Spacing.l) {
                    // 最后更新时间
                    Text("privacyPolicy.lastUpdated".localized)
                        .font(AppTheme.Typography.caption)
                        .foregroundColor(AppTheme.Colors.textSecondary)
                        .frame(maxWidth: .infinity, alignment: .trailing)
                        .padding(.horizontal)
                    
                    // 引言
                    PolicySectionView(
                        title: "privacyPolicy.section.intro.title".localized,
                        content: "privacyPolicy.section.intro.content".localized,
                        icon: "hand.wave"
                    )
                    
                    // 数据收集
                    PolicySectionView(
                        title: "privacyPolicy.section.dataCollection.title".localized,
                        content: "privacyPolicy.section.dataCollection.content".localized,
                        icon: "doc.text"
                    )
                    
                    // 数据存储
                    PolicySectionView(
                        title: "privacyPolicy.section.dataStorage.title".localized,
                        content: "privacyPolicy.section.dataStorage.content".localized,
                        icon: "externaldrive"
                    )
                    
                    // 权限使用
                    PolicySectionView(
                        title: "privacyPolicy.section.permissions.title".localized,
                        content: "privacyPolicy.section.permissions.content".localized,
                        icon: "lock.shield"
                    )
                    
                    // AI 服务说明
                    PolicySectionView(
                        title: "privacyPolicy.section.aiService.title".localized,
                        content: "privacyPolicy.section.aiService.content".localized,
                        icon: "sparkles"
                    )
                    
                    // 您的权利
                    PolicySectionView(
                        title: "privacyPolicy.section.userRights.title".localized,
                        content: "privacyPolicy.section.userRights.content".localized,
                        icon: "person.badge.shield.checkmark"
                    )
                    
                    // 数据安全
                    PolicySectionView(
                        title: "privacyPolicy.section.security.title".localized,
                        content: "privacyPolicy.section.security.content".localized,
                        icon: "lock.fill"
                    )
                    
                    // 联系我们
                    PolicySectionView(
                        title: "privacyPolicy.section.contact.title".localized,
                        content: "privacyPolicy.section.contact.content".localized,
                        icon: "envelope"
                    )
                    
                    // 政策变更
                    PolicySectionView(
                        title: "privacyPolicy.section.changes.title".localized,
                        content: "privacyPolicy.section.changes.content".localized,
                        icon: "arrow.triangle.2.circlepath"
                    )
                    
                    // 查看完整政策
                    VStack(spacing: AppTheme.Spacing.s) {
                        Text("privacyPolicy.fullDocument.hint".localized)
                            .font(AppTheme.Typography.caption)
                            .foregroundColor(AppTheme.Colors.textSecondary)
                            .multilineTextAlignment(.center)
                        
                        Button(action: {
                            openFullPrivacyPolicy()
                        }) {
                            HStack {
                                Image(systemName: "doc.text")
                                Text("privacyPolicy.fullDocument.button".localized)
                            }
                            .font(AppTheme.Typography.body)
                            .foregroundColor(AppTheme.Colors.primary)
                            .padding(.horizontal, AppTheme.Spacing.l)
                            .padding(.vertical, AppTheme.Spacing.m)
                            .background(
                                RoundedRectangle(cornerRadius: AppTheme.Radius.m)
                                    .stroke(AppTheme.Colors.primary, lineWidth: 1)
                            )
                        }
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.top, AppTheme.Spacing.l)
                    .padding(.horizontal)
                }
                .padding(.vertical)
            }
            .background(AppTheme.Colors.background)
            .navigationTitle("privacyPolicy.title".localized)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("common.done".localized) {
                        dismiss()
                    }
                }
            }
        }
    }
    
    // MARK: - Private Methods
    
    private func openFullPrivacyPolicy() {
        // 根据应用设置中的语言选择对应的隐私政策链接
        let currentLanguage = LocalizationManager.shared.currentLanguage
        let privacyURLString: String
        
        if currentLanguage == .chinese {
            // 中文链接
            privacyURLString = "https://github.com/GavinZL/MyStory/blob/main/privacy/PRIVACY_POLICY_zh-Hans.md"
        } else {
            // 英文链接
            privacyURLString = "https://github.com/GavinZL/MyStory/blob/main/privacy/PRIVACY_POLICY_en.md"
        }
        
        if let url = URL(string: privacyURLString) {
            UIApplication.shared.open(url)
        }
    }
}

// MARK: - Policy Section View

private struct PolicySectionView: View {
    let title: String
    let content: String
    let icon: String
    
    var body: some View {
        VStack(alignment: .leading, spacing: AppTheme.Spacing.s) {
            // 标题
            HStack(spacing: AppTheme.Spacing.s) {
                Image(systemName: icon)
                    .font(.system(size: 18, weight: .medium))
                    .foregroundColor(AppTheme.Colors.primary)
                    .frame(width: 24)
                
                Text(title)
                    .font(AppTheme.Typography.headline)
                    .foregroundColor(AppTheme.Colors.textPrimary)
            }
            
            // 内容
            Text(content)
                .font(AppTheme.Typography.body)
                .foregroundColor(AppTheme.Colors.textSecondary)
                .lineSpacing(4)
                .padding(.leading, 32) // 对齐到标题文字下方
        }
        .padding(.horizontal)
        .padding(.vertical, AppTheme.Spacing.s)
    }
}

#Preview {
    PrivacyPolicyView()
}
