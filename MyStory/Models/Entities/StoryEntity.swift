import Foundation
import CoreData

@objc(StoryEntity)
public class StoryEntity: NSManagedObject {
    @nonobjc public class func fetchRequest() -> NSFetchRequest<StoryEntity> {
        NSFetchRequest<StoryEntity>(entityName: "StoryEntity")
    }
}

extension StoryEntity {
    @NSManaged public var id: UUID
    @NSManaged public var title: String
    @NSManaged public var content: String?
    @NSManaged public var timestamp: Date
    @NSManaged public var createdAt: Date
    @NSManaged public var updatedAt: Date
    @NSManaged public var locationName: String?
    @NSManaged public var locationCity: String?
    @NSManaged public var latitude: NSNumber?
    @NSManaged public var longitude: NSNumber?
    @NSManaged public var medias: Set<MediaEntity>?
}

extension StoryEntity: Identifiable {}
