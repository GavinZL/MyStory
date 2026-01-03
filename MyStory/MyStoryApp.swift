//
//  MyStoryApp.swift
//  MyStory
//
//  Created on 2025-11-21.
//

import SwiftUI

@main
struct MyStoryApp: App {
    // Core Data持久化控制器
    @StateObject private var coreDataStack = CoreDataStack()
    
    // 路由协调器
    @StateObject private var router = AppRouter()
    
    // 多语言管理器
    @StateObject private var localizationManager = LocalizationManager.shared
    
    var body: some Scene {
        WindowGroup {
            RootView()
                .environment(\.managedObjectContext, coreDataStack.viewContext)
                .environmentObject(coreDataStack)
                .environmentObject(router)
                .environmentObject(localizationManager)
        }
    }
}
