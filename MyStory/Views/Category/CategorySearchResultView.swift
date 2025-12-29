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
    let onSelectCategory: (CategoryEntity) -> Void
    
    var body: some View {
        if results.isEmpty {
            emptyView
        } else {
            List {
                ForEach(results) { result in
                    CategorySearchResultItem(
                        result: result,
                        onSelect: { onSelectCategory(result.category) }
                    )
                }
            }
            .listStyle(.insetGrouped)
        }
    }
    
    private var emptyView: some View {
        VStack(spacing: AppTheme.Spacing.m) {
            Image(systemName: "magnifyingglass")
                .font(.system(size: 60))
                .foregroundColor(.secondary)
            
            Text("search.noResults".localized)
                .font(AppTheme.Typography.body)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(UIColor.systemGroupedBackground))
    }
}

// MARK: - Category Search Result Item

/// 搜索结果单项
private struct CategorySearchResultItem: View {
    let result: CategorySearchResult
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
                    
                    Text(result.categoryPath)
                        .font(AppTheme.Typography.headline)
                        .foregroundColor(AppTheme.Colors.textPrimary)
                }
                
                // 匹配的故事列表
                if !result.matchedStories.isEmpty {
                    VStack(alignment: .leading, spacing: AppTheme.Spacing.xs) {
                        ForEach(result.matchedStories.prefix(3)) { match in
                            StoryMatchRow(match: match)
                        }
                        
                        if result.matchedStories.count > 3 {
                            Text(String(format: "search.moreStories".localized, result.matchedStories.count - 3))
                                .font(AppTheme.Typography.footnote)
                                .foregroundColor(.secondary)
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
    
    var body: some View {
        HStack(alignment: .top, spacing: AppTheme.Spacing.s) {
            // 匹配类型图标
            Image(systemName: match.matchType == .title ? "doc.text" : "text.alignleft")
                .font(.caption)
                .foregroundColor(.secondary)
                .frame(width: 16)
            
            VStack(alignment: .leading, spacing: 2) {
                // 故事标题或匹配片段
                Text(match.matchSnippet)
                    .font(AppTheme.Typography.body)
                    .foregroundColor(AppTheme.Colors.textPrimary)
                    .lineLimit(2)
                
                // 匹配类型标签
                Text(match.matchType == .title ? "search.matchInTitle".localized : "search.matchInContent".localized)
                    .font(AppTheme.Typography.caption)
                    .foregroundColor(.secondary)
            }
        }
        .padding(.leading, AppTheme.Spacing.s)
    }
}
