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
    @StateObject private var persistenceController = PersistenceController.shared
    
    // 路由协调器
    @StateObject private var router = AppRouter()
    
    var body: some Scene {
        WindowGroup {
            RootView()
                .environment(\.managedObjectContext, persistenceController.container.viewContext)
                .environmentObject(router)
        }
    }
}
