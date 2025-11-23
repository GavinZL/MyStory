import SwiftUI

public struct CategoryView: View {
    @ObservedObject private var viewModel: CategoryViewModel

    public init(viewModel: CategoryViewModel) {
        self.viewModel = viewModel
    }

    public var body: some View {
        VStack(spacing: 12) {
            Picker("显示模式", selection: $viewModel.displayMode) {
                ForEach(CategoryDisplayMode.allCases) { mode in
                    Text(mode.title).tag(mode)
                }
            }
            .pickerStyle(.segmented)
            .padding(.horizontal)

            switch viewModel.displayMode {
            case .card:
                cardGrid
            case .list:
                listTree
            }
        }
        .navigationTitle("分类")
    }

    private var cardGrid: some View {
        ScrollView {
            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                ForEach(flatten(tree: viewModel.tree), id: \.id) { node in
                    CategoryCardView(node: node)
                }
            }
            .padding(.horizontal)
        }
    }

    private var listTree: some View {
        List {
            ForEach(viewModel.tree) { node in
                Section(header: row(node)) {
                    ForEach(node.children) { child in
                        row(child)
                        ForEach(child.children) { grand in
                            row(grand).padding(.leading, 24)
                        }
                    }
                }
            }
        }
        .listStyle(.insetGrouped)
    }

    private func row(_ node: CategoryTreeNode) -> some View {
        HStack {
            Image(systemName: node.category.iconName)
                .frame(width: 24)
            Text(node.category.name)
            Spacer()
            Text("共 \(node.storyCount) 个故事")
                .foregroundColor(.secondary)
                .font(.footnote)
        }
    }

    private func flatten(tree: [CategoryTreeNode]) -> [CategoryTreeNode] {
        var result: [CategoryTreeNode] = []
        func walk(_ node: CategoryTreeNode) {
            result.append(node)
            node.children.forEach(walk)
        }
        tree.forEach(walk)
        return result
    }
}
