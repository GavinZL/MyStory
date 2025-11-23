import Foundation

public enum MarkdownProcessor {
    // 设计文档中的规则可在此扩展，目前直接返回内容以便由系统 Markdown 渲染
    public static func convert(_ text: String) -> String {
        text
    }
}
