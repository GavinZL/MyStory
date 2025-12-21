//
//  FontSettingsSheet.swift
//  MyStory
//
//  字体大小与颜色设置面板
//

import SwiftUI

/// 字体设置面板
struct FontSettingsSheet: View {
    /// 当前字体大小
    @Binding var fontSize: CGFloat
    
    /// 当前字体颜色
    @Binding var textColor: Color
    
    /// 应用回调
    var onApply: (CGFloat, Color) -> Void
    
    /// 16 色预设调色板（2 行 x 8 列）
    private let colorGrid: [[Color]] = [
        [
            .black,
            (Color(hex: "5F9EA0") ?? .black),
            (Color(hex: "FFB6C1") ?? .black),
            (Color(hex: "DC143C") ?? .black),
            (Color(hex: "8B7355") ?? .black),
            (Color(hex: "8B4513") ?? .black),
            (Color(hex: "00FF00") ?? .black),
            (Color(hex: "ADFF2F") ?? .black)
        ],
        [
            .white,
            (Color(hex: "FFC0CB") ?? .black),
            (Color(hex: "FF69B4") ?? .black),
            (Color(hex: "C71585") ?? .black),
            (Color(hex: "A0522D") ?? .black),
            (Color(hex: "228B22") ?? .black),
            (Color(hex: "9ACD32") ?? .black),
            (Color(hex: "696969") ?? .black)
        ]
    ]
    
    var body: some View {
        VStack(spacing: AppTheme.Spacing.l) {
            // 字体大小
            VStack(alignment: .leading, spacing: AppTheme.Spacing.s) {
                HStack {
                    Image(systemName: "textformat.size")
                    Text("字体大小")
                    Spacer()
                }
                .font(.system(size: 16))
                
                HStack(spacing: AppTheme.Spacing.m) {
                    Text("A")
                        .font(.system(size: 14))
                        .foregroundColor(AppTheme.Colors.textSecondary)
                    
                    Slider(value: $fontSize, in: 10...48, step: 2)
                        .tint(AppTheme.Colors.primary)
                    
                    Text("A")
                        .font(.system(size: 24, weight: .medium))
                        .foregroundColor(AppTheme.Colors.textSecondary)
                }
            }
            .padding(.horizontal, AppTheme.Spacing.l)
            
            // 字体颜色
            VStack(alignment: .leading, spacing: AppTheme.Spacing.s) {
                HStack {
                    Image(systemName: "paintpalette")
                    Text("字体颜色")
                    Spacer()
                }
                .font(.system(size: 16))
                
                VStack(spacing: AppTheme.Spacing.m) {
                    ForEach(0..<colorGrid.count, id: \.self) { row in
                        HStack(spacing: AppTheme.Spacing.m) {
                            ForEach(0..<colorGrid[row].count, id: \.self) { col in
                                let color = colorGrid[row][col]
                                ColorCircle(
                                    color: color,
                                    isSelected: color.isApproximatelyEqual(to: textColor)
                                ) {
                                    textColor = color
                                }
                            }
                        }
                    }
                }
            }
            .padding(.horizontal, AppTheme.Spacing.l)
            
            Spacer(minLength: AppTheme.Spacing.m)
        }
        .padding(.vertical, AppTheme.Spacing.m)
        .presentationDetents([.height(280)])
        .onChange(of: fontSize) { newValue in
            onApply(newValue, textColor)
        }
        .onChange(of: textColor) { newValue in
            onApply(fontSize, newValue)
        }
    }
}

/// 颜色圆点
private struct ColorCircle: View {
    let color: Color
    let isSelected: Bool
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            ZStack {
                Circle()
                    .fill(color)
                    .frame(width: 32, height: 32)
                    .overlay(
                        Circle()
                            .stroke(Color.gray.opacity(0.3), lineWidth: 1)
                    )
                
                if isSelected {
                    Image(systemName: "checkmark")
                        .font(.system(size: 14, weight: .bold))
                        .foregroundColor(checkmarkColor)
                }
            }
        }
    }
    
    private var checkmarkColor: Color {
        // 深色背景用白色勾，浅色背景用主色勾
        var red: CGFloat = 0
        var green: CGFloat = 0
        var blue: CGFloat = 0
        var alpha: CGFloat = 0
        UIColor(color).getRed(&red, green: &green, blue: &blue, alpha: &alpha)
        let brightness = (red + green + blue) / 3.0
        return brightness < 0.5 ? .white : AppTheme.Colors.primary
    }
}

// MARK: - Color 辅助

private extension Color {
    /// 近似相等比较，用于选中状态判断
    func isApproximatelyEqual(to other: Color, tolerance: CGFloat = 0.02) -> Bool {
        var r1: CGFloat = 0, g1: CGFloat = 0, b1: CGFloat = 0, a1: CGFloat = 0
        var r2: CGFloat = 0, g2: CGFloat = 0, b2: CGFloat = 0, a2: CGFloat = 0
        
        UIColor(self).getRed(&r1, green: &g1, blue: &b1, alpha: &a1)
        UIColor(other).getRed(&r2, green: &g2, blue: &b2, alpha: &a2)
        
        return abs(r1 - r2) < tolerance &&
        abs(g1 - g2) < tolerance &&
        abs(b1 - b2) < tolerance
    }
}
