//
//  SettingsView.swift
//  MyStory
//
//  设置页面
//

import SwiftUI

struct SettingsView: View {
    @EnvironmentObject var router: AppRouter
    
    var body: some View {
        NavigationStack {
            List {
                Section("通用") {
                    NavigationLink {
                        Text("语言设置")
                    } label: {
                        Label("语言", systemImage: "globe")
                    }
                    
                    NavigationLink {
                        Text("主题设置")
                    } label: {
                        Label("主题", systemImage: "paintbrush")
                    }
                }
                
                Section("关于") {
                    HStack {
                        Text("版本")
                        Spacer()
                        Text("1.0.0")
                            .foregroundColor(.appSecondaryText)
                    }
                }
            }
            .navigationTitle("设置")
        }
    }
}

#Preview {
    SettingsView()
        .environmentObject(AppRouter())
}
