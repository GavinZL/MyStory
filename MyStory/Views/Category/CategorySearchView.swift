import SwiftUI

/// 分类搜索专用视图
public struct CategorySearchView: View {
    @ObservedObject var viewModel: CategoryViewModel
    @Environment(\.dismiss) private var dismiss
    @FocusState private var isSearchFieldFocused: Bool
    
    /// 点击搜索结果的回调
    let onSelectCategory: (CategoryEntity) -> Void
    
    public init(viewModel: CategoryViewModel, onSelectCategory: @escaping (CategoryEntity) -> Void) {
        self.viewModel = viewModel
        self.onSelectCategory = onSelectCategory
    }
    
    public var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // 搜索框
                searchBar
                
                // 内容区域
                if viewModel.searchText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                    // 无搜索文本：显示搜索历史或空状态
                    if viewModel.searchHistory.isEmpty {
                        emptyStateView
                    } else {
                        searchHistoryView
                    }
                } else if !viewModel.searchResults.isEmpty {
                    // 有搜索结果
                    CategorySearchResultView(
                        results: viewModel.searchResults,
                        keywords: viewModel.searchKeywords,
                        hasMoreResults: viewModel.hasMoreResults,
                        totalResultCount: viewModel.totalResultCount,
                        onSelectCategory: { category in
                            viewModel.addSearchHistory(
                                keyword: viewModel.searchText,
                                resultCount: viewModel.totalResultCount
                            )
                            dismiss()
                            viewModel.clearSearch()
                            onSelectCategory(category)
                        },
                        onLoadMore: {
                            viewModel.loadMoreResults()
                        }
                    )
                } else {
                    // 无结果
                    noResultsView
                }
            }
            .navigationTitle("search.title".localized)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("common.cancel".localized) {
                        viewModel.clearSearch()
                        dismiss()
                    }
                }
            }
            .onAppear {
                isSearchFieldFocused = true
            }
        }
    }
    
    // MARK: - Subviews
    
    private var searchBar: some View {
        HStack(spacing: AppTheme.Spacing.s) {
            Image(systemName: "magnifyingglass")
                .foregroundColor(AppTheme.Colors.textSecondary)
            
            TextField("search.placeholder".localized, text: $viewModel.searchText)
                .focused($isSearchFieldFocused)
                .textFieldStyle(.plain)
                .submitLabel(.search)
                .onSubmit {
                    viewModel.performSearch()
                }
            
            if !viewModel.searchText.isEmpty {
                Button(action: {
                    viewModel.searchText = ""
                }) {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundColor(AppTheme.Colors.textSecondary)
                }
            }
        }
        .padding(AppTheme.Spacing.m)
        .background(AppTheme.Colors.surface)
        .cornerRadius(AppTheme.Radius.m)
        .padding(.horizontal, AppTheme.Spacing.l)
        .padding(.vertical, AppTheme.Spacing.s)
    }
    
    private var searchHistoryView: some View {
        List {
            Section {
                ForEach(viewModel.searchHistory) { item in
                    Button {
                        viewModel.searchFromHistory(item.keyword)
                    } label: {
                        HStack(spacing: AppTheme.Spacing.s) {
                            Image(systemName: "clock.arrow.circlepath")
                                .font(AppTheme.Typography.subheadline)
                                .foregroundColor(AppTheme.Colors.textSecondary)
                                .frame(width: 20)
                            
                            Text(item.keyword)
                                .font(AppTheme.Typography.body)
                                .foregroundColor(AppTheme.Colors.textPrimary)
                            
                            Spacer()
                            
                            Text(String(format: "search.resultCount".localized, item.resultCount))
                                .font(AppTheme.Typography.caption)
                                .foregroundColor(AppTheme.Colors.textSecondary)
                        }
                    }
                    .swipeActions(edge: .trailing) {
                        Button(role: .destructive) {
                            viewModel.removeSearchHistoryItem(item)
                        } label: {
                            Label("common.delete".localized, systemImage: "trash")
                        }
                    }
                }
            } header: {
                HStack {
                    Text("search.history.title".localized)
                        .font(AppTheme.Typography.footnote)
                        .foregroundColor(AppTheme.Colors.textSecondary)
                    
                    Spacer()
                    
                    Button("search.history.clear".localized) {
                        viewModel.clearSearchHistory()
                    }
                    .font(AppTheme.Typography.footnote)
                    .foregroundColor(AppTheme.Colors.primary)
                }
            }
        }
        .listStyle(.insetGrouped)
    }
    
    private var emptyStateView: some View {
        VStack(spacing: AppTheme.Spacing.l) {
            Image(systemName: "magnifyingglass")
                .font(.system(size: 60))
                .foregroundColor(AppTheme.Colors.textSecondary)
            
            Text("search.emptyState.title".localized)
                .font(AppTheme.Typography.headline)
                .foregroundColor(AppTheme.Colors.textSecondary)
            
            Text("search.emptyState.message".localized)
                .font(AppTheme.Typography.subheadline)
                .foregroundColor(AppTheme.Colors.textSecondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, AppTheme.Spacing.xxl)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
    
    private var noResultsView: some View {
        VStack(spacing: AppTheme.Spacing.l) {
            Image(systemName: "doc.text.magnifyingglass")
                .font(.system(size: 60))
                .foregroundColor(AppTheme.Colors.textSecondary)
            
            Text("search.noResults.title".localized)
                .font(AppTheme.Typography.headline)
                .foregroundColor(AppTheme.Colors.textSecondary)
            
            Text(String(format: "search.noResults.message".localized, viewModel.searchText))
                .font(AppTheme.Typography.subheadline)
                .foregroundColor(AppTheme.Colors.textSecondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, AppTheme.Spacing.xxl)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}
