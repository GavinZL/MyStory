//
//  SearchHistoryItem.swift
//  MyStory
//
//  搜索历史记录模型
//

import Foundation

struct SearchHistoryItem: Codable, Identifiable {
    let id = UUID()
    let keyword: String
    let timestamp: Date
    let resultCount: Int
    
    enum CodingKeys: String, CodingKey {
        case keyword, timestamp, resultCount
    }
}
