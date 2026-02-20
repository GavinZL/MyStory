//
//  CategorySearchResultView.swift
//  MyStory
//
//  分类搜索结果视图
//

import SwiftUI

// MARK: - Category Search Result View

/// 分类搜索结果列表视图
struct CategorySearchResultView: View {
    let results: [CategorySearchResult]
    let keywords: [String]
    let hasMoreResults: Bool
    let totalResultCount: Int
    let onSelectCategory: (CategoryEntity) -> Void
    let onLoadMore: () -> Void
    
    var body: some View {
        List {
            // 结果计数
            Section {
                Text(String(format: "search.resultCount".localized, totalResultCount))
                    .font(AppTheme.Typography.footnote)
                    .foregroundColor(AppTheme.Colors.textSecondary)
                    .listRowBackground(Color.clear)
                    .listRowInsets(EdgeInsets(top: 0, leading: AppTheme.Spacing.l, bottom: 0, trailing: AppTheme.Spacing.l))
            }
            
            // 搜索结果
            Section {
                ForEach(results) { result in
                    CategorySearchResultItem(
                        result: result,
                        keywords: keywords,
                        onSelect: { onSelectCategory(result.category) }
                    )
                }
                
                // 加载更多
                if hasMoreResults {
                    Button(action: onLoadMore) {
                        HStack {
                            Spacer()
                            Text("search.loadMore".localized)
                                .font(AppTheme.Typography.subheadline)
                                .foregroundColor(AppTheme.Colors.primary)
                            Spacer()
                        }
                        .padding(.vertical, AppTheme.Spacing.s)
                    }
                    .buttonStyle(PlainButtonStyle())
                }
            }
        }
        .listStyle(.insetGrouped)
    }
}

// MARK: - Category Search Result Item

/// 搜索结果单项
private struct CategorySearchResultItem: View {
    let result: CategorySearchResult
    let keywords: [String]
    let onSelect: () -> Void
    
    var body: some View {
        Button(action: onSelect) {
            VStack(alignment: .leading, spacing: AppTheme.Spacing.s) {
                // 分类路径
                HStack(spacing: AppTheme.Spacing.xs) {
                    CategoryIconView(
                        entity: result.category,
                        size: 20,
                        color: Color(hex: result.category.colorHex ?? "#007AFF")
                    )
                    
                    if result.categoryNameMatched {
                        SearchHighlighter.highlightedText(result.categoryPath, keywords: keywords)
                            .font(AppTheme.Typography.headline)
                            .foregroundColor(AppTheme.Colors.textPrimary)
                    } else {
                        Text(result.categoryPath)
                            .font(AppTheme.Typography.headline)
                            .foregroundColor(AppTheme.Colors.textPrimary)
                    }
                }
                
                // 分类名称匹配标签
                if result.categoryNameMatched && result.matchedStories.isEmpty {
                    Text("search.matchInCategory".localized)
                        .font(AppTheme.Typography.caption)
                        .foregroundColor(AppTheme.Colors.textSecondary)
                        .padding(.leading, AppTheme.Spacing.l)
                }
                
                // 匹配的故事列表
                if !result.matchedStories.isEmpty {
                    VStack(alignment: .leading, spacing: AppTheme.Spacing.xs) {
                        ForEach(result.matchedStories.prefix(3)) { match in
                            StoryMatchRow(match: match, keywords: keywords)
                        }
                        
                        if result.matchedStories.count > 3 {
                            Text(String(format: "search.moreStories".localized, result.matchedStories.count - 3))
                                .font(AppTheme.Typography.footnote)
                                .foregroundColor(AppTheme.Colors.textSecondary)
                                .padding(.leading, AppTheme.Spacing.l)
                        }
                    }
                    .padding(.top, AppTheme.Spacing.xs)
                }
            }
            .padding(.vertical, AppTheme.Spacing.xs)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// MARK: - Story Match Row

/// 故事匹配行
private struct StoryMatchRow: View {
    let match: StoryMatch
    let keywords: [String]
    
    var body: some View {
        HStack(alignment: .top, spacing: AppTheme.Spacing.s) {
            // 匹配类型图标
            Image(systemName: matchIcon)
                .font(.caption)
                .foregroundColor(AppTheme.Colors.textSecondary)
                .frame(width: 16)
            
            VStack(alignment: .leading, spacing: 2) {
                // 高亮显示匹配文本
                SearchHighlighter.highlightedText(match.matchSnippet, keywords: keywords)
                    .font(AppTheme.Typography.body)
                    .foregroundColor(AppTheme.Colors.textPrimary)
                    .lineLimit(2)
                
                // 匹配类型标签
                Text(matchLabel)
                    .font(AppTheme.Typography.caption)
                    .foregroundColor(AppTheme.Colors.textSecondary)
            }
        }
        .padding(.leading, AppTheme.Spacing.s)
    }
    
    private var matchIcon: String {
        switch match.matchType {
        case .title: return "doc.text"
        case .content: return "text.alignleft"
        case .location: return "mappin.and.ellipse"
        }
    }
    
    private var matchLabel: String {
        switch match.matchType {
        case .title: return "search.matchInTitle".localized
        case .content: return "search.matchInContent".localized
        case .location: return "search.matchInLocation".localized
        }
    }
}

// MARK: - Search Highlighter

/// 搜索关键词高亮工具
@MainActor
enum SearchHighlighter {
    
    /// 生成带关键词高亮的 Text
    static func highlightedText(_ text: String, keywords: [String], highlightColor: Color? = nil) -> Text {
        guard !keywords.isEmpty, !text.isEmpty else { return Text(text) }
        let color = highlightColor ?? AppTheme.Colors.primary
        
        // 找到所有关键词的匹配范围
        let lowerText = text.lowercased()
        var ranges: [Range<String.Index>] = []
        
        for keyword in keywords {
            guard !keyword.isEmpty else { continue }
            let lowerKeyword = keyword.lowercased()
            var searchStart = lowerText.startIndex
            
            while searchStart < lowerText.endIndex,
                  let range = lowerText.range(of: lowerKeyword, range: searchStart..<lowerText.endIndex) {
                ranges.append(range)
                searchStart = range.upperBound
            }
        }
        
        guard !ranges.isEmpty else { return Text(text) }
        
        // 按位置排序
        ranges.sort { $0.lowerBound < $1.lowerBound }
        
        // 合并重叠的范围
        var merged: [Range<String.Index>] = []
        for range in ranges {
            if let last = merged.last, range.lowerBound <= last.upperBound {
                let newEnd = max(last.upperBound, range.upperBound)
                merged[merged.count - 1] = last.lowerBound..<newEnd
            } else {
                merged.append(range)
            }
        }
        
        // 构建高亮 Text
        var result = Text("")
        var currentIndex = text.startIndex
        
        for range in merged {
            // 匹配前的普通文本
            if currentIndex < range.lowerBound {
                result = result + Text(text[currentIndex..<range.lowerBound])
            }
            // 高亮文本
            result = result + Text(text[range])
                .foregroundColor(color)
                .bold()
            currentIndex = range.upperBound
        }
        
        // 剩余文本
        if currentIndex < text.endIndex {
            result = result + Text(text[currentIndex...])
        }
        
        return result
    }
}
