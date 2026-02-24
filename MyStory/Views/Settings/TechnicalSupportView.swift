//
//  TechnicalSupportView.swift
//  MyStory
//
//  技术支持页面
//

import SwiftUI

struct TechnicalSupportView: View {
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: AppTheme.Spacing.l) {
                    // 页面说明
                    VStack(alignment: .leading, spacing: AppTheme.Spacing.s) {
                        Text("support.description".localized)
                            .font(AppTheme.Typography.body)
                            .foregroundColor(AppTheme.Colors.textSecondary)
                    }
                    .padding(.horizontal)
                    .padding(.top, AppTheme.Spacing.m)
                    
                    // 查看完整文档按钮
                    VStack(spacing: AppTheme.Spacing.s) {
                        Button(action: {
                            openFullSupportDocument()
                        }) {
                            HStack {
                                Image(systemName: "doc.text")
                                Text("support.viewFullDocument".localized)
                            }
                            .font(AppTheme.Typography.body)
                            .foregroundColor(AppTheme.Colors.primary)
                            .padding(.horizontal, AppTheme.Spacing.l)
                            .padding(.vertical, AppTheme.Spacing.m)
                            .frame(maxWidth: .infinity)
                            .background(
                                RoundedRectangle(cornerRadius: AppTheme.Radius.m)
                                    .stroke(AppTheme.Colors.primary, lineWidth: 1)
                            )
                        }
                    }
                    .padding(.horizontal)
                    .padding(.top, AppTheme.Spacing.l)
                    
                    // 快速帮助部分
                    VStack(alignment: .leading, spacing: AppTheme.Spacing.m) {
                        Text("support.quickHelp".localized)
                            .font(AppTheme.Typography.headline)
                            .foregroundColor(AppTheme.Colors.textPrimary)
                            .padding(.horizontal)
                        
                        QuickHelpSectionView(
                            icon: "questionmark.circle",
                            title: "support.faq".localized,
                            description: "support.faq.description".localized
                        )
                        
                        QuickHelpSectionView(
                            icon: "book",
                            title: "support.tutorials".localized,
                            description: "support.tutorials.description".localized
                        )
                        
                        QuickHelpSectionView(
                            icon: "wrench.and.screwdriver",
                            title: "support.troubleshooting".localized,
                            description: "support.troubleshooting.description".localized
                        )
                        
                        QuickHelpSectionView(
                            icon: "envelope",
                            title: "support.contact".localized,
                            description: "support.contact.description".localized
                        )
                    }
                    .padding(.top, AppTheme.Spacing.xl)
                }
                .padding(.vertical)
            }
            .background(AppTheme.Colors.background)
            .navigationTitle("support.title".localized)
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
    
    private func openFullSupportDocument() {
        // 根据应用设置中的语言选择对应的技术支持文档链接
        let currentLanguage = LocalizationManager.shared.currentLanguage
        let supportURLString: String
        
        if currentLanguage == .chinese {
            // 中文链接
            supportURLString = "https://github.com/GavinZL/MyStory/blob/main/support/SUPPORT_zh-Hans.md"
        } else {
            // 英文链接
            supportURLString = "https://github.com/GavinZL/MyStory/blob/main/support/SUPPORT_en.md"
        }
        
        if let url = URL(string: supportURLString) {
            UIApplication.shared.open(url)
        }
    }
}

// MARK: - Quick Help Section View

private struct QuickHelpSectionView: View {
    let icon: String
    let title: String
    let description: String
    
    var body: some View {
        VStack(alignment: .leading, spacing: AppTheme.Spacing.s) {
            HStack(spacing: AppTheme.Spacing.s) {
                Image(systemName: icon)
                    .font(.system(size: 18, weight: .medium))
                    .foregroundColor(AppTheme.Colors.primary)
                    .frame(width: 24)
                
                Text(title)
                    .font(AppTheme.Typography.headline)
                    .foregroundColor(AppTheme.Colors.textPrimary)
            }
            
            Text(description)
                .font(AppTheme.Typography.body)
                .foregroundColor(AppTheme.Colors.textSecondary)
                .lineSpacing(4)
                .padding(.leading, 32)
        }
        .padding(.horizontal)
        .padding(.vertical, AppTheme.Spacing.s)
    }
}

#Preview {
    TechnicalSupportView()
}
