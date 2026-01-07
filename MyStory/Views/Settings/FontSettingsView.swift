//
//  FontSettingsView.swift
//  MyStory
//
//  字体设置页面
//

import SwiftUI

struct FontSettingsView: View {
    @Environment(\.dismiss) private var dismiss
    @ObservedObject private var fontScaleManager = FontScaleManager.shared
    
    // 本地预览状态，不立即同步到全局
    @State private var sliderValue: Double
    @State private var previewScale: FontScale
    
    init() {
        let currentScale = FontScaleManager.shared.currentScale
        _sliderValue = State(initialValue: currentScale.sliderValue)
        _previewScale = State(initialValue: currentScale)
    }
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // 预览区域
                previewSection
                    .frame(maxHeight: .infinity)
                
                // 底部控制区
                controlSection
                    .background(Color(UIColor.systemGroupedBackground))
            }
            .navigationTitle("settings.font.title".localized)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button {
                        // 退出时应用设置
                        applySettings()
                        dismiss()
                    } label: {
                        HStack(spacing: 4) {
                            Image(systemName: "chevron.left")
                                .font(.system(size: 17, weight: .medium))
                            Text("common.cancel".localized)
                        }
                        .foregroundColor(AppTheme.Colors.primary)
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("settings.font.reset".localized) {
                        withAnimation {
                            sliderValue = FontScale.standard.sliderValue
                            previewScale = .standard
                        }
                    }
                    .foregroundColor(AppTheme.Colors.primary)
                }
            }
            .interactiveDismissDisabled(false)
            .onDisappear {
                // 用户下滑关闭时也应用设置
                applySettings()
            }
        }
    }
    
    // MARK: - Preview Section
    
    private var previewSection: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: AppTheme.Spacing.xl) {
                // 欢迎文本
                Text("settings.font.preview.welcome".localized)
                    .font(previewFont(baseSize: 22)) // 使用动态字体
                    .foregroundColor(AppTheme.Colors.textPrimary)
                
                // 说明文本 - 段落1
                Text("settings.font.preview.description1".localized)
                    .font(previewFont(baseSize: 17)) // 使用动态字体
                    .foregroundColor(AppTheme.Colors.textPrimary)
                    .lineSpacing(4)
                
                // 说明文本 - 段落2
                Text("settings.font.preview.description2".localized)
                    .font(previewFont(baseSize: 17)) // 使用动态字体
                    .foregroundColor(AppTheme.Colors.textPrimary)
                    .lineSpacing(4)
                
                // 功能列表标题
                Text("settings.font.preview.featuresTitle".localized)
                    .font(previewFont(baseSize: 17, weight: .semibold)) // 使用动态字体
                    .foregroundColor(AppTheme.Colors.textPrimary)
                    .padding(.top, AppTheme.Spacing.s)
                
                // 功能列表
                VStack(alignment: .leading, spacing: AppTheme.Spacing.m) {
                    featureRow(icon: "text.alignleft", text: "settings.font.preview.feature1".localized)
                    featureRow(icon: "photo.on.rectangle", text: "settings.font.preview.feature2".localized)
                    featureRow(icon: "waveform", text: "settings.font.preview.feature3".localized)
                    featureRow(icon: "heart.fill", text: "settings.font.preview.feature4".localized)
                    featureRow(icon: "map.fill", text: "settings.font.preview.feature5".localized)
                }
                
                // 底部提示
                Text("settings.font.preview.closing".localized)
                    .font(previewFont(baseSize: 17)) // 使用动态字体
                    .foregroundColor(AppTheme.Colors.textPrimary)
                    .lineSpacing(4)
                    .padding(.top, AppTheme.Spacing.s)
            }
            .padding(AppTheme.Spacing.xl)
        }
        .background(Color(UIColor.systemBackground))
    }
    
    private func featureRow(icon: String, text: String) -> some View {
        HStack(spacing: AppTheme.Spacing.m) {
            Image(systemName: icon)
                .font(.system(size: 16))
                .foregroundColor(AppTheme.Colors.primary)
                .frame(width: 24)
            
            Text(text)
                .font(previewFont(baseSize: 17)) // 使用动态字体
                .foregroundColor(AppTheme.Colors.textPrimary)
        }
    }
    
    // MARK: - Control Section
    
    private var controlSection: some View {
        VStack(spacing: AppTheme.Spacing.l) {
            // 标题
            HStack {
                Text("settings.font.label".localized)
                    .font(AppTheme.Typography.headline)
                    .foregroundColor(AppTheme.Colors.textPrimary)
                Spacer()
                Text(previewScale.displayName)
                    .font(AppTheme.Typography.subheadline)
                    .foregroundColor(AppTheme.Colors.textSecondary)
            }
            .padding(.horizontal, AppTheme.Spacing.xl)
            
            // 滑块
            HStack(spacing: AppTheme.Spacing.l) {
                // 小号 A
                Text("A")
                    .font(.system(size: 14))
                    .foregroundColor(AppTheme.Colors.textSecondary)
                    .frame(width: 24)
                
                // 滑块
                Slider(value: $sliderValue, in: 0...3, step: 1)
                    .tint(AppTheme.Colors.primary)
                    .onChange(of: sliderValue) { newValue in
                        // 只更新本地预览状态，不同步到全局
                        let newScale = FontScale.from(sliderValue: newValue)
                        withAnimation(.easeInOut(duration: 0.2)) {
                            previewScale = newScale
                        }
                    }
                
                // 大号 A
                Text("A")
                    .font(.system(size: 24, weight: .medium))
                    .foregroundColor(AppTheme.Colors.textSecondary)
                    .frame(width: 24)
            }
            .padding(.horizontal, AppTheme.Spacing.xl)
            
            // 说明文本
            Text("settings.font.hint".localized)
                .font(AppTheme.Typography.caption)
                .foregroundColor(AppTheme.Colors.textSecondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, AppTheme.Spacing.xl)
        }
        .padding(.vertical, AppTheme.Spacing.xl)
        .background(
            RoundedRectangle(cornerRadius: AppTheme.Radius.l)
                .fill(Color(UIColor.systemBackground))
                .shadow(
                    color: AppTheme.Shadow.small.color,
                    radius: AppTheme.Shadow.small.radius,
                    x: AppTheme.Shadow.small.x,
                    y: AppTheme.Shadow.small.y
                )
        )
        .padding(AppTheme.Spacing.l)
    }
    
    // MARK: - Helper Methods
    
    /// 生成预览字体（基于当前预览缩放比例）
    private func previewFont(baseSize: CGFloat, weight: Font.Weight = .regular) -> Font {
        return Font.system(size: baseSize * previewScale.scale, weight: weight)
    }
    
    /// 应用设置到全局
    private func applySettings() {
        if previewScale != fontScaleManager.currentScale {
            fontScaleManager.setScale(previewScale)
        }
    }
}

#Preview {
    FontSettingsView()
}
