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
        persistentContainer.persistentStoreDescriptions = [description]
        persistentContainer.loadPersistentStores { _, error in
            if let error = error {
                fatalError("Failed to load store: \(error)")
            }
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

        let s_latitude = NSAttributeDescription()
        s_latitude.name = "latitude"
        s_latitude.attributeType = .doubleAttributeType
        s_latitude.isOptional = true

        let s_longitude = NSAttributeDescription()
        s_longitude.name = "longitude"
        s_longitude.attributeType = .doubleAttributeType
        s_longitude.isOptional = true

        storyEntity.properties = [
            s_id, s_title, s_content, s_timestamp, s_createdAt, s_updatedAt,
            s_locationName, s_locationCity, s_latitude, s_longitude
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

        // Relationships
        let r_story_to_media = NSRelationshipDescription()
        r_story_to_media.name = "medias"
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

        storyEntity.properties.append(r_story_to_media)
        mediaEntity.properties = [
            m_id, m_type, m_fileName, m_thumbnail, m_createdAt, m_width, m_height, m_duration,
            r_media_to_story
        ]

        model.entities = [storyEntity, mediaEntity]
        return model
    }
}
