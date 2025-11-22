//
//  SettingEntity+CoreDataProperties.swift
//  MyStory
//
//  Setting实体属性
//

import Foundation
import CoreData

extension SettingEntity {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<SettingEntity> {
        return NSFetchRequest<SettingEntity>(entityName: "SettingEntity")
    }

    @NSManaged public var key: String?
    @NSManaged public var value: String?
    @NSManaged public var type: String?
    @NSManaged public var updatedAt: Date?

}
