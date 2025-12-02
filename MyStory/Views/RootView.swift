import SwiftUI

struct RootView: View {
    @EnvironmentObject var router: AppRouter
    @Environment(\.managedObjectContext) private var context
    
    var body: some View {
        TabView {
            // 时间轴页面
            TimelineView()
                .tabItem {
                    Label("时间轴", systemImage: "clock.fill")
                }
            
            // 分类页面
            NavigationStack {
                CategoryView(viewModel: CategoryViewModel(service: CoreDataCategoryService(context: context)))
            }
            .tabItem {
                Label("分类", systemImage: "folder.fill")
            }
            
            // 设置页面
            SettingsView()
                .tabItem {
                    Label("设置", systemImage: "gearshape.fill")
                }
        }
        .accentColor(.appPrimary)
    }
}

#Preview {
    RootView()
        .environmentObject(AppRouter())
        .environment(\.managedObjectContext, PersistenceController.preview.container.viewContext)
}
