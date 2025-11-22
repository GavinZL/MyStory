//
//  PersistenceController.swift
//  MyStory
//
//  Core Data持久化控制器
//  负责管理Core Data栈的初始化和配置
//

import CoreData

class PersistenceController: ObservableObject {
    // 单例模式
    static let shared = PersistenceController()
    
    // 预览模式使用的临时持久化控制器
    static var preview: PersistenceController = {
        let controller = PersistenceController(inMemory: true)
        let viewContext = controller.container.viewContext
        
        // 创建示例数据用于预览
        for i in 0..<10 {
            let story = StoryEntity(context: viewContext)
            story.id = UUID()
            story.title = "示例故事 \(i + 1)"
            story.content = "这是一个示例故事的内容..."
            story.timestamp = Date().addingTimeInterval(TimeInterval(-i * 86400))
            story.createdAt = Date()
            story.updatedAt = Date()
            story.plainTextContent = story.content
            story.syncStatus = 0
            story.isDeleted = false
        }
        
        do {
            try viewContext.save()
        } catch {
            let nsError = error as NSError
            fatalError("无法保存预览数据: \(nsError), \(nsError.userInfo)")
        }
        
        return controller
    }()
    
    // NSPersistentContainer
    let container: NSPersistentContainer
    
    // 初始化方法
    init(inMemory: Bool = false) {
        container = NSPersistentContainer(name: "MyStory")
        
        if inMemory {
            // 内存模式，用于测试和预览
            container.persistentStoreDescriptions.first?.url = URL(fileURLWithPath: "/dev/null")
        }
        
        // 配置持久化存储
        container.persistentStoreDescriptions.first?.setOption(true as NSNumber,
                                                                forKey: NSPersistentHistoryTrackingKey)
        container.persistentStoreDescriptions.first?.setOption(true as NSNumber,
                                                                forKey: NSPersistentStoreRemoteChangeNotificationPostOptionKey)
        
        container.loadPersistentStores { description, error in
            if let error = error as NSError? {
                fatalError("无法加载Core Data存储: \(error), \(error.userInfo)")
            }
        }
        
        // 配置视图上下文
        container.viewContext.automaticallyMergesChangesFromParent = true
        container.viewContext.mergePolicy = NSMergeByPropertyObjectTrumpMergePolicy
    }
    
    // MARK: - 保存上下文
    
    func saveContext() {
        let context = container.viewContext
        
        if context.hasChanges {
            do {
                try context.save()
            } catch {
                let nsError = error as NSError
                print("保存上下文时出错: \(nsError), \(nsError.userInfo)")
            }
        }
    }
    
    // MARK: - 批量操作
    
    /// 创建后台上下文用于批量操作
    func newBackgroundContext() -> NSManagedObjectContext {
        let context = container.newBackgroundContext()
        context.mergePolicy = NSMergeByPropertyObjectTrumpMergePolicy
        return context
    }
}
