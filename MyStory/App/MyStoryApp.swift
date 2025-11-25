import SwiftUI
import CoreData

@main
struct MyStoryApp: App {
    @StateObject private var coreDataStack = CoreDataStack()

    var body: some Scene {
        WindowGroup {
            RootView()
                .environment(\.managedObjectContext, coreDataStack.viewContext)
                .environmentObject(coreDataStack)
                .environmentObject(AppRouter())
        }
    }
}
