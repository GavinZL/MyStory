import SwiftUI
import PhotosUI
import AVFoundation
import CoreData

// MARK: - New Story Editor View

struct NewStoryEditorView: View {
    let existingStory: StoryEntity?
    let category: CategoryEntity?
    let onSaveComplete: (() -> Void)?
    
    @Environment(\.managedObjectContext) private var context
    @EnvironmentObject private var coreData: CoreDataStack
    @Environment(\.dismiss) private var dismiss
    
    @StateObject private var viewModel = NewStoryEditorViewModel()
    
    @State private var imagePickerItems: [PhotosPickerItem] = []
    @State private var videoPickerItems: [PhotosPickerItem] = []
    @State private var showMediaSourceSheet = false
    
    var body: some View {
        ZStack {
            AppTheme.Colors.background
                .ignoresSafeArea()
            
            VStack(spacing: 0) {
                topBar
                contentScrollView
                bottomToolbar
            }
        }
        .onAppear {
            viewModel.configureIfNeeded(
                context: context,
                coreData: coreData,
                existingStory: existingStory,
                initialCategory: category
            )
        }
        .fullScreenCover(isPresented: $viewModel.isShowingVideoPlayer) {
            if let url = viewModel.currentPlayingVideoURL {
                VideoPlayerView(videoURL: url)
            }
        }
        .sheet(isPresented: $showMediaSourceSheet) {
            mediaSourceSheet
        }
        .withLoadingIndicator()
    }
    
    // MARK: - Top Bar
    
    private var topBar: some View {
        VStack(spacing: 0) {
            HStack {
                Button {
                    dismiss()
                } label: {
                    Image(systemName: "xmark")
                        .foregroundColor(AppTheme.Colors.textPrimary)
                }
                
                Spacer()
                
                VStack(spacing: 2) {
                    Text(viewModel.currentDateTitle)
                        .font(AppTheme.Typography.title2)
                        .foregroundColor(AppTheme.Colors.textPrimary)
                    Text(viewModel.currentDateSubtitle)
                        .font(AppTheme.Typography.footnote)
                        .foregroundColor(AppTheme.Colors.textSecondary)
                }
                
                Spacer()
                
                Button {
                    viewModel.save {
                        onSaveComplete?()
                        dismiss()
                    }
                } label: {
                    Image(systemName: "checkmark")
                        .foregroundColor(viewModel.canSave ? AppTheme.Colors.primary : AppTheme.Colors.textSecondary)
                }
                .disabled(!viewModel.canSave || viewModel.isSaving)
            }
            .padding(.horizontal, AppTheme.Spacing.l)
            .padding(.vertical, AppTheme.Spacing.m)
            
            Rectangle()
                .fill(AppTheme.Colors.border)
                .frame(height: 0.5)
        }
    }
    
    // MARK: - Content
    
    private var contentScrollView: some View {
        ScrollView(.vertical, showsIndicators: false) {
            VStack(alignment: .leading, spacing: AppTheme.Spacing.l) {
                textEditorSection
                mediaSection
                locationSection
            }
            .padding(.horizontal, AppTheme.Spacing.l)
            .padding(.top, AppTheme.Spacing.l)
            .padding(.bottom, AppTheme.Spacing.xl)
        }
    }
    
    private var textEditorSection: some View {
        RichTextEditorView(
            viewModel: viewModel.richTextEditorViewModel,
            config: RichTextEditorConfig(
                minHeight: 160,
                backgroundColor: .clear
            )
        )
    }
    
    // MARK: - Media Section
    
    private var mediaSection: some View {
        VStack(alignment: .leading, spacing: AppTheme.Spacing.m) {
            if !viewModel.images.isEmpty {
                imageGrid
            }
            
            if viewModel.hasVideoThumbnail {
                videoThumbnail
            }
            
            // 仅在图片未满9张且无视频时显示添加按钮
            if viewModel.images.count < 9 && !viewModel.hasVideoThumbnail {
                addMediaEntry
            }
        }
    }
    
    private var imageGrid: some View {
        let columns = [
            GridItem(.flexible(), spacing: AppTheme.Spacing.s),
            GridItem(.flexible(), spacing: AppTheme.Spacing.s),
            GridItem(.flexible(), spacing: AppTheme.Spacing.s)
        ]
        
        let screenWidth = UIScreen.main.bounds.width
        let horizontalPadding = AppTheme.Spacing.l * 2
        let gridSpacing = AppTheme.Spacing.s * 2
        let itemWidth = (screenWidth - horizontalPadding - gridSpacing) / 3
        
        return LazyVGrid(columns: columns, spacing: AppTheme.Spacing.s) {
            ForEach(Array(viewModel.images.enumerated()), id: \.offset) { index, image in
                ZStack(alignment: .topTrailing) {
                    Image(uiImage: image)
                        .resizable()
                        .scaledToFill()
                        .frame(width: itemWidth, height: itemWidth)
                        .clipShape(RoundedRectangle(cornerRadius: AppTheme.Radius.m))
                    
                    Button {
                        viewModel.removeImage(at: index)
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundColor(.white)
                            .background(Circle().fill(Color.black.opacity(0.6)))
                    }
                    .padding(AppTheme.Spacing.xs)
                }
            }
        }
    }
    
    private var videoThumbnail: some View {
        let screenWidth = UIScreen.main.bounds.width
        let horizontalPadding = AppTheme.Spacing.l * 2
        let maxSize = screenWidth - horizontalPadding
        
        return ZStack(alignment: .topTrailing) {
            Button {
                viewModel.playVideo()
            } label: {
                ZStack {
                    if let thumbnail = viewModel.videoThumbnails.first {
                        let imageSize = thumbnail.size
                        let aspectRatio = imageSize.width / imageSize.height
                        
                        let displayWidth = aspectRatio > 1 ? maxSize : min(maxSize * aspectRatio, maxSize)
                        let displayHeight = aspectRatio > 1 ? min(maxSize / aspectRatio, maxSize) : maxSize
                        
                        Image(uiImage: thumbnail)
                            .resizable()
                            .scaledToFit()
                            .frame(width: displayWidth, height: displayHeight)
                            .clipShape(RoundedRectangle(cornerRadius: AppTheme.Radius.m))
                    }
                    
                    Circle()
                        .fill(Color.black.opacity(0.6))
                        .frame(width: 40, height: 40)
                    
                    Image(systemName: "play.fill")
                        .foregroundColor(.white)
                }
            }
            .buttonStyle(.plain)
            .frame(maxWidth: .infinity, alignment: .leading)
            
            Button {
                viewModel.deleteVideo()
            } label: {
                Image(systemName: "xmark.circle.fill")
                    .foregroundColor(.white)
                    .background(Circle().fill(Color.black.opacity(0.6)))
            }
            .padding(AppTheme.Spacing.xs)
        }
    }
    
    private var addMediaEntry: some View {
        Group {
            if viewModel.images.isEmpty && !viewModel.hasVideoThumbnail {
                Button {
                    showMediaSourceSheet = true
                } label: {
                    RoundedRectangle(cornerRadius: AppTheme.Radius.l)
                        .fill(AppTheme.Colors.surface)
                        .frame(width: 120, height: 120)
                        .overlay(
                            Image(systemName: "plus")
                                .font(.system(size: 24, weight: .medium))
                                .foregroundColor(AppTheme.Colors.textSecondary)
                        )
                }
                .buttonStyle(.plain)
            } else if !viewModel.images.isEmpty {
                PhotosPicker(
                    selection: $imagePickerItems,
                    maxSelectionCount: 9,
                    matching: .images
                ) {
                    RoundedRectangle(cornerRadius: AppTheme.Radius.l)
                        .strokeBorder(AppTheme.Colors.border, style: StrokeStyle(lineWidth: 1, dash: [4]))
                        .frame(width: 80, height: 80)
                        .overlay(
                            Image(systemName: "plus")
                                .font(.system(size: 18, weight: .medium))
                                .foregroundColor(AppTheme.Colors.textSecondary)
                        )
                }
                .onChange(of: imagePickerItems) { items in
                    Task {
                        await viewModel.handleMediaItemsChange(items: items, expectedVideo: false)
                        imagePickerItems.removeAll()
                    }
                }
            } else {
                PhotosPicker(
                    selection: $videoPickerItems,
                    maxSelectionCount: 1,
                    matching: .videos
                ) {
                    RoundedRectangle(cornerRadius: AppTheme.Radius.l)
                        .strokeBorder(AppTheme.Colors.border, style: StrokeStyle(lineWidth: 1, dash: [4]))
                        .frame(width: 80, height: 80)
                        .overlay(
                            Image(systemName: "plus")
                                .font(.system(size: 18, weight: .medium))
                                .foregroundColor(AppTheme.Colors.textSecondary)
                        )
                }
                .onChange(of: videoPickerItems) { items in
                    Task {
                        await viewModel.handleMediaItemsChange(items: items, expectedVideo: true)
                        videoPickerItems.removeAll()
                    }
                }
            }
        }
    }
    
    // MARK: - Media Source Sheet
    
    private var mediaSourceSheet: some View {
        VStack(spacing: AppTheme.Spacing.l) {
            Spacer()
            
            VStack(spacing: AppTheme.Spacing.l) {
                HStack(spacing: AppTheme.Spacing.xl) {
                    PhotosPicker(
                        selection: $imagePickerItems,
                        maxSelectionCount: 9,
                        matching: .images
                    ) {
                        VStack(spacing: AppTheme.Spacing.s) {
                            Image(systemName: "photo.on.rectangle")
                                .font(.system(size: 24))
                            Text("图库")
                                .font(AppTheme.Typography.body)
                        }
                        .frame(maxWidth: .infinity)
                    }
                    .onChange(of: imagePickerItems) { items in
                        Task {
                            await viewModel.handleMediaItemsChange(items: items, expectedVideo: false)
                            imagePickerItems.removeAll()
                            showMediaSourceSheet = false
                        }
                    }
                    
                    PhotosPicker(
                        selection: $videoPickerItems,
                        maxSelectionCount: 1,
                        matching: .videos
                    ) {
                        VStack(spacing: AppTheme.Spacing.s) {
                            Image(systemName: "video")
                                .font(.system(size: 24))
                            Text("视频")
                                .font(AppTheme.Typography.body)
                        }
                        .frame(maxWidth: .infinity)
                    }
                    .onChange(of: videoPickerItems) { items in
                        Task {
                            await viewModel.handleMediaItemsChange(items: items, expectedVideo: true)
                            videoPickerItems.removeAll()
                            showMediaSourceSheet = false
                        }
                    }
                }
            }
            .padding(AppTheme.Spacing.xl)
            .frame(maxWidth: .infinity)
            .background(AppTheme.Colors.surface)
            .clipShape(RoundedRectangle(cornerRadius: AppTheme.Radius.l))
            .padding(.horizontal, AppTheme.Spacing.l)
            .padding(.bottom, AppTheme.Spacing.xl)
        }
        .background(Color.black.opacity(0.4).ignoresSafeArea())
    }
    
    // MARK: - Location Section
    
    private var locationSection: some View {
        VStack(alignment: .leading, spacing: AppTheme.Spacing.s) {
            if let _ = viewModel.locationInfo {
                HStack {
                    Label(viewModel.locationDisplayText, systemImage: "mappin.circle.fill")
                        .foregroundColor(AppTheme.Colors.primary)
                        .font(AppTheme.Typography.subheadline)
                    Spacer()
                    Button {
                        viewModel.clearLocation()
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundColor(.secondary)
                    }
                }
            } else {
                Button {
                    viewModel.fetchCurrentLocation()
                } label: {
                    Label("story.addLocation".localized, systemImage: "mappin.circle")
                        .font(AppTheme.Typography.subheadline)
                }
                .foregroundColor(AppTheme.Colors.primary)
            }
        }
    }
    
    // MARK: - Bottom Toolbar
    
    private var bottomToolbar: some View {
        VStack(spacing: 0) {
            Rectangle()
                .fill(AppTheme.Colors.border)
                .frame(height: 0.5)
            
            HStack(spacing: AppTheme.Spacing.l) {
                Button {
                    viewModel.showCategoryPicker = true
                } label: {
                    Image(systemName: "folder.fill")
                }
                
                Button {
                    viewModel.richTextEditorViewModel.insertTimestamp()
                } label: {
                    Image(systemName: "calendar")
                }
                
                Button {
                    viewModel.richTextEditorViewModel.toggleBold()
                } label: {
                    Image(systemName: "bold")
                        .foregroundColor(viewModel.richTextEditorViewModel.isBold ? AppTheme.Colors.primary : AppTheme.Colors.textPrimary)
                }
                
                Button {
                    viewModel.richTextEditorViewModel.toggleItalic()
                } label: {
                    Image(systemName: "italic")
                        .foregroundColor(viewModel.richTextEditorViewModel.isItalic ? AppTheme.Colors.primary : AppTheme.Colors.textPrimary)
                }
                
                Button {
                    viewModel.richTextEditorViewModel.insertTodoItem()
                } label: {
                    Image(systemName: "list.bullet")
                }
                
                Spacer()
            }
            .font(.system(size: 18))
            .foregroundColor(AppTheme.Colors.textPrimary)
            .padding(.horizontal, AppTheme.Spacing.l)
            .padding(.vertical, AppTheme.Spacing.s)
            .background(AppTheme.Colors.surface.ignoresSafeArea(edges: .bottom))
        }
        .sheet(isPresented: $viewModel.showCategoryPicker) {
            SimpleCategoryPicker(selectedCategories: $viewModel.categorySelectionSet) {
                viewModel.applySelectedCategory()
            }
        }
    }
}

// MARK: - View Model

final class NewStoryEditorViewModel: ObservableObject {
    @Published var title: String = ""
    @Published var images: [UIImage] = []
    @Published var videoURLs: [URL] = []
    @Published var videoThumbnails: [UIImage] = []
    @Published var videoFileName: String? = nil
    @Published var selectedCategoryId: UUID? = nil
    @Published var locationInfo: LocationInfo? = nil
    @Published var isSaving: Bool = false
    @Published var isShowingVideoPlayer: Bool = false
    @Published var currentPlayingVideoURL: URL? = nil
    @Published var showCategoryPicker: Bool = false
    
    @Published var categorySelectionSet: Set<UUID> = []
    
    // 使用通用富文本编辑器 ViewModel
    let richTextEditorViewModel = RichTextEditorViewModel()
    
    private var context: NSManagedObjectContext?
    private var coreData: CoreDataStack?
    private var mediaService = MediaStorageService()
    private var locationService = LocationService()
    private var existingStory: StoryEntity?
    private var initialCategory: CategoryEntity?
    private var isConfigured = false
    
    var canSave: Bool { !title.isEmpty || !richTextEditorViewModel.isEmpty }
    var hasVideoThumbnail: Bool { !videoThumbnails.isEmpty || videoFileName != nil }
    
    var currentDateTitle: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MM月dd日"
        return formatter.string(from: Date())
    }
    
    var currentDateSubtitle: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "EEE HH:mm"
        
        let isChineseLocale = LocalizationManager.shared.currentLanguage == .chinese
        formatter.locale = Locale(identifier: isChineseLocale ? "zh-Hans" : "en")
        return formatter.string(from: Date())
    }
    
    func configureIfNeeded(
        context: NSManagedObjectContext,
        coreData: CoreDataStack,
        existingStory: StoryEntity?,
        initialCategory: CategoryEntity?
    ) {
        guard !isConfigured else { return }
        self.context = context
        self.coreData = coreData
        self.existingStory = existingStory
        self.initialCategory = initialCategory
        loadInitialData()
        isConfigured = true
    }
    
    private func loadInitialData() {
        guard let context = context else { return }
        
        if let story = existingStory {
            title = story.title ?? ""
            let contentString = story.content ?? ""
            richTextEditorViewModel.setText(contentString)
            
            if let city = story.locationCity {
                locationInfo = LocationInfo(
                    latitude: story.latitude,
                    longitude: story.longitude,
                    name: story.locationName,
                    address: story.locationAddress,
                    city: city,
                    country: nil
                )
            }
            
            let mediaService = self.mediaService
            if let mediaSet = story.media as? Set<MediaEntity> {
                let medias = Array(mediaSet)
                let imageMedias = medias.filter { $0.type == "image" }
                images = imageMedias.compactMap { media in
                    guard let name = media.fileName else { return nil }
                    return mediaService.loadImage(fileName: name)
                }
                let videoMedias = medias.filter { $0.type == "video" }
                if let videoMedia = videoMedias.first {
                    videoFileName = videoMedia.fileName
                    if let fileName = videoMedia.fileName,
                       let url = mediaService.loadVideoURL(fileName: fileName) {
                        videoURLs = [url]
                    }
                    if let thumbFileName = videoMedia.thumbnailFileName,
                       let thumbnail = mediaService.loadVideoThumbnail(fileName: thumbFileName) {
                        videoThumbnails = [thumbnail]
                    }
                }
            }
            
            if let set = story.categories as? Set<CategoryEntity>,
               let first = set.first,
               let cid = first.id {
                selectedCategoryId = cid
            }
        } else if let category = initialCategory, let cid = category.id {
            selectedCategoryId = cid
        }
        
        if let cid = selectedCategoryId {
            categorySelectionSet = [cid]
        }
    }
    
    // MARK: - Media Handling
    
    func handleMediaItemsChange(items: [PhotosPickerItem], expectedVideo: Bool) async {
        guard !items.isEmpty else { return }
        
        if expectedVideo {
            images.removeAll()
            LoadingIndicatorManager.shared.show(message: "story.videoLoading".localized)
        } else {
            videoURLs.removeAll()
            videoThumbnails.removeAll()
            videoFileName = nil
        }
        
        for item in items {
            if !expectedVideo,
               let data = try? await item.loadTransferable(type: Data.self),
               let image = UIImage(data: data) {
                await MainActor.run {
                    self.images.append(image)
                }
            } else if expectedVideo,
                      let movie = try? await item.loadTransferable(type: VideoTransferable.self) {
                await handleVideoLoad(movie.url)
            }
        }
        
        if expectedVideo {
            await MainActor.run {
                LoadingIndicatorManager.shared.hide()
            }
        }
    }
    
    private func handleVideoLoad(_ url: URL) async {
        await MainActor.run {
            videoURLs.removeAll()
            videoThumbnails.removeAll()
            videoURLs.append(url)
        }
        if let thumbnail = await generateVideoThumbnailAsync(url: url) {
            await MainActor.run {
                videoThumbnails.append(thumbnail)
            }
        }
    }
    
    func removeImage(at index: Int) {
        guard images.indices.contains(index) else { return }
        images.remove(at: index)
    }
    
    func deleteVideo() {
        videoURLs.removeAll()
        videoThumbnails.removeAll()
        videoFileName = nil
    }
    
    func playVideo() {
        if let fileName = videoFileName,
           let url = mediaService.loadVideoURL(fileName: fileName) {
            currentPlayingVideoURL = url
            isShowingVideoPlayer = true
        } else if let url = videoURLs.first {
            currentPlayingVideoURL = url
            isShowingVideoPlayer = true
        }
    }
    
    private func generateVideoThumbnailAsync(url: URL) async -> UIImage? {
        await Task.detached {
            let asset = AVAsset(url: url)
            let generator = AVAssetImageGenerator(asset: asset)
            generator.appliesPreferredTrackTransform = true
            generator.maximumSize = CGSize(width: 800, height: 800)
            generator.requestedTimeToleranceBefore = CMTime(seconds: 1, preferredTimescale: 60)
            generator.requestedTimeToleranceAfter = CMTime(seconds: 1, preferredTimescale: 60)
            let time = CMTime(seconds: 0.1, preferredTimescale: 60)
            do {
                let cgImage = try generator.copyCGImage(at: time, actualTime: nil)
                return UIImage(cgImage: cgImage)
            } catch {
                print("生成视频缩略图失败: \(error)")
                return nil
            }
        }.value
    }
    
    // MARK: - Location
    
    var locationDisplayText: String {
        if let city = locationInfo?.city {
            return city
        }
        if let name = locationInfo?.name {
            return name
        }
        return "story.locationSelected".localized
    }
    
    func fetchCurrentLocation() {
        locationService.requestCurrentLocation { [weak self] info in
            self?.locationInfo = info
        }
    }
    
    func clearLocation() {
        locationInfo = nil
    }
    
    // MARK: - Category
    
    func applySelectedCategory() {
        if let first = categorySelectionSet.first {
            selectedCategoryId = first
        } else {
            selectedCategoryId = nil
        }
    }
    
    // MARK: - Save
    
    func save(onSuccess: @escaping () -> Void) {
        guard !isSaving, let context = context, let coreData = coreData else { return }
        isSaving = true
        
        let story = getOrCreateStory(in: context)
        updateStoryBasicInfo(story)
        updateStoryLocation(story)
        updateStoryCategories(story, in: context)
        
        if existingStory == nil {
            saveMediaToStory(story)
        }
        
        coreData.save()
        isSaving = false
        onSuccess()
    }
    
    private func getOrCreateStory(in context: NSManagedObjectContext) -> StoryEntity {
        let now = Date()
        if let story = existingStory {
            story.updatedAt = now
            return story
        } else {
            let story = StoryEntity(context: context)
            story.id = UUID()
            story.createdAt = now
            story.timestamp = now
            story.updatedAt = now
            return story
        }
    }
    
    private func updateStoryBasicInfo(_ story: StoryEntity) {
        story.title = title
        let contentString = richTextEditorViewModel.plainText
        story.content = contentString.isEmpty ? nil : contentString
    }
    
    private func updateStoryLocation(_ story: StoryEntity) {
        guard let info = locationInfo else { return }
        story.locationName = info.name
        story.locationCity = info.city
        story.latitude = info.latitude
        story.longitude = info.longitude
    }
    
    private func updateStoryCategories(_ story: StoryEntity, in context: NSManagedObjectContext) {
        let service = CoreDataCategoryService(context: context)
        var targetId = selectedCategoryId
        if targetId == nil {
            if let defaultEntity = fetchDefaultCategory(in: context), let did = defaultEntity.id {
                targetId = did
            }
        }
        guard let finalId = targetId else { return }
        
        if let current = story.categories as? Set<CategoryEntity>, !current.isEmpty {
            let toRemove = current.filter { $0.id != finalId }
            if !toRemove.isEmpty {
                story.removeFromCategories(NSSet(array: Array(toRemove)))
            }
        }
        if let entity = service.fetchCategory(id: finalId) {
            story.addToCategories(entity)
        }
    }
    
    private func fetchDefaultCategory(in context: NSManagedObjectContext) -> CategoryEntity? {
        let now = Date()
        
        let l1Request = CategoryEntity.fetchRequest()
        l1Request.predicate = NSPredicate(format: "name == %@ AND level == %d", "Default", 1)
        l1Request.fetchLimit = 1
        var level1: CategoryEntity?
        do {
            level1 = try context.fetch(l1Request).first
        } catch {
            print("查询一级默认分类失败: \(error)")
        }
        if level1 == nil {
            let entity = CategoryEntity(context: context)
            entity.id = UUID()
            entity.name = "Default"
            entity.iconName = "folder.fill"
            entity.colorHex = "#007AFF"
            entity.level = 1
            entity.sortOrder = 0
            entity.createdAt = now
            level1 = entity
        }
        guard let l1 = level1 else { return nil }
        
        let l2Request = CategoryEntity.fetchRequest()
        l2Request.predicate = NSPredicate(format: "name == %@ AND level == %d AND parent == %@", "Default", 2, l1)
        l2Request.fetchLimit = 1
        var level2: CategoryEntity?
        do {
            level2 = try context.fetch(l2Request).first
        } catch {
            print("查询二级默认分类失败: \(error)")
        }
        if level2 == nil {
            let entity = CategoryEntity(context: context)
            entity.id = UUID()
            entity.name = "Default"
            entity.iconName = "folder.fill"
            entity.colorHex = "#007AFF"
            entity.level = 2
            entity.sortOrder = 0
            entity.createdAt = now
            entity.parent = l1
            level2 = entity
        }
        guard let l2 = level2 else { return nil }
        
        let l3Request = CategoryEntity.fetchRequest()
        l3Request.predicate = NSPredicate(format: "name == %@ AND level == %d AND parent == %@", "Default", 3, l2)
        l3Request.fetchLimit = 1
        var level3: CategoryEntity?
        do {
            level3 = try context.fetch(l3Request).first
        } catch {
            print("查询三级默认分类失败: \(error)")
        }
        if level3 == nil {
            let entity = CategoryEntity(context: context)
            entity.id = UUID()
            entity.name = "Default"
            entity.iconName = "folder.fill"
            entity.colorHex = "#007AFF"
            entity.level = 3
            entity.sortOrder = 0
            entity.createdAt = now
            entity.parent = l2
            level3 = entity
        }
        do {
            try context.save()
        } catch {
            print("保存默认分类失败: \(error)")
            return nil
        }
        return level3
    }
    
    private func saveMediaToStory(_ story: StoryEntity) {
        let now = Date()
        for image in images {
            saveImage(image, to: story, createdAt: now)
        }
        for url in videoURLs {
            saveVideo(url, to: story, createdAt: now)
        }
    }
    
    private func saveImage(_ image: UIImage, to story: StoryEntity, createdAt: Date) {
        do {
            let res = try mediaService.saveImageWithThumbnail(image)
            guard let context = context else { return }
            let media = MediaEntity(context: context)
            media.id = UUID()
            media.type = "image"
            media.fileName = res.fileName
            media.thumbnailFileName = res.thumbFileName
            media.createdAt = createdAt
            media.story = story
        } catch {
            print("保存图片失败: \(error)")
        }
    }
    
    private func saveVideo(_ url: URL, to story: StoryEntity, createdAt: Date) {
        do {
            let res = try mediaService.saveVideo(from: url)
            guard let context = context else { return }
            let media = MediaEntity(context: context)
            media.id = UUID()
            media.type = "video"
            media.fileName = res.fileName
            media.thumbnailFileName = res.thumbFileName
            media.createdAt = createdAt
            media.story = story
        } catch {
            print("保存视频失败: \(error)")
        }
    }
}
