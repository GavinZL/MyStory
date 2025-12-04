import SwiftUI

struct StoryCardView: View {
    let story: StoryEntity
    let firstImage: UIImage?
    let hideCategoryDisplay: Bool
    let onCategoryTap: (() -> Void)?
    
    private var firstMedia: MediaEntity? {
        (story.media as? Set<MediaEntity>)?.first
    }
    
    private var categoryNamesText: String? {
        guard let categories = story.categories as? Set<CategoryEntity>, !categories.isEmpty else {
            return nil
        }
        let names = categories.compactMap { $0.name?.trimmingCharacters(in: .whitespacesAndNewlines) }.filter { !$0.isEmpty }
        guard !names.isEmpty else { return nil }
        return names.joined(separator: " >> ")
    }
    
    private var isVideo: Bool {
        firstMedia?.type == "video"
    }
    
    // 计算图片宽高比，判断是横屏还是竖屏
    private var isLandscape: Bool {
        guard let image = firstImage else { return false }
        return image.size.width > image.size.height
    }

    var body: some View {
        VStack(alignment: .leading, spacing: AppTheme.Spacing.xl) {
            if let uiImg = firstImage {
                ZStack(alignment: .center) {
                    Image(uiImage: uiImg)
                        .resizable()
                        .aspectRatio(contentMode: isLandscape ? .fit : .fill)
                        .cornerRadius(AppTheme.Radius.s)
                        .frame(maxWidth: .infinity)
                        .frame(height: 200)
                        .cornerRadius(AppTheme.Radius.s)
                    
                    if isVideo {
                        Circle()
                            .fill(Color.black.opacity(0.6))
                            .frame(width: 60, height: 60)
                        Image(systemName: "play.fill")
                            .font(.system(size: 28))
                            .foregroundColor(.white)
                    }
                }
            } else {
                RoundedRectangle(cornerRadius: AppTheme.Radius.s)
                    .fill(AppTheme.Colors.surface.opacity(0.15))
                    .frame(maxWidth: .infinity)
                    .frame(height: 200)
                    .overlay(
                        Image(systemName: "photo")
                            .font(.system(size: 28))
                            .foregroundColor(AppTheme.Colors.border)
                    )
            }

            Text(story.title ?? "None")
                .font(.headline)
                .lineLimit(2)
                .foregroundColor(.primary)
            
            if !hideCategoryDisplay, let categoryNamesText = categoryNamesText {
                HStack(spacing: AppTheme.Spacing.xs) {
                    Image(systemName: "folder.fill")
                        .foregroundColor(AppTheme.Colors.primary)
                    Text(categoryNamesText)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .lineLimit(1)
                }
                .onTapGesture {
                    onCategoryTap?()
                }
            }
            
            if let city = story.locationCity, !city.isEmpty {
                HStack(spacing: AppTheme.Spacing.xs) {
                    Image(systemName: "mappin.circle.fill").foregroundColor(AppTheme.Colors.primary)
                    Text(city)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .lineLimit(1)
                }
            }

            if let content = story.content, !content.isEmpty {
                Text(content)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .lineLimit(3)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(AppTheme.Spacing.xs)
        .background(
            RoundedRectangle(cornerRadius: AppTheme.Radius.s)
                .fill(AppTheme.Colors.surface.opacity(0.05))
        )
    }

}
