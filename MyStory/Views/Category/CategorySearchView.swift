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
                
                // 搜索结果
                if viewModel.isSearching && !viewModel.searchText.isEmpty {
                    CategorySearchResultView(
                        results: viewModel.searchResults,
                        onSelectCategory: { category in
                            // 关闭搜索界面
                            dismiss()
                            // 清空搜索
                            viewModel.clearSearch()
                            // 通知父视图进行导航
                            onSelectCategory(category)
                        }
                    )
                } else if !viewModel.searchText.isEmpty && viewModel.searchResults.isEmpty {
                    // 无结果提示
                    noResultsView
                } else {
                    // 空状态提示
                    emptyStateView
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
                // 自动聚焦搜索框
                isSearchFieldFocused = true
            }
        }
    }
    
    // MARK: - Subviews
    
    private var searchBar: some View {
        HStack {
            Image(systemName: "magnifyingglass")
                .foregroundColor(.secondary)
            
            TextField("search.placeholder".localized, text: $viewModel.searchText)
                .focused($isSearchFieldFocused)
                .textFieldStyle(.plain)
                .onChange(of: viewModel.searchText) { _ in
                    viewModel.performSearch()
                }
            
            if !viewModel.searchText.isEmpty {
                Button(action: {
                    viewModel.searchText = ""
                }) {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundColor(.secondary)
                }
            }
        }
        .padding(12)
        .background(Color(.systemGray6))
        .cornerRadius(10)
        .padding(.horizontal)
        .padding(.vertical, 8)
    }
    
    private var emptyStateView: some View {
        VStack(spacing: 16) {
            Image(systemName: "magnifyingglass")
                .font(.system(size: 60))
                .foregroundColor(.secondary)
            
            Text("search.emptyState.title".localized)
                .font(.headline)
                .foregroundColor(.secondary)
            
            Text("search.emptyState.message".localized)
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 32)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
    
    private var noResultsView: some View {
        VStack(spacing: 16) {
            Image(systemName: "doc.text.magnifyingglass")
                .font(.system(size: 60))
                .foregroundColor(.secondary)
            
            Text("search.noResults.title".localized)
                .font(.headline)
                .foregroundColor(.secondary)
            
            Text(String(format: "search.noResults.message".localized, viewModel.searchText))
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 32)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}
