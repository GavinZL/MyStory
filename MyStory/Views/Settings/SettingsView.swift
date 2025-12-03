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
    @State private var showLanguageSettings = false
    
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
                    
                    NavigationLink {
                        Text("settings.themeSetting".localized)
                    } label: {
                        Label("settings.theme".localized, systemImage: "paintbrush")
                    }
                }
                
                Section("settings.about".localized) {
                    HStack {
                        Text("settings.version".localized)
                        Spacer()
                        Text("1.0.0")
                            .foregroundColor(.appSecondaryText)
                    }
                }
            }
            .navigationTitle("settings.title".localized)
            .sheet(isPresented: $showLanguageSettings) {
                LanguageSettingsView()
            }
        }
    }
}

#Preview {
    SettingsView()
        .environmentObject(AppRouter())
}
