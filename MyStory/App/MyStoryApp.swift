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

struct RootTabView: View {
    @EnvironmentObject private var coreDataStack: CoreDataStack

    var body: some View {
        TabView {
            TimelineView()
                .tabItem {
                    Image(systemName: "clock")
                    Text("时间轴")
                }
            SettingsPlaceholderView()
                .tabItem {
                    Image(systemName: "gearshape")
                    Text("设置")
                }
        }
    }
}

struct SettingsPlaceholderView: View {
    var body: some View {
        NavigationView {
            Text("设置功能在后续阶段完善")
                .navigationTitle("设置")
        }
    }
}
