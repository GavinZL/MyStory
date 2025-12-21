//
//  RichTextEditorView.swift
//  MyStory
//
//  通用富文本编辑器组件
//  基于 RichTextKit 封装
//

import SwiftUI
import RichTextKit

// MARK: - 富文本编辑器配置

/// 富文本编辑器配置
struct RichTextEditorConfig {
    /// 最小高度
    var minHeight: CGFloat = 160
    
    /// 背景颜色
    var backgroundColor: Color = .clear
    
    /// 文本内边距
    var textInset: CGSize = CGSize(width: AppTheme.Spacing.s, height: AppTheme.Spacing.s)
    
    /// 占位符文本
    var placeholder: String = "在这里输入文本..."
}

// MARK: - 富文本编辑器 ViewModel

/// 富文本编辑器 ViewModel
class RichTextEditorViewModel: ObservableObject {
    /// 富文本内容
    @Published var attributedContent = NSAttributedString()
    
    /// RichTextKit 上下文
    let context = RichTextContext()
    
    /// 当前是否为粗体
    @Published var isBold = false
    
    /// 当前是否为斜体
    @Published var isItalic = false
    
    /// 当前是否为下划线
    @Published var isUnderlined = false
    
    /// 当前字体大小
    @Published var fontSize: CGFloat = UIFont.systemFontSize
    
    /// 当前字体颜色
    @Published var textColor: Color = .black
    
    /// 是否展示字体设置面板
    @Published var showFontSettings: Bool = false
    
    /// UITextView 引用（用于程序化插入文本）
    weak var textView: UITextView?
    
    /// 初始化
    /// - Parameter initialText: 初始文本内容
    init(initialText: String = "") {
        self.attributedContent = NSAttributedString(string: initialText)
    }
    
    /// 获取纯文本内容
    var plainText: String {
        attributedContent.string
    }
    
    /// 内容是否为空
    var isEmpty: Bool {
        plainText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }
    
    /// 设置文本内容
    /// - Parameter text: 文本内容
    func setText(_ text: String) {
        attributedContent = NSAttributedString(string: text)
    }
    
    /// 更新格式状态
    func updateFormatState() {
        // 获取当前选中位置的文本属性
        let selectedRange = context.selectedRange
        guard selectedRange.location < attributedContent.length else {
            isBold = false
            isItalic = false
            return
        }
        
        let effectiveRange = selectedRange.length > 0 ? selectedRange : NSRange(location: max(0, selectedRange.location - 1), length: 1)
        guard effectiveRange.location < attributedContent.length else {
            isBold = false
            isItalic = false
            return
        }
        
        let attributes = attributedContent.attributes(at: effectiveRange.location, effectiveRange: nil)
        
        // 检查字体样式
        if let font = attributes[.font] as? UIFont {
            isBold = font.fontDescriptor.symbolicTraits.contains(.traitBold)
            isItalic = font.fontDescriptor.symbolicTraits.contains(.traitItalic)
            fontSize = font.pointSize
        } else {
            isBold = false
            isItalic = false
            fontSize = UIFont.systemFontSize
        }
        
        // 检查是否为下划线
        isUnderlined = attributes[.underlineStyle] != nil
    }
    
    /// 切换粗体
    func toggleBold() {
        context.toggleStyle(.bold)
        // 延迟更新状态，等待 RichTextKit 应用样式
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            self.updateFormatState()
        }
    }
    
    /// 切换斜体
    func toggleItalic() {
        context.toggleStyle(.italic)
        // 延迟更新状态
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            self.updateFormatState()
        }
    }
    
    /// 切换下划线
    func toggleUnderline() {
        context.toggleStyle(.underlined)
        // 延迟更新状态
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            self.updateFormatState()
        }
    }
    
    /// 缩进（Tab）
    func insertTab() {
        insertText("    ", newlineBefore: false, newlineAfter: false)
    }
    
    /// 应用字体大小和颜色
    func applyFontSettings(size: CGFloat, color: Color) {
        guard let textView = textView else {
            // 没有 textView 时，只更新默认值
            fontSize = size
            textColor = color
            return
        }
        
        let selectedRange = textView.selectedRange
        
        if selectedRange.length > 0 {
            let mutableText = NSMutableAttributedString(attributedString: attributedContent)
            
            // 应用字体大小
            mutableText.enumerateAttribute(.font, in: selectedRange) { value, range, _ in
                let baseFont: UIFont
                if let font = value as? UIFont {
                    baseFont = font
                } else {
                    baseFont = UIFont.systemFont(ofSize: size)
                }
                let newFont = baseFont.withSize(size)
                mutableText.addAttribute(.font, value: newFont, range: range)
            }
            
            // 应用文字颜色
            mutableText.addAttribute(.foregroundColor, value: UIColor(color), range: selectedRange)
            
            attributedContent = NSAttributedString(attributedString: mutableText)
        } else {
            // 修改当前插入点的默认样式
            var attributes = textView.typingAttributes
            
            if let font = attributes[.font] as? UIFont {
                attributes[.font] = font.withSize(size)
            } else {
                attributes[.font] = UIFont.systemFont(ofSize: size)
            }
            
            attributes[.foregroundColor] = UIColor(color)
            textView.typingAttributes = attributes
            
            fontSize = size
            textColor = color
        }
        
        updateFormatState()
    }
    
    /// 插入文本到光标位置
    /// - Parameters:
    ///   - text: 要插入的文本
    ///   - newlineBefore: 是否在前面添加换行
    ///   - newlineAfter: 是否在后面添加换行
    func insertText(_ text: String, newlineBefore: Bool = false, newlineAfter: Bool = false) {
        // ✅ 关键修复：如果有 UITextView 引用，直接通过它插入文本
        if let textView = textView {
            var textToInsert = text
            let selectedRange = textView.selectedRange
            
            // 根据配置添加换行
            // if newlineBefore && selectedRange.location > 0 {
            //     let previousChar = (textView.text as NSString).substring(with: NSRange(location: selectedRange.location - 1, length: 1))
            //     if previousChar != "\n" {
            //         textToInsert = "\n" + textToInsert
            //     }
            // }
            
            // 直接在 UITextView 上插入文本
            textView.insertText(textToInsert)
        }
    }
    
    /// 插入时间戳
    /// - Parameter format: 时间格式，默认为 "yyyy-MM-dd HH:mm"
    func insertTimestamp(format: String = "yyyy-MM-dd HH:mm") {
        let formatter = DateFormatter()
        formatter.dateFormat = format
        let timestamp = "[" + formatter.string(from: Date()) + "]"
        insertText(timestamp, newlineBefore: true, newlineAfter: true)
    }
    
    /// 插入待办事项
    func insertTodoItem() {
        insertText("☐ ", newlineBefore: true, newlineAfter: false)
    }
}

// MARK: - 富文本编辑器视图

/// 通用富文本编辑器视图
struct RichTextEditorView: View {
    /// ViewModel
    @ObservedObject var viewModel: RichTextEditorViewModel
    
    /// 配置
    var config: RichTextEditorConfig
    
    /// 分类按钮点击回调
    var onCategoryTap: (() -> Void)?
    
    init(
        viewModel: RichTextEditorViewModel,
        config: RichTextEditorConfig = RichTextEditorConfig(),
        onCategoryTap: (() -> Void)? = nil
    ) {
        self.viewModel = viewModel
        self.config = config
        self.onCategoryTap = onCategoryTap
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // 富文本编辑器区域（包含占位符）
            ZStack(alignment: .topLeading) {
                // 占位符文本（只在空白内容时显示）
                if !config.placeholder.isEmpty && viewModel.plainText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                    Text(config.placeholder)
                        .foregroundColor(AppTheme.Colors.textSecondary)
                        .padding(.top, config.textInset.height + 2)
                        .padding(.horizontal, config.textInset.width)
                        .allowsHitTesting(false)
                }
                
                // 富文本编辑器
                RichTextEditor(
                    text: $viewModel.attributedContent,
                    context: viewModel.context
                ) { textView in
                    textView.textContentInset = config.textInset
                    // ✅ 保存 UITextView 引用到 ViewModel，用于程序化插入文本
                    DispatchQueue.main.async {
                        viewModel.textView = textView as? UITextView
                    }
                }
            }
            .frame(minHeight: config.minHeight)
            .background(config.backgroundColor)
            .onChange(of: viewModel.context.selectedRange) { _ in
                viewModel.updateFormatState()
            }
            .onChange(of: viewModel.attributedContent) { _ in
                viewModel.updateFormatState()
            }
        }
    }
}
