//
//  StoryEntity+CoreDataProperties.swift
//  MyStory
//
//  Story实体属性
//

import Foundation
import CoreData

extension StoryEntity {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<StoryEntity> {
        return NSFetchRequest<StoryEntity>(entityName: "StoryEntity")
    }

    @NSManaged public var id: UUID?
    @NSManaged public var title: String?
    @NSManaged public var content: String?
    @NSManaged public var plainTextContent: String?
    @NSManaged public var timestamp: Date
    @NSManaged public var createdAt: Date
    @NSManaged public var updatedAt: Date
    @NSManaged public var locationName: String?
    @NSManaged public var locationAddress: String?
    @NSManaged public var locationCity: String?
    @NSManaged public var latitude: Double
    @NSManaged public var longitude: Double
    @NSManaged public var mood: String?
    @NSManaged public var syncStatus: Int16
    @NSManaged public override var isDeleted: Bool
    @NSManaged public var categories: NSSet?
    @NSManaged public var media: NSSet?

}

// MARK: Generated accessors for categories
extension StoryEntity {

    @objc(addCategoriesObject:)
    @NSManaged public func addToCategories(_ value: CategoryEntity)

    @objc(removeCategoriesObject:)
    @NSManaged public func removeFromCategories(_ value: CategoryEntity)

    @objc(addCategories:)
    @NSManaged public func addToCategories(_ values: NSSet)

    @objc(removeCategories:)
    @NSManaged public func removeFromCategories(_ values: NSSet)

}

// MARK: Generated accessors for media
extension StoryEntity {

    @objc(addMediaObject:)
    @NSManaged public func addToMedia(_ value: MediaEntity)

    @objc(removeMediaObject:)
    @NSManaged public func removeFromMedia(_ value: MediaEntity)

    @objc(addMedia:)
    @NSManaged public func addToMedia(_ values: NSSet)

    @objc(removeMedia:)
    @NSManaged public func removeFromMedia(_ values: NSSet)

}

