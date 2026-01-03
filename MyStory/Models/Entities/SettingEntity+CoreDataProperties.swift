//
//  SettingEntity+CoreDataProperties.swift
//  MyStory
//
//  Created by BIGO on 2026/1/3.
//
//

public import Foundation
public import CoreData


public typealias SettingEntityCoreDataPropertiesSet = NSSet

extension SettingEntity {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<SettingEntity> {
        return NSFetchRequest<SettingEntity>(entityName: "SettingEntity")
    }

    @NSManaged public var key: String?
    @NSManaged public var type: String?
    @NSManaged public var updatedAt: Date?
    @NSManaged public var value: String?

}

extension SettingEntity : Identifiable {

}
