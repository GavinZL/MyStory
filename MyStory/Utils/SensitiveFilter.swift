import Foundation

public enum SensitiveFilter {
    private static let words: [String] = [
        // 示例敏感词，可根据需要扩展或改为读取本地 JSON 词库
        "测试敏感词",
        "违禁词"
    ]

    public static func filter(_ text: String) -> String {
        var result = text
        for w in words where !w.isEmpty {
            result = result.replacingOccurrences(of: w, with: "***")
        }
        return result
    }
}
