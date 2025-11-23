import SwiftUI

public struct AIPolishView: View {
    @ObservedObject private var viewModel: AIPolishViewModel

    public init(viewModel: AIPolishViewModel) {
        self.viewModel = viewModel
    }

    public var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("AI 文本润色")
                .font(.title2)
                .bold()
                .padding(.horizontal)

            TextEditor(text: $viewModel.inputText)
                .frame(minHeight: 160)
                .padding(8)
                .overlay(RoundedRectangle(cornerRadius: 8).stroke(Color.gray.opacity(0.2)))
                .padding(.horizontal)

            HStack {
                Spacer()
                Button(action: { viewModel.polish() }) {
                    if viewModel.isLoading { ProgressView() } else { Text("开始润色") }
                }
                .buttonStyle(.borderedProminent)
                Spacer()
            }
            .padding(.horizontal)

            if let err = viewModel.errorMessage { Text(err).foregroundColor(.red).padding(.horizontal) }

            if !viewModel.outputMarkdown.isEmpty {
                Divider()
                ScrollView {
                    let attr = (try? AttributedString(markdown: viewModel.outputMarkdown))
                    if let attr = attr { Text(attr).padding(.horizontal) } else { Text(viewModel.outputMarkdown).padding(.horizontal) }
                }
            }

            Spacer()
        }
    }
}
