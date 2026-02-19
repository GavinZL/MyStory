//
//  AppTheme+CardStyles.swift
//  MyStory
//
//  统一的卡片样式定义
//

import SwiftUI

// MARK: - Card Style Modifiers
extension AppTheme {
    struct CardStyles {
        // MARK: - Standard Card
        /// 标准卡片 - 用于 StoryCard, CategoryCard
        struct StandardCard: ViewModifier {
            func body(content: Content) -> some View {
                content
                    .padding(AppTheme.Spacing.m)
                    .background(
                        RoundedRectangle(cornerRadius: AppTheme.Radius.m)
                            .fill(AppTheme.Colors.surface)
                            .shadow(
                                color: AppTheme.Shadow.small.color,
                                radius: AppTheme.Shadow.small.radius,
                                x: AppTheme.Shadow.small.x,
                                y: AppTheme.Shadow.small.y
                            )
                    )
            }
        }
        
        // MARK: - Elevated Card
        /// 高程卡片 - 用于弹窗、悬浮面板
        struct ElevatedCard: ViewModifier {
            func body(content: Content) -> some View {
                content
                    .padding(AppTheme.Spacing.l)
                    .background(
                        RoundedRectangle(cornerRadius: AppTheme.Radius.l)
                            .fill(AppTheme.Colors.background)
                            .shadow(
                                color: AppTheme.Shadow.medium.color,
                                radius: AppTheme.Shadow.medium.radius,
                                x: AppTheme.Shadow.medium.x,
                                y: AppTheme.Shadow.medium.y
                            )
                    )
            }
        }
        
        // MARK: - Outline Card
        /// 描边卡片 - 用于选择态容器、表单分组
        struct OutlineCard: ViewModifier {
            var isSelected: Bool = false
            
            func body(content: Content) -> some View {
                content
                    .padding(AppTheme.Spacing.m)
                    .background(
                        RoundedRectangle(cornerRadius: AppTheme.Radius.m)
                            .stroke(
                                isSelected ? AppTheme.Colors.primary : AppTheme.Colors.border,
                                lineWidth: isSelected ? 2 : 1
                            )
                            .background(
                                RoundedRectangle(cornerRadius: AppTheme.Radius.m)
                                    .fill(isSelected ? AppTheme.Colors.primary.opacity(AppTheme.Opacity.subtle) : Color.clear)
                            )
                    )
            }
        }
        
        // MARK: - Grouped Card
        /// 分组卡片 - 用于设置列表项
        struct GroupedCard: ViewModifier {
            func body(content: Content) -> some View {
                content
                    .padding(.horizontal, AppTheme.Spacing.l)
                    .padding(.vertical, AppTheme.Spacing.m)
                    .background(AppTheme.Colors.surface)
            }
        }
    }
}

// MARK: - View Extensions
extension View {
    /// 应用标准卡片样式
    func standardCard() -> some View {
        modifier(AppTheme.CardStyles.StandardCard())
    }
    
    /// 应用高程卡片样式
    func elevatedCard() -> some View {
        modifier(AppTheme.CardStyles.ElevatedCard())
    }
    
    /// 应用描边卡片样式
    func outlineCard(isSelected: Bool = false) -> some View {
        modifier(AppTheme.CardStyles.OutlineCard(isSelected: isSelected))
    }
    
    /// 应用分组卡片样式
    func groupedCard() -> some View {
        modifier(AppTheme.CardStyles.GroupedCard())
    }
}

// MARK: - Preview
#Preview {
    ScrollView {
        VStack(spacing: AppTheme.Spacing.xl) {
            // Standard Card
            VStack(alignment: .leading, spacing: AppTheme.Spacing.s) {
                Text("Standard Card")
                    .font(AppTheme.Typography.headline)
                Text("用于 StoryCard, CategoryCard 等常规卡片")
                    .font(AppTheme.Typography.body)
                    .foregroundColor(AppTheme.Colors.textSecondary)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .standardCard()
            
            // Elevated Card
            VStack(alignment: .leading, spacing: AppTheme.Spacing.s) {
                Text("Elevated Card")
                    .font(AppTheme.Typography.headline)
                Text("用于弹窗、悬浮面板等需要更强层次感的场景")
                    .font(AppTheme.Typography.body)
                    .foregroundColor(AppTheme.Colors.textSecondary)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .elevatedCard()
            
            // Outline Card - Normal
            VStack(alignment: .leading, spacing: AppTheme.Spacing.s) {
                Text("Outline Card")
                    .font(AppTheme.Typography.headline)
                Text("用于选择态容器、表单分组")
                    .font(AppTheme.Typography.body)
                    .foregroundColor(AppTheme.Colors.textSecondary)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .outlineCard()
            
            // Outline Card - Selected
            VStack(alignment: .leading, spacing: AppTheme.Spacing.s) {
                Text("Outline Card (Selected)")
                    .font(AppTheme.Typography.headline)
                Text("选中状态的描边卡片")
                    .font(AppTheme.Typography.body)
                    .foregroundColor(AppTheme.Colors.textSecondary)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .outlineCard(isSelected: true)
        }
        .padding()
    }
    .background(AppTheme.Colors.background)
}
