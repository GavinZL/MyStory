import Foundation

public protocol KeychainProviding {
    func getAPIKey() -> String?
    func setAPIKey(_ key: String) -> Bool
}

public final class AIPolishService {
    private let keychain: KeychainProviding
    private let endpoint = URL(string: "https://dashscope.aliyuncs.com/api/v1/services/aigc/text-generation/generation")!

    public init(keychain: KeychainProviding) {
        self.keychain = keychain
    }

    public struct RequestBody: Encodable {
        public struct Message: Encodable { let role: String; let content: String }
        public struct Parameters: Encodable {
            let result_format: String
            let incremental_output: Bool
            let max_tokens: Int
            let temperature: Double
        }
        let model: String
        let input: Input
        let parameters: Parameters
        public struct Input: Encodable { let messages: [Message] }
    }

    public func polish(text: String, completion: @escaping (Result<String, Error>) -> Void) {
        guard let apiKey = keychain.getAPIKey(), !apiKey.isEmpty else {
            completion(.failure(NSError(domain: "AIPolishService", code: 401, userInfo: [NSLocalizedDescriptionKey: "未配置通义千问 API Key"])));
            return
        }
        let body = RequestBody(
            model: "qwen-plus",
            input: .init(messages: [.init(role: "user", content: text)]),
            parameters: .init(result_format: "message", incremental_output: true, max_tokens: 2000, temperature: 0.7)
        )
        var req = URLRequest(url: endpoint)
        req.httpMethod = "POST"
        req.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        req.setValue("application/json", forHTTPHeaderField: "Content-Type")
        req.timeoutInterval = 30
        do { req.httpBody = try JSONEncoder().encode(body) } catch {
            completion(.failure(error)); return
        }

        URLSession.shared.dataTask(with: req) { data, _, err in
            if let err = err { completion(.failure(err)); return }
            guard let data = data else {
                completion(.failure(NSError(domain: "AIPolishService", code: -1, userInfo: [NSLocalizedDescriptionKey: "空响应"])))
                return
            }
            // 尝试解析常见结构，失败则回退为原文
            let polished = (try? Self.parseOutputText(from: data)) ?? text
            let markdown = MarkdownProcessor.convert(polished)
            let finalText = SensitiveFilter.filter(markdown)
            completion(.success(finalText))
        }.resume()
    }

    private static func parseOutputText(from data: Data) throws -> String {
        // 兼容若干返回结构：{"output":{"text":"..."}} 或 message/choices
        struct Output1: Decodable { struct Inner: Decodable { let text: String? }; let output: Inner? }
        if let o1 = try? JSONDecoder().decode(Output1.self, from: data), let t = o1.output?.text { return t }
        // 通用字典兜底
        let json = try JSONSerialization.jsonObject(with: data) as? [String: Any]
        if let output = json?["output"] as? [String: Any], let text = output["text"] as? String { return text }
        if let choices = json?["choices"] as? [[String: Any]], let first = choices.first,
           let msg = first["message"] as? [String: Any], let content = msg["content"] as? String {
            return content
        }
        throw NSError(domain: "AIPolishService", code: -2, userInfo: [NSLocalizedDescriptionKey: "解析失败"])
    }
}
