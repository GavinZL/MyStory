import SwiftUI

struct RootView: View {
    @EnvironmentObject var router: AppRouter
    @Environment(\.managedObjectContext) private var context
    @StateObject private var localizationManager = LocalizationManager.shared
    
    var body: some View {
        TabView {
            // 时间轴页面
            TimelineView()
                .tabItem {
                    Label("tab.timeline".localized, systemImage: "clock.fill")
                }
            
            // 分类页面
            NavigationStack {
                CategoryView(viewModel: CategoryViewModel(service: CoreDataCategoryService(context: context)))
            }
            .tabItem {
                Label("tab.category".localized, systemImage: "folder.fill")
            }
            
            // 设置页面
            SettingsView()
                .tabItem {
                    Label("tab.settings".localized, systemImage: "gearshape.fill")
                }
        }
        .accentColor(AppTheme.Colors.primary)
    }
}

#Preview {
    RootView()
        .environmentObject(AppRouter())
        .environment(\.managedObjectContext, PersistenceController.preview.container.viewContext)
}
