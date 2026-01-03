import Foundation
import CoreData

final class CoreDataStack: ObservableObject {
    let persistentContainer: NSPersistentContainer
    var viewContext: NSManagedObjectContext { persistentContainer.viewContext }

    init() {
        let model = Self.makeModel()
        persistentContainer = NSPersistentContainer(name: "MyStoryModel", managedObjectModel: model)
        let description = NSPersistentStoreDescription()
        description.type = NSSQLiteStoreType
        description.shouldAddStoreAsynchronously = false
        description.url = Self.defaultStoreURL()
        
        #if DEBUG
        // ⚠️ 临时：强制删除旧数据库（模型结构变更时使用）
        if let storeURL = description.url {
            try? FileManager.default.removeItem(at: storeURL)
            try? FileManager.default.removeItem(at: URL(fileURLWithPath: storeURL.path + "-wal"))
            try? FileManager.default.removeItem(at: URL(fileURLWithPath: storeURL.path + "-shm"))
            print("🗑️ [CoreDataStack] 已删除旧数据库: \(storeURL.lastPathComponent)")
        }
        #endif
        
        persistentContainer.persistentStoreDescriptions = [description]
        persistentContainer.loadPersistentStores { _, error in
            if let error = error {
                fatalError("Failed to load store: \(error)")
            }
            print("✅ [CoreDataStack] 数据库加载成功")
            self.persistentContainer.viewContext.mergePolicy = NSMergeByPropertyObjectTrumpMergePolicy
            self.persistentContainer.viewContext.automaticallyMergesChangesFromParent = true
        }
    }

    func save() {
        let context = viewContext
        if context.hasChanges {
            do { try context.save() } catch { print("CoreData save error: \(error)") }
        }
    }

    private static func defaultStoreURL() -> URL {
        let urls = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)
        return urls[0].appendingPathComponent("MyStory.sqlite")
    }

    private static func makeModel() -> NSManagedObjectModel {
        let model = NSManagedObjectModel()

        // StoryEntity
        let storyEntity = NSEntityDescription()
        storyEntity.name = "StoryEntity"
        storyEntity.managedObjectClassName = "StoryEntity"

        let s_id = NSAttributeDescription()
        s_id.name = "id"
        s_id.attributeType = .UUIDAttributeType
        s_id.isOptional = false

        let s_title = NSAttributeDescription()
        s_title.name = "title"
        s_title.attributeType = .stringAttributeType
        s_title.isOptional = false

        let s_content = NSAttributeDescription()
        s_content.name = "content"
        s_content.attributeType = .stringAttributeType
        s_content.isOptional = true
        
        let s_plainTextContent = NSAttributeDescription()
        s_plainTextContent.name = "plainTextContent"
        s_plainTextContent.attributeType = .stringAttributeType
        s_plainTextContent.isOptional = true

        let s_timestamp = NSAttributeDescription()
        s_timestamp.name = "timestamp"
        s_timestamp.attributeType = .dateAttributeType
        s_timestamp.isOptional = false

        let s_createdAt = NSAttributeDescription()
        s_createdAt.name = "createdAt"
        s_createdAt.attributeType = .dateAttributeType
        s_createdAt.isOptional = false

        let s_updatedAt = NSAttributeDescription()
        s_updatedAt.name = "updatedAt"
        s_updatedAt.attributeType = .dateAttributeType
        s_updatedAt.isOptional = false

        let s_locationName = NSAttributeDescription()
        s_locationName.name = "locationName"
        s_locationName.attributeType = .stringAttributeType
        s_locationName.isOptional = true

        let s_locationCity = NSAttributeDescription()
        s_locationCity.name = "locationCity"
        s_locationCity.attributeType = .stringAttributeType
        s_locationCity.isOptional = true
        
        let s_locationAddress = NSAttributeDescription()
        s_locationAddress.name = "locationAddress"
        s_locationAddress.attributeType = .stringAttributeType
        s_locationAddress.isOptional = true

        let s_latitude = NSAttributeDescription()
        s_latitude.name = "latitude"
        s_latitude.attributeType = .doubleAttributeType
        s_latitude.isOptional = true

        let s_longitude = NSAttributeDescription()
        s_longitude.name = "longitude"
        s_longitude.attributeType = .doubleAttributeType
        s_longitude.isOptional = true
        
        let s_mood = NSAttributeDescription()
        s_mood.name = "mood"
        s_mood.attributeType = .stringAttributeType
        s_mood.isOptional = true
        
        let s_syncStatus = NSAttributeDescription()
        s_syncStatus.name = "syncStatus"
        s_syncStatus.attributeType = .integer16AttributeType
        s_syncStatus.isOptional = false
        s_syncStatus.defaultValue = 0
        
        let s_isDeleted = NSAttributeDescription()
        s_isDeleted.name = "isDeleted"
        s_isDeleted.attributeType = .booleanAttributeType
        s_isDeleted.isOptional = false
        s_isDeleted.defaultValue = false

        storyEntity.properties = [
            s_id, s_title, s_content, s_plainTextContent, s_timestamp, s_createdAt, s_updatedAt,
            s_locationName, s_locationCity, s_locationAddress, s_latitude, s_longitude,
            s_mood, s_syncStatus, s_isDeleted
        ]

        // CategoryEntity
        let categoryEntity = NSEntityDescription()
        categoryEntity.name = "CategoryEntity"
        categoryEntity.managedObjectClassName = "CategoryEntity"
        
        let c_id = NSAttributeDescription()
        c_id.name = "id"
        c_id.attributeType = .UUIDAttributeType
        c_id.isOptional = false
        
        let c_name = NSAttributeDescription()
        c_name.name = "name"
        c_name.attributeType = .stringAttributeType
        c_name.isOptional = false
        
        let c_nameEn = NSAttributeDescription()
        c_nameEn.name = "nameEn"
        c_nameEn.attributeType = .stringAttributeType
        c_nameEn.isOptional = true
        
        let c_iconName = NSAttributeDescription()
        c_iconName.name = "iconName"
        c_iconName.attributeType = .stringAttributeType
        c_iconName.isOptional = false
        
        let c_colorHex = NSAttributeDescription()
        c_colorHex.name = "colorHex"
        c_colorHex.attributeType = .stringAttributeType
        c_colorHex.isOptional = true
        c_colorHex.defaultValue = "#007AFF"
        
        let c_level = NSAttributeDescription()
        c_level.name = "level"
        c_level.attributeType = .integer16AttributeType
        c_level.isOptional = false
        c_level.defaultValue = 1
        
        let c_sortOrder = NSAttributeDescription()
        c_sortOrder.name = "sortOrder"
        c_sortOrder.attributeType = .integer32AttributeType
        c_sortOrder.isOptional = false
        c_sortOrder.defaultValue = 0
        
        let c_createdAt = NSAttributeDescription()
        c_createdAt.name = "createdAt"
        c_createdAt.attributeType = .dateAttributeType
        c_createdAt.isOptional = false
        
        // ✅ 新增：图标类型和自定义图标数据
        let c_iconType = NSAttributeDescription()
        c_iconType.name = "iconType"
        c_iconType.attributeType = .stringAttributeType
        c_iconType.isOptional = false
        c_iconType.defaultValue = "system"
        
        let c_customIconData = NSAttributeDescription()
        c_customIconData.name = "customIconData"
        c_customIconData.attributeType = .binaryDataAttributeType
        c_customIconData.isOptional = true
        
        categoryEntity.properties = [
            c_id, c_name, c_nameEn, c_iconName, c_colorHex, c_level, c_sortOrder, c_createdAt,
            c_iconType, c_customIconData  // ✅ 新增字段
        ]

        // MediaEntity
        let mediaEntity = NSEntityDescription()
        mediaEntity.name = "MediaEntity"
        mediaEntity.managedObjectClassName = "MediaEntity"

        let m_id = NSAttributeDescription()
        m_id.name = "id"
        m_id.attributeType = .UUIDAttributeType
        m_id.isOptional = false

        let m_type = NSAttributeDescription()
        m_type.name = "type"
        m_type.attributeType = .stringAttributeType
        m_type.isOptional = false

        let m_fileName = NSAttributeDescription()
        m_fileName.name = "fileName"
        m_fileName.attributeType = .stringAttributeType
        m_fileName.isOptional = false

        let m_thumbnail = NSAttributeDescription()
        m_thumbnail.name = "thumbnailFileName"
        m_thumbnail.attributeType = .stringAttributeType
        m_thumbnail.isOptional = true

        let m_createdAt = NSAttributeDescription()
        m_createdAt.name = "createdAt"
        m_createdAt.attributeType = .dateAttributeType
        m_createdAt.isOptional = false

        let m_width = NSAttributeDescription()
        m_width.name = "width"
        m_width.attributeType = .integer32AttributeType
        m_width.isOptional = true

        let m_height = NSAttributeDescription()
        m_height.name = "height"
        m_height.attributeType = .integer32AttributeType
        m_height.isOptional = true

        let m_duration = NSAttributeDescription()
        m_duration.name = "duration"
        m_duration.attributeType = .doubleAttributeType
        m_duration.isOptional = true

        // Relationships: Story <-> Media
        let r_story_to_media = NSRelationshipDescription()
        r_story_to_media.name = "media"
        r_story_to_media.destinationEntity = mediaEntity
        r_story_to_media.minCount = 0
        r_story_to_media.maxCount = 0 // to-many
        r_story_to_media.deleteRule = .cascadeDeleteRule

        let r_media_to_story = NSRelationshipDescription()
        r_media_to_story.name = "story"
        r_media_to_story.destinationEntity = storyEntity
        r_media_to_story.minCount = 0
        r_media_to_story.maxCount = 1
        r_media_to_story.deleteRule = .nullifyDeleteRule

        r_story_to_media.inverseRelationship = r_media_to_story
        r_media_to_story.inverseRelationship = r_story_to_media
        
        // Relationships: Story <-> Category (Many-to-Many)
        let r_story_to_categories = NSRelationshipDescription()
        r_story_to_categories.name = "categories"
        r_story_to_categories.destinationEntity = categoryEntity
        r_story_to_categories.minCount = 0
        r_story_to_categories.maxCount = 0 // to-many
        r_story_to_categories.deleteRule = .nullifyDeleteRule
        
        let r_category_to_stories = NSRelationshipDescription()
        r_category_to_stories.name = "stories"
        r_category_to_stories.destinationEntity = storyEntity
        r_category_to_stories.minCount = 0
        r_category_to_stories.maxCount = 0 // to-many
        r_category_to_stories.deleteRule = .nullifyDeleteRule
        
        r_story_to_categories.inverseRelationship = r_category_to_stories
        r_category_to_stories.inverseRelationship = r_story_to_categories
        
        // Relationships: Category parent-children (self-referencing)
        let r_category_to_parent = NSRelationshipDescription()
        r_category_to_parent.name = "parent"
        r_category_to_parent.destinationEntity = categoryEntity
        r_category_to_parent.minCount = 0
        r_category_to_parent.maxCount = 1 // to-one
        r_category_to_parent.deleteRule = .nullifyDeleteRule
        
        let r_category_to_children = NSRelationshipDescription()
        r_category_to_children.name = "children"
        r_category_to_children.destinationEntity = categoryEntity
        r_category_to_children.minCount = 0
        r_category_to_children.maxCount = 0 // to-many
        r_category_to_children.deleteRule = .cascadeDeleteRule
        
        r_category_to_parent.inverseRelationship = r_category_to_children
        r_category_to_children.inverseRelationship = r_category_to_parent

        storyEntity.properties.append(r_story_to_media)
        storyEntity.properties.append(r_story_to_categories)
        
        categoryEntity.properties.append(r_category_to_stories)
        categoryEntity.properties.append(r_category_to_parent)
        categoryEntity.properties.append(r_category_to_children)
        
        mediaEntity.properties = [
            m_id, m_type, m_fileName, m_thumbnail, m_createdAt, m_width, m_height, m_duration,
            r_media_to_story
        ]

        model.entities = [storyEntity, categoryEntity, mediaEntity]
        return model
    }
}
