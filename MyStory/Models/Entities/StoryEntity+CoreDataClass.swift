//
//  StoryEntity+CoreDataClass.swift
//  MyStory
//
//  Story实体扩展
//

import Foundation
import CoreData

@objc(StoryEntity)
public class StoryEntity: NSManagedObject, Identifiable {
    
    /// 转换为业务模型
    func toModel() -> StoryModel {
        StoryModel(
            id: id ?? UUID(),
            title: title ?? "",
            contentPreview: String((plainTextContent ?? "").prefix(100)),
            displayTime: formatDisplayTime(timestamp!),
            locationDisplay: locationName ?? locationCity,
            thumbnails: [], // 需要从media关系加载
            categoryTags: [], // 需要从categories关系加载
            mediaCount: media?.count ?? 0,
            hasVideo: media?.contains(where: { ($0 as? MediaEntity)?.type == "video" }) ?? false,
            hasLocation: locationName != nil || locationCity != nil
        )
    }
    
    /// 格式化显示时间
    private func formatDisplayTime(_ date: Date) -> String {
        let calendar = Calendar.current
        let now = Date()
        
        if calendar.isDateInToday(date) {
            let formatter = DateFormatter()
            formatter.timeStyle = .short
            return "今天 " + formatter.string(from: date)
        } else if calendar.isDateInYesterday(date) {
            return "昨天"
        } else if calendar.dateComponents([.day], from: date, to: now).day! < 7 {
            let days = calendar.dateComponents([.day], from: date, to: now).day!
            return "\(days)天前"
        } else {
            let formatter = DateFormatter()
            formatter.dateFormat = "yyyy年MM月dd日"
            return formatter.string(from: date)
        }
    }
}
