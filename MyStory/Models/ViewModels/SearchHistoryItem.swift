//
//  SearchHistoryItem.swift
//  MyStory
//
//  搜索历史记录模型
//

import Foundation

public struct SearchHistoryItem: Codable, Identifiable {
    public let id = UUID()
    public let keyword: String
    public let timestamp: Date
    public let resultCount: Int
    
    enum CodingKeys: String, CodingKey {
        case keyword, timestamp, resultCount
    }
    
    public init(keyword: String, timestamp: Date, resultCount: Int) {
        self.keyword = keyword
        self.timestamp = timestamp
        self.resultCount = resultCount
    }
}
