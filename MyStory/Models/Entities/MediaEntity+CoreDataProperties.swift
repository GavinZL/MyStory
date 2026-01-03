//
//  MediaEntity+CoreDataProperties.swift
//  MyStory
//
//  Created by BIGO on 2026/1/3.
//
//

public import Foundation
public import CoreData


public typealias MediaEntityCoreDataPropertiesSet = NSSet

extension MediaEntity {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<MediaEntity> {
        return NSFetchRequest<MediaEntity>(entityName: "MediaEntity")
    }

    @NSManaged public var createdAt: Date?
    @NSManaged public var duration: Double
    @NSManaged public var encryptionKeyId: String?
    @NSManaged public var fileName: String?
    @NSManaged public var fileSize: Int64
    @NSManaged public var height: Int32
    @NSManaged public var id: UUID?
    @NSManaged public var originalFileName: String?
    @NSManaged public var thumbnailFileName: String?
    @NSManaged public var type: String?
    @NSManaged public var width: Int32
    @NSManaged public var story: StoryEntity?

}
