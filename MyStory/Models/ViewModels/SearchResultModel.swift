//
//  SearchResultModel.swift
//  MyStory
//
//  分类搜索结果数据模型
//

import Foundation
import CoreData

// MARK: - Story Match

/// 故事匹配结果
public struct StoryMatch: Identifiable {
    public let id: UUID
    public let story: StoryEntity
    public let matchType: MatchType
    public let matchSnippet: String  // 匹配的文本片段
    public let matchScore: Int       // 匹配分数
    
    public enum MatchType {
        case title          // 标题匹配
        case content        // 内容匹配
        case location       // 位置匹配
    }
    
    public init(
        story: StoryEntity,
        matchType: MatchType,
        matchSnippet: String,
        matchScore: Int
    ) {
        self.id = story.id ?? UUID()
        self.story = story
        self.matchType = matchType
        self.matchSnippet = matchSnippet
        self.matchScore = matchScore
    }
}

// MARK: - Category Search Result

/// 分类搜索结果
public struct CategorySearchResult: Identifiable {
    public let id: UUID
    public let category: CategoryEntity
    public let categoryPath: String              // 分类路径（如："生活 > 旅行 > 日本之旅"）
    public let matchedStories: [StoryMatch]      // 匹配的故事列表
    public let categoryNameMatched: Bool         // 分类名称是否匹配
    public let totalScore: Int                   // 总匹配分数（用于排序）
    
    public init(
        category: CategoryEntity,
        categoryPath: String,
        matchedStories: [StoryMatch],
        categoryNameMatched: Bool = false
    ) {
        self.id = category.id ?? UUID()
        self.category = category
        self.categoryPath = categoryPath
        self.matchedStories = matchedStories
        self.categoryNameMatched = categoryNameMatched
        self.totalScore = matchedStories.reduce(0) { $0 + $1.matchScore } + (categoryNameMatched ? 80 : 0)
    }
}
