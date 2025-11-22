import Foundation
import CoreData

@objc(MediaEntity)
public class MediaEntity: NSManagedObject {
    @nonobjc public class func fetchRequest() -> NSFetchRequest<MediaEntity> {
        NSFetchRequest<MediaEntity>(entityName: "MediaEntity")
    }
}

extension MediaEntity {
    @NSManaged public var id: UUID
    @NSManaged public var type: String // image/video
    @NSManaged public var fileName: String
    @NSManaged public var thumbnailFileName: String?
    @NSManaged public var createdAt: Date
    @NSManaged public var width: NSNumber?
    @NSManaged public var height: NSNumber?
    @NSManaged public var duration: NSNumber?
    @NSManaged public var story: StoryEntity?
}

extension MediaEntity: Identifiable {}
