import SwiftUI
import CoreData

@main
struct MyStoryApp: App {
    @StateObject private var coreDataStack = CoreDataStack()
    @StateObject private var localizationManager = LocalizationManager.shared

    var body: some Scene {
        WindowGroup {
            RootView()
                .environment(\.managedObjectContext, coreDataStack.viewContext)
                .environmentObject(coreDataStack)
                .environmentObject(AppRouter())
                .environmentObject(localizationManager)
        }
    }
}
