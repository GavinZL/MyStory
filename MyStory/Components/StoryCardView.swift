import SwiftUI

struct StoryCardView: View {
    let story: StoryEntity
    let firstImage: UIImage?
    let hideCategoryDisplay: Bool
    let onCategoryTap: (() -> Void)?
    
    // MARK: - Services
    @State private var mediaService = MediaStorageService()
    
    // MARK: - Image Viewer State
    @State private var showImageViewer = false
    @State private var selectedImageIndex = 0
    
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
        VStack(alignment: .leading, spacing: AppTheme.Spacing.xl) {
            // 内容摘要（隐藏标题，只显示content）
            if let content = story.content, !content.isEmpty {
                Text(content)
                    .font(AppTheme.Typography.body)
                    .foregroundColor(AppTheme.Colors.textPrimary)
                    .lineLimit(5)
            }
            
            // 图片网格展示
            if !allMediaItems.isEmpty {
                mediaGridView
            }
            
            // 分类信息 + 位置信息（同一行）
            if !hideCategoryDisplay || locationText != nil {
                HStack(spacing: AppTheme.Spacing.s) {
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
                    
                    if let locationText = locationText {
                        HStack(spacing: AppTheme.Spacing.xs) {
                            Image(systemName: "mappin.circle.fill")
                                .font(.system(size: 16))
                                .foregroundColor(AppTheme.Colors.primary)
                                .padding(.leading, AppTheme.Spacing.l)
                            
                            Text(locationText)
                                .font(AppTheme.Typography.caption)
                                .foregroundColor(AppTheme.Colors.textSecondary)
                                .lineLimit(1)
                        }
                    }
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(AppTheme.Spacing.l)
        .fullScreenCover(isPresented: $showImageViewer) {
            ImageGalleryViewer(
                images: loadAllImages(),
                initialIndex: selectedImageIndex,
                isPresented: $showImageViewer
            )
        }
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
    
    // MARK: - Media Grid / Video View
    @ViewBuilder
    private var mediaGridView: some View {
        let images = imageItems()
        let videos = videoItems()
        
        if let firstVideo = videos.first {
            // 存在视频时，仅展示视频缩略图
            videoItemView(media: firstVideo)
        } else if !images.isEmpty {
            // 仅图片时，按 3x3 九宫格展示
            let columns = Array(repeating: GridItem(.flexible(), spacing: AppTheme.Spacing.s), count: 3)
            
            LazyVGrid(columns: columns, spacing: AppTheme.Spacing.s) {
                ForEach(Array(images.prefix(9).enumerated()), id: \.offset) { index, media in
                    mediaItemView(media: media, index: index, totalCount: min(images.count, 9))
                }
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
                    .frame(height: 90)
                    .clipped()
                    .cornerRadius(AppTheme.Radius.s)
            } else {
                RoundedRectangle(cornerRadius: AppTheme.Radius.s)
                    .fill(AppTheme.Colors.surface.opacity(0.15))
                    .frame(height: 90)
                    .overlay(
                        Image(systemName: "photo")
                            .font(.system(size: 24))
                            .foregroundColor(AppTheme.Colors.border)
                    )
            }
        }
        .contentShape(Rectangle())
        .onTapGesture {
            openImageViewer(media: media)
        }
    }
    
    @ViewBuilder
    private func videoItemView(media: MediaEntity) -> some View {
        ZStack(alignment: .center) {
            if let image = loadMediaImage(media: media) {
                Image(uiImage: image)
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .frame(maxWidth: .infinity, maxHeight: 180)
                    .clipped()
                    .cornerRadius(AppTheme.Radius.s)
            } else {
                RoundedRectangle(cornerRadius: AppTheme.Radius.s)
                    .fill(AppTheme.Colors.surface.opacity(0.15))
                    .frame(height: 180)
            }
            
            Circle()
                .fill(Color.black.opacity(0.6))
                .frame(width: 40, height: 40)
            Image(systemName: "play.fill")
                .font(.system(size: 22))
                .foregroundColor(.white)
        }
        .contentShape(Rectangle())
        .onTapGesture {
            openVideoFullscreen(media: media)
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
    
    private func imageItems() -> [MediaEntity] {
        allMediaItems.filter { $0.type == "image" }
    }
    
    private func videoItems() -> [MediaEntity] {
        allMediaItems.filter { $0.type == "video" }
    }
    
    private func loadAllImages() -> [UIImage] {
        imageItems().compactMap { media in
            let fileName = (media.thumbnailFileName ?? media.fileName) ?? ""
            return mediaService.loadImage(fileName: fileName)
        }
    }
    
    private func openImageViewer(media: MediaEntity) {
        let items = imageItems()
        if let mediaId = media.id, let idx = items.firstIndex(where: { $0.id == mediaId }) {
            selectedImageIndex = idx
        } else {
            selectedImageIndex = 0
        }
        showImageViewer = true
    }
    
    private func openVideoFullscreen(media: MediaEntity) {
        guard let fileName = media.fileName,
            let url = mediaService.loadVideoURL(fileName: fileName) else {
            print("无法加载视频文件: fileName 为空或 URL 加载失败")
            return
        }
        
        if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
        let window = windowScene.windows.first,
        let rootVC = window.rootViewController {
            let hosting = UIHostingController(rootView: VideoPlayerView(videoURL: url))
            hosting.modalPresentationStyle = .fullScreen
            rootVC.present(hosting, animated: true, completion: nil)
        }
    }

}
