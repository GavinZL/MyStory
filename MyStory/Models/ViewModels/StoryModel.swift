//
//  StoryModel.swift
//  MyStory
//
//  故事业务模型 - 用于UI展示
//

import Foundation

struct StoryModel: Identifiable {
    let id: UUID
    let title: String
    let contentPreview: String
    let displayTime: String
    let locationDisplay: String?
    let thumbnails: [URL]
    let categoryTags: [CategoryTag]
    let mediaCount: Int
    let hasVideo: Bool
    let hasLocation: Bool
}

struct CategoryTag: Identifiable {
    let id: UUID
    let name: String
    let colorHex: String
    let iconName: String
}
