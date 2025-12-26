//
//  LanguageSettingsView.swift
//  MyStory
//
//  语言设置页面
//

import SwiftUI

struct LanguageSettingsView: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var localizationManager = LocalizationManager.shared
    @State private var selectedLanguage: AppLanguage
    
    init() {
        _selectedLanguage = State(initialValue: LocalizationManager.shared.currentLanguage)
    }
    
    var body: some View {
        NavigationView {
            List {
                Section {
                    ForEach(AppLanguage.allCases, id: \.self) { language in
                        Button {
                            selectedLanguage = language
                        } label: {
                            HStack {
                                Text(language.displayName)
                                    .foregroundColor(.primary)
                                Spacer()
                                if selectedLanguage == language {
                                    Image(systemName: "checkmark")
                                        .foregroundColor(AppTheme.Colors.primary)
                                }
                            }
                        }
                    }
                } header: {
                    Text("settings.currentLanguage".localized)
                }
            }
            .navigationTitle("settings.languageSetting".localized)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("common.cancel".localized) {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("common.done".localized) {
                        applyLanguageChange()
                    }
                    .disabled(selectedLanguage == localizationManager.currentLanguage)
                }
            }
        }
    }
    
    private func applyLanguageChange() {
        localizationManager.setLanguage(selectedLanguage)
        dismiss()
    }
}

#Preview {
    LanguageSettingsView()
}
