import SwiftUI

public struct AIPolishView: View {
    @ObservedObject private var viewModel: AIPolishViewModel

    public init(viewModel: AIPolishViewModel) {
        self.viewModel = viewModel
    }

    public var body: some View {
        VStack(alignment: .leading, spacing: AppTheme.Spacing.l) {
            Text("ai.polish.title".localized)
                .font(AppTheme.Typography.title2)
                .foregroundColor(AppTheme.Colors.textPrimary)
                .padding(.horizontal, AppTheme.Spacing.l)

            TextEditor(text: $viewModel.inputText)
                .frame(minHeight: 160)
                .padding(AppTheme.Spacing.s)
                .background(AppTheme.Colors.surface)
                .overlay(
                    RoundedRectangle(cornerRadius: AppTheme.Radius.s)
                        .stroke(AppTheme.Surface.cardBorder, lineWidth: 1)
                )
                .padding(.horizontal, AppTheme.Spacing.l)

            HStack {
                Spacer()
                Button(action: { viewModel.polish() }) {
                    if viewModel.isLoading {
                        ProgressView()
                    } else {
                        Text("ai.polish.start".localized)
                    }
                }
                .buttonStyle(.borderedProminent)
                Spacer()
            }
            .padding(.horizontal, AppTheme.Spacing.l)

            if let err = viewModel.errorMessage {
                Text(err)
                    .font(AppTheme.Typography.callout)
                    .foregroundColor(AppTheme.Colors.error)
                    .padding(.horizontal, AppTheme.Spacing.l)
            }

            if !viewModel.outputMarkdown.isEmpty {
                Divider()
                ScrollView {
                    let attr = (try? AttributedString(markdown: viewModel.outputMarkdown))
                    if let attr = attr {
                        Text(attr)
                            .padding(.horizontal, AppTheme.Spacing.l)
                    } else {
                        Text(viewModel.outputMarkdown)
                            .padding(.horizontal, AppTheme.Spacing.l)
                    }
                }
            }

            Spacer()
        }
        .background(AppTheme.Colors.background)
    }
}
