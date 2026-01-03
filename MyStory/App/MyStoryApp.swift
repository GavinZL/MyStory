import SwiftUI
import CoreData

@main
struct MyStoryApp: App {
    @StateObject private var coreDataStack = CoreDataStack()
    @StateObject private var localizationManager = LocalizationManager.shared

    var body: some Scene {
        WindowGroup {
            RootView()
//                .environment(_:_) 是一个 View Modifier，作用是：
//                  针对某个 环境键（EnvironmentKey）（这里是 \.managedObjectContext）
//                  设置一个值（这里是 coreDataStack.viewContext）
//                  之后这个 WindowGroup 里的所有子 View，只要声明：
//                  @Environment(\.managedObjectContext) var context
//                  就能拿到同一个 viewContext。
                .environment(\.managedObjectContext, coreDataStack.viewContext)
//                .environmentObject(_:) 是专门给 ObservableObject 用的环境注入方式。
//                  使用方式是：父 View 用 .environmentObject(someObject) 注入；子 View 里这样声明就能拿到：
//                  @EnvironmentObject var coreDataStack: CoreDataStack
                .environmentObject(coreDataStack)
                .environmentObject(AppRouter())
                .environmentObject(localizationManager)
        }
    }
}

//  区别
//    .environment：基于「键」，比如 \.colorScheme、\.managedObjectContext，访问用 @Environment。
//    .environmentObject：基于「类型」，只要类型匹配的 ObservableObject 都能通过 @EnvironmentObject 拿到。
