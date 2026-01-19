//
//  SettingsView.swift
//  MyStory
//
//  设置页面
//

import SwiftUI

struct SettingsView: View {
    @EnvironmentObject var router: AppRouter
    @StateObject private var localizationManager = LocalizationManager.shared
    @ObservedObject private var themeManager = ThemeManager.shared
    @ObservedObject private var fontScaleManager = FontScaleManager.shared
    @State private var showLanguageSettings = false
    @State private var showThemeSettings = false
    @State private var showFontSettings = false
    @State private var showDataSync = false
    @State private var showPrivacyPolicy = false
    @State private var showCacheCleanupConfirm = false
    @State private var isCleaningCache = false
    @State private var showCleanupResult = false
    @State private var cleanupResultTitle = ""
    @State private var cleanupResultMessage = ""
    
    var body: some View {
        NavigationStack {
            List {
                Section("settings.general".localized) {
                    Button {
                        showLanguageSettings = true
                    } label: {
                        HStack {
                            Label("settings.language".localized, systemImage: "globe")
                            Spacer()
                            Text(localizationManager.currentLanguage.displayName)
                                .foregroundColor(.secondary)
                            Image(systemName: "chevron.right")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                    .foregroundColor(.primary)
                    
                    Button {
                        showThemeSettings = true
                    } label: {
                        HStack {
                            Label("settings.theme".localized, systemImage: "paintbrush")
                            Spacer()
                            Text(themeManager.currentTheme.displayName)
                                .foregroundColor(.secondary)
                            Image(systemName: "chevron.right")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                    .foregroundColor(.primary)
                    
                    Button {
                        showFontSettings = true
                    } label: {
                        HStack {
                            Label("settings.font".localized, systemImage: "textformat.size")
                            Spacer()
                            Text(fontScaleManager.currentScale.displayName)
                                .foregroundColor(.secondary)
                            Image(systemName: "chevron.right")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                    .foregroundColor(.primary)
                }
                
                // 数据同步入口
                Section {
                    Button {
                        showDataSync = true
                    } label: {
                        HStack {
                            Label("settings.dataSync".localized, systemImage: "arrow.triangle.2.circlepath")
                            Spacer()
                            Image(systemName: "chevron.right")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                    .foregroundColor(.primary)
                    
                    // 缓存清理
                    Button {
                        showCacheCleanupConfirm = true
                    } label: {
                        HStack {
                            Label("settings.cacheCleanup".localized, systemImage: "trash")
                            Spacer()
                            if isCleaningCache {
                                ProgressView()
                                    .progressViewStyle(CircularProgressViewStyle())
                            } else {
                                Image(systemName: "chevron.right")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                        }
                    }
                    .foregroundColor(.primary)
                    .disabled(isCleaningCache)
                }
                
                Section("settings.about".localized) {
                    Button {
                        showPrivacyPolicy = true
                    } label: {
                        HStack {
                            Label("settings.privacyPolicy".localized, systemImage: "hand.raised")
                            Spacer()
                            Image(systemName: "chevron.right")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                    .foregroundColor(.primary)
                    
                    HStack {
                        Text("settings.version".localized)
                        Spacer()
                        Text("1.0.0")
                            .foregroundColor(AppTheme.Colors.textSecondary)
                    }
                }
            }
            .navigationTitle("settings.title".localized)
            .navigationBarTitleDisplayMode(.inline)
            .sheet(isPresented: $showLanguageSettings) {
                LanguageSettingsView()
            }
            .sheet(isPresented: $showThemeSettings) {
                ThemeSettingsView()
            }
            .sheet(isPresented: $showFontSettings) {
                FontSettingsView()
            }
            .sheet(isPresented: $showDataSync) {
                DataSyncView()
            }
            .sheet(isPresented: $showPrivacyPolicy) {
                PrivacyPolicyView()
            }
            .alert("settings.cacheCleanup.confirm.title".localized, isPresented: $showCacheCleanupConfirm) {
                Button("common.cancel".localized, role: .cancel) { }
                Button("common.confirm".localized) {
                    performCacheCleanup()
                }
            } message: {
                Text("settings.cacheCleanup.confirm.message".localized)
            }
            .alert(cleanupResultTitle, isPresented: $showCleanupResult) {
                Button("common.confirm".localized) { }
            } message: {
                Text(cleanupResultMessage)
            }
            .overlay {
                if isCleaningCache {
                    ZStack {
                        Color.black.opacity(0.3)
                            .ignoresSafeArea()
                        
                        VStack(spacing: AppTheme.Spacing.l) {
                            ProgressView()
                                .scaleEffect(1.5)
                                .progressViewStyle(CircularProgressViewStyle(tint: .white))
                            
                            Text("settings.cacheCleanup.inProgress".localized)
                                .font(AppTheme.Typography.body)
                                .foregroundColor(.white)
                        }
                        .padding(AppTheme.Spacing.xxl)
                        .background(
                            RoundedRectangle(cornerRadius: AppTheme.Radius.m)
                                .fill(Color.black.opacity(0.8))
                        )
                    }
                }
            }
        }
    }
    
    // MARK: - Private Methods
    
    /// 执行缓存清理
    private func performCacheCleanup() {
        isCleaningCache = true
        
        // 在后台线程执行清理
        DispatchQueue.global(qos: .userInitiated).async {
            let result = CacheCleanupService.cleanupCache()
            
            // 回到主线程更新 UI
            DispatchQueue.main.async {
                isCleaningCache = false
                
                if result.deletedFilesCount == 0 && result.errors.isEmpty {
                    // 没有可清理的文件
                    cleanupResultTitle = "settings.cacheCleanup.empty.title".localized
                    cleanupResultMessage = "settings.cacheCleanup.empty.message".localized
                } else if !result.errors.isEmpty {
                    // 清理过程中有错误
                    cleanupResultTitle = "settings.cacheCleanup.error.title".localized
                    let errorMessage = result.errors.joined(separator: "\n")
                    cleanupResultMessage = String(format: "settings.cacheCleanup.error.message".localized, errorMessage)
                } else {
                    // 清理成功
                    cleanupResultTitle = "settings.cacheCleanup.success.title".localized
                    cleanupResultMessage = String(
                        format: "settings.cacheCleanup.success.message".localized,
                        result.deletedFilesCount,
                        result.freedSpaceMB
                    )
                }
                
                showCleanupResult = true
            }
        }
    }
}
