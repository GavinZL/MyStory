import Foundation
import Combine

public final class AIPolishViewModel: ObservableObject {
    @Published public var inputText: String = ""
    @Published public private(set) var outputMarkdown: String = ""
    @Published public private(set) var isLoading: Bool = false
    @Published public private(set) var errorMessage: String?

    private let service: AIPolishService
    private var requestTimestamps: [Date] = []
    private let maxPerMinute = 5

    public init(service: AIPolishService) {
        self.service = service
    }

    public func polish() {
        guard !inputText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            errorMessage = "ai.polish.error.empty".localized
            return
        }
        pruneOld()
        guard requestTimestamps.count < maxPerMinute else {
            errorMessage = "ai.polish.error.rateLimited".localized
            return
        }
        requestTimestamps.append(Date())
        isLoading = true
        errorMessage = nil
        service.polish(text: inputText) { [weak self] result in
            DispatchQueue.main.async {
                guard let self = self else { return }
                self.isLoading = false
                switch result {
                case .success(let md): self.outputMarkdown = md
                case .failure(let err): self.errorMessage = err.localizedDescription
                }
            }
        }
    }

    private func pruneOld() {
        let cutoff = Date().addingTimeInterval(-60)
        requestTimestamps = requestTimestamps.filter { $0 > cutoff }
    }
}
