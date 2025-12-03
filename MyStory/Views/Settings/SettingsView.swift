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
    @StateObject private var themeManager = ThemeManager.shared
    @State private var showLanguageSettings = false
    @State private var showThemeSettings = false
    
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
                }
                
                Section("settings.about".localized) {
                    HStack {
                        Text("settings.version".localized)
                        Spacer()
                        Text("1.0.0")
                            .foregroundColor(AppTheme.Colors.textSecondary)
                    }
                }
            }
            .navigationTitle("settings.title".localized)
            .sheet(isPresented: $showLanguageSettings) {
                LanguageSettingsView()
            }
            .sheet(isPresented: $showThemeSettings) {
                ThemeSettingsView()
            }
        }
    }
}

#Preview {
    SettingsView()
        .environmentObject(AppRouter())
}
