//
//  MediaEntity+CoreDataProperties.swift
//  MyStory
//
//  Media实体属性
//

import Foundation
import CoreData

extension MediaEntity {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<MediaEntity> {
        return NSFetchRequest<MediaEntity>(entityName: "MediaEntity")
    }

    @NSManaged public var id: UUID?
    @NSManaged public var type: String?
    @NSManaged public var fileName: String?
    @NSManaged public var originalFileName: String?
    @NSManaged public var fileSize: Int64
    @NSManaged public var width: Int32
    @NSManaged public var height: Int32
    @NSManaged public var duration: Double
    @NSManaged public var thumbnailFileName: String?
    @NSManaged public var encryptionKeyId: String?
    @NSManaged public var createdAt: Date?
    @NSManaged public var story: StoryEntity?

}
