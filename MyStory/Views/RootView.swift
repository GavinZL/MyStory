import SwiftUI

struct RootView: View {
    @EnvironmentObject var router: AppRouter
    @Environment(\.managedObjectContext) private var context
    @StateObject private var localizationManager = LocalizationManager.shared
    @StateObject private var themeManager = ThemeManager.shared
    @StateObject private var fontScaleManager = FontScaleManager.shared
    
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
        .id(themeManager.currentTheme) // 强制在主题变化时重新渲染
        .id(fontScaleManager.currentScale) // 强制在字体缩放变化时重新渲染
    }
}

#Preview {
    RootView()
        .environmentObject(AppRouter())
        .environment(\.managedObjectContext, CoreDataStack.preview.viewContext)
}
