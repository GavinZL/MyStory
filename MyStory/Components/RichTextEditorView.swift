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
    weak var textView: UITextView? {
        didSet {
            // 当 textView 设置完成后，如果有待设置的初始文本，立即设置
            if let pending = pendingInitialText, !pending.isEmpty, !hasSetInitialText {
                // ✅ 确保在主线程更新
                DispatchQueue.main.async { [weak self] in
                    guard let self = self, let textView = self.textView else { return }
                    
                    // ✅ 直接设置 UITextView 的 attributedText
                    let attributedString = self.createAttributedString(from: pending)
                    textView.attributedText = attributedString
                    
                    // 同步更新 ViewModel 的状态
                    self.attributedContent = attributedString
                    self.hasSetInitialText = true
                    self.pendingInitialText = nil
                }
            }
        }
    }
    
    /// 待设置的初始文本（在 textView 准备好之前暂存）
    private var pendingInitialText: String?
    
    /// 标记是否已设置过初始文本
    private var hasSetInitialText = false
    
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
    
    /// 创建带默认字体的富文本
    /// - Parameter text: 纯文本内容
    /// - Returns: 带默认字体属性的富文本
    private func createAttributedString(from text: String) -> NSAttributedString {
        let font = UIFont.preferredFont(forTextStyle: .headline)
        let attributes: [NSAttributedString.Key: Any] = [
            .font: font
        ]
        return NSAttributedString(string: text, attributes: attributes)
    }
    
    /// 设置文本内容
    /// - Parameter text: 文本内容
    func setText(_ text: String) {
        // ✅ 同步执行，避免时序问题
        if textView != nil && !hasSetInitialText {
            // textView 已准备好，直接设置
            DispatchQueue.main.async { [weak self] in
                guard let self = self else { return }
                self.attributedContent = self.createAttributedString(from: text)
                self.hasSetInitialText = true
            }
        } else if textView == nil {
            // textView 还未准备好，暂存文本
            self.pendingInitialText = text
        }
    }
    
    /// 更新格式状态
    func updateFormatState() {
        // 从 textView 的 typingAttributes 读取格式状态（支持空文本场景）
        if let textView = textView {
            let attributes = textView.typingAttributes
            
            // 检查粗体
            if let font = attributes[.font] as? UIFont {
                isBold = font.fontDescriptor.symbolicTraits.contains(.traitBold)
                isItalic = font.fontDescriptor.symbolicTraits.contains(.traitItalic)
                fontSize = font.pointSize
            } else {
                isBold = false
                isItalic = false
                fontSize = UIFont.systemFontSize
            }
            
            // 检查下划线
            isUnderlined = (attributes[.underlineStyle] as? Int) != nil && (attributes[.underlineStyle] as? Int) != 0
            
            // 检查颜色
            if let color = attributes[.foregroundColor] as? UIColor {
                textColor = Color(color)
            }
            
            return
        }
        
        // 如果没有 textView，从选中文本读取属性
        let selectedRange = context.selectedRange
        guard selectedRange.location < attributedContent.length else {
            // 空文本或光标在末尾，保持当前状态不变
            return
        }
        
        let effectiveRange = selectedRange.length > 0 ? selectedRange : NSRange(location: max(0, selectedRange.location - 1), length: 1)
        guard effectiveRange.location < attributedContent.length else {
            return
        }
        
        let attributes = attributedContent.attributes(at: effectiveRange.location, effectiveRange: nil)
        
        // 检查字体属性
        if let font = attributes[.font] as? UIFont {
            isBold = font.fontDescriptor.symbolicTraits.contains(.traitBold)
            isItalic = font.fontDescriptor.symbolicTraits.contains(.traitItalic)
            fontSize = font.pointSize
        } else {
            isBold = false
            isItalic = false
            fontSize = UIFont.systemFontSize
        }
        
        // 检查下划线
        isUnderlined = (attributes[.underlineStyle] as? Int) != nil && (attributes[.underlineStyle] as? Int) != 0
        
        // 检查颜色
        if let color = attributes[.foregroundColor] as? UIColor {
            textColor = Color(color)
        }
    }
    
    /// 切换粗体
    func toggleBold() {
        // 立即切换状态，确保 UI 响应
        isBold.toggle()
        
        // 手动触发 objectWillChange 以确保视图更新
        objectWillChange.send()
        
        // 应用到 RichTextContext
        context.toggleStyle(.bold)
        
        // 同步更新 typingAttributes
        if let textView = textView {
            var attributes = textView.typingAttributes
            if let font = attributes[.font] as? UIFont {
                let descriptor = font.fontDescriptor
                let newDescriptor: UIFontDescriptor
                if isBold {
                    newDescriptor = descriptor.withSymbolicTraits(descriptor.symbolicTraits.union(.traitBold)) ?? descriptor
                } else {
                    newDescriptor = descriptor.withSymbolicTraits(descriptor.symbolicTraits.subtracting(.traitBold)) ?? descriptor
                }
                attributes[.font] = UIFont(descriptor: newDescriptor, size: font.pointSize)
                textView.typingAttributes = attributes
            }
        }
    }
    
    /// 切换斜体
    func toggleItalic() {
        // 立即切换状态，确保 UI 响应
        isItalic.toggle()
        
        // 手动触发 objectWillChange 以确保视图更新
        objectWillChange.send()
        
        // 应用到 RichTextContext
        context.toggleStyle(.italic)
        
        // 同步更新 typingAttributes
        if let textView = textView {
            var attributes = textView.typingAttributes
            if let font = attributes[.font] as? UIFont {
                let descriptor = font.fontDescriptor
                let newDescriptor: UIFontDescriptor
                if isItalic {
                    newDescriptor = descriptor.withSymbolicTraits(descriptor.symbolicTraits.union(.traitItalic)) ?? descriptor
                } else {
                    newDescriptor = descriptor.withSymbolicTraits(descriptor.symbolicTraits.subtracting(.traitItalic)) ?? descriptor
                }
                attributes[.font] = UIFont(descriptor: newDescriptor, size: font.pointSize)
                textView.typingAttributes = attributes
            }
        }
    }
    
    /// 切换下划线
    func toggleUnderline() {
        // 立即切换状态，确保 UI 响应
        isUnderlined.toggle()
        
        // 手动触发 objectWillChange 以确保视图更新
        objectWillChange.send()
        
        // 应用到 RichTextContext
        context.toggleStyle(.underlined)
        
        // 同步更新 typingAttributes
        if let textView = textView {
            var attributes = textView.typingAttributes
            if isUnderlined {
                attributes[.underlineStyle] = NSUnderlineStyle.single.rawValue
            } else {
                attributes.removeValue(forKey: .underlineStyle)
            }
            textView.typingAttributes = attributes
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
        onCategoryTap: (() -> Void)? = nil,
        initialText: String? = nil
    ) {
        self.viewModel = viewModel
        self.config = config
        self.onCategoryTap = onCategoryTap
        
        // 如果有初始文本，设置到 ViewModel
        if let text = initialText, !text.isEmpty {
            viewModel.setText(text)
        }
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
                    // ✅ 保存 UITextView 引用到 ViewModel
                    // didSet 会自动处理待设置的初始文本
                    DispatchQueue.main.async {
                        viewModel.textView = textView as? UITextView
                    }
                }
            }
            .frame(minHeight: config.minHeight)
            .background(config.backgroundColor)
//          富文本的更新，先注释掉
//            .onChange(of: viewModel.context.selectedRange) { _ in
//                viewModel.updateFormatState()
//            }
//            .onChange(of: viewModel.attributedContent) { _ in
//                viewModel.updateFormatState()
//            }
        }
    }
}
