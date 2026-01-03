//
//  CategoryEntity+CoreDataProperties.swift
//  MyStory
//
//  Created by BIGO on 2026/1/3.
//
//

public import Foundation
public import CoreData


public typealias CategoryEntityCoreDataPropertiesSet = NSSet

extension CategoryEntity {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<CategoryEntity> {
        return NSFetchRequest<CategoryEntity>(entityName: "CategoryEntity")
    }

    @NSManaged public var colorHex: String?
    @NSManaged public var createdAt: Date?
    @NSManaged public var customIconData: Data?
    @NSManaged public var iconName: String?
    @NSManaged public var iconType: String?
    @NSManaged public var id: UUID?
    @NSManaged public var level: Int16
    @NSManaged public var name: String?
    @NSManaged public var nameEn: String?
    @NSManaged public var sortOrder: Int32
    @NSManaged public var children: NSSet?
    @NSManaged public var parent: CategoryEntity?
    @NSManaged public var stories: NSSet?

}

// MARK: Generated accessors for children
extension CategoryEntity {

    @objc(addChildrenObject:)
    @NSManaged public func addToChildren(_ value: CategoryEntity)

    @objc(removeChildrenObject:)
    @NSManaged public func removeFromChildren(_ value: CategoryEntity)

    @objc(addChildren:)
    @NSManaged public func addToChildren(_ values: NSSet)

    @objc(removeChildren:)
    @NSManaged public func removeFromChildren(_ values: NSSet)

}

// MARK: Generated accessors for stories
extension CategoryEntity {

    @objc(addStoriesObject:)
    @NSManaged public func addToStories(_ value: StoryEntity)

    @objc(removeStoriesObject:)
    @NSManaged public func removeFromStories(_ value: StoryEntity)

    @objc(addStories:)
    @NSManaged public func addToStories(_ values: NSSet)

    @objc(removeStories:)
    @NSManaged public func removeFromStories(_ values: NSSet)

}

extension CategoryEntity : Identifiable {

}
