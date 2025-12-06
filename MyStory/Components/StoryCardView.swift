import SwiftUI

struct StoryCardView: View {
    let story: StoryEntity
    let firstImage: UIImage?
    let hideCategoryDisplay: Bool
    let onCategoryTap: (() -> Void)?
    
    // MARK: - Services
    @State private var mediaService = MediaStorageService()
    
    // MARK: - Computed Properties
    private var allMediaItems: [MediaEntity] {
        guard let mediaSet = story.media as? Set<MediaEntity> else { return [] }
        return Array(mediaSet).sorted { ($0.createdAt ?? Date.distantPast) < ($1.createdAt ?? Date.distantPast) }
    }
    
    private var categoryNamesText: String? {
        guard let categories = story.categories as? Set<CategoryEntity>, !categories.isEmpty else {
            return nil
        }
        let names = categories.compactMap { $0.name?.trimmingCharacters(in: .whitespacesAndNewlines) }.filter { !$0.isEmpty }
        guard !names.isEmpty else { return nil }
        return names.joined(separator: " >> ")
    }
    
    private var locationText: String? {
        var components: [String] = []
        
        if let city = story.locationCity, !city.isEmpty {
            components.append(city)
        }
        
        if let address = story.locationAddress, !address.isEmpty {
            components.append(address)
        }
        
        return components.isEmpty ? nil : components.joined(separator: " • ")
    }

    var body: some View {
        VStack(alignment: .leading, spacing: AppTheme.Spacing.m) {
            // 内容摘要（隐藏标题，只显示content）
            if let content = story.content, !content.isEmpty {
                Text(content)
                    .font(AppTheme.Typography.body)
                    .foregroundColor(AppTheme.Colors.textPrimary)
                    .lineLimit(3)
            }
            
            // 图片网格展示
            if !allMediaItems.isEmpty {
                mediaGridView
            }
            
            // 分类信息
            if !hideCategoryDisplay, let categoryNamesText = categoryNamesText {
                HStack(spacing: AppTheme.Spacing.xs) {
                    Image(systemName: "folder.fill")
                        .font(.system(size: 16))
                        .foregroundColor(AppTheme.Colors.primary)
                    
                    Text(categoryNamesText)
                        .font(AppTheme.Typography.subheadline)
                        .foregroundColor(AppTheme.Colors.textSecondary)
                        .lineLimit(1)
                }
                .onTapGesture {
                    onCategoryTap?()
                }
            }
            
            // 位置信息（仅当有位置数据时显示）
            if let locationText = locationText {
                HStack(spacing: AppTheme.Spacing.xs) {
                    Image(systemName: "mappin.circle.fill")
                        .font(.system(size: 16))
                        .foregroundColor(AppTheme.Colors.primary)
                    
                    Text(locationText)
                        .font(AppTheme.Typography.caption)
                        .foregroundColor(AppTheme.Colors.textSecondary)
                        .lineLimit(1)
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(AppTheme.Spacing.l)
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
    
    // MARK: - Media Grid View
    @ViewBuilder
    private var mediaGridView: some View {
        let displayCount = min(allMediaItems.count, 4)
        let columns = displayCount == 1 ? 1 : 2
        
        LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: AppTheme.Spacing.s), count: columns), spacing: AppTheme.Spacing.s) {
            ForEach(Array(allMediaItems.prefix(displayCount).enumerated()), id: \.offset) { index, media in
                mediaItemView(media: media, index: index, totalCount: displayCount)
            }
        }
    }
    
    @ViewBuilder
    private func mediaItemView(media: MediaEntity, index: Int, totalCount: Int) -> some View {
        ZStack(alignment: .center) {
            if let image = loadMediaImage(media: media) {
                Image(uiImage: image)
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .frame(height: totalCount == 1 ? 200 : 120)
                    .clipped()
                    .cornerRadius(AppTheme.Radius.s)
                
                if media.type == "video" {
                    Circle()
                        .fill(Color.black.opacity(0.6))
                        .frame(width: 40, height: 40)
                    Image(systemName: "play.fill")
                        .font(.system(size: 20))
                        .foregroundColor(.white)
                }
            } else {
                RoundedRectangle(cornerRadius: AppTheme.Radius.s)
                    .fill(AppTheme.Colors.surface.opacity(0.15))
                    .frame(height: totalCount == 1 ? 200 : 120)
                    .overlay(
                        Image(systemName: media.type == "video" ? "video" : "photo")
                            .font(.system(size: 24))
                            .foregroundColor(AppTheme.Colors.border)
                    )
            }
        }
    }
    
    // MARK: - Helper Methods
    private func loadMediaImage(media: MediaEntity) -> UIImage? {
        if media.type == "video" {
            if let thumbFileName = media.thumbnailFileName {
                return mediaService.loadVideoThumbnail(fileName: thumbFileName)
            }
            return nil
        } else {
            let fileName = (media.thumbnailFileName ?? media.fileName) ?? ""
            return mediaService.loadImage(fileName: fileName)
        }
    }

}
