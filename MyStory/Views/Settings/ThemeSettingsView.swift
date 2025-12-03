//
//  ThemeSettingsView.swift
//  MyStory
//
//  主题设置页面
//

import SwiftUI

struct ThemeSettingsView: View {
    @StateObject private var themeManager = ThemeManager.shared
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        NavigationStack {
            List {
                Section {
                    ForEach(ThemeType.allCases) { theme in
                        ThemeOptionRow(
                            theme: theme,
                            isSelected: themeManager.currentTheme == theme
                        )
                        .contentShape(Rectangle())
                        .onTapGesture {
                            withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                                themeManager.setTheme(theme)
                            }
                        }
                    }
                } header: {
                    Text("settings.theme.selectTheme".localized)
                } footer: {
                    Text("settings.theme.hint".localized)
                        .font(AppTheme.Typography.footnote)
                }
            }
            .navigationTitle("settings.theme".localized)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("common.done".localized) {
                        dismiss()
                    }
                }
            }
        }
    }
}

// MARK: - Theme Option Row
struct ThemeOptionRow: View {
    let theme: ThemeType
    let isSelected: Bool
    
    var body: some View {
        HStack(spacing: AppTheme.Spacing.l) {
            // 主题预览卡片
            ThemePreviewCard(theme: theme)
            
            // 主题信息
            VStack(alignment: .leading, spacing: AppTheme.Spacing.xs) {
                Text(theme.displayName)
                    .font(AppTheme.Typography.headline)
                    .foregroundColor(AppTheme.Colors.textPrimary)
                
                Text(theme.description)
                    .font(AppTheme.Typography.caption)
                    .foregroundColor(AppTheme.Colors.textSecondary)
                    .lineLimit(2)
            }
            
            Spacer()
            
            // 选中标记
            if isSelected {
                Image(systemName: "checkmark.circle.fill")
                    .font(.title3)
                    .foregroundColor(AppTheme.Colors.primary)
                    .transition(.scale.combined(with: .opacity))
            }
        }
        .padding(.vertical, AppTheme.Spacing.s)
    }
}

// MARK: - Theme Preview Card
struct ThemePreviewCard: View {
    let theme: ThemeType
    
    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: AppTheme.Radius.s)
                .fill(theme.previewColors.surface)
                .frame(width: 60, height: 60)
            
            VStack(spacing: 4) {
                Circle()
                    .fill(theme.previewColors.primary)
                    .frame(width: 20, height: 20)
                
                HStack(spacing: 4) {
                    RoundedRectangle(cornerRadius: 2)
                        .fill(theme.previewColors.primary.opacity(0.6))
                        .frame(width: 12, height: 4)
                    
                    RoundedRectangle(cornerRadius: 2)
                        .fill(theme.previewColors.primary.opacity(0.3))
                        .frame(width: 12, height: 4)
                }
            }
        }
        .overlay(
            RoundedRectangle(cornerRadius: AppTheme.Radius.s)
                .stroke(AppTheme.Colors.border, lineWidth: 1)
        )
    }
}

#Preview {
    ThemeSettingsView()
}
