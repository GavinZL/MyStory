//
//  CategoryListView.swift
//  MyStory
//
//  分类列表页面
//

import SwiftUI

struct CategoryListView: View {
    @EnvironmentObject var router: AppRouter
    @Environment(\.managedObjectContext) private var viewContext
    
    @State private var isSearching = false
    @State private var searchText = ""
    
    var body: some View {
        NavigationStack {
            VStack {
                // 搜索栏
                if isSearching {
                    SearchBar(text: $searchText, isSearching: $isSearching)
                }
                
                // 分类内容（占位）
                Text("分类页面")
                    .font(.appTitle)
                    .foregroundColor(.appSecondaryText)
                
                Spacer()
            }
            .navigationTitle("分类")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: {
                        isSearching.toggle()
                    }) {
                        Image(systemName: "magnifyingglass")
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: {
                        // 创建新分类
                    }) {
                        Image(systemName: "plus")
                    }
                }
            }
        }
    }
}

#Preview {
    CategoryListView()
        .environmentObject(AppRouter())
        .environment(\.managedObjectContext, PersistenceController.preview.container.viewContext)
}
