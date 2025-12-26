import SwiftUI
import PhotosUI
import AVFoundation

// MARK: - Video Player Wrapper
struct VideoPlayerWrapper: View {
    @Binding var videoURL: URL?
    
    var body: some View {
        if let url = videoURL {
            VideoPlayerView(videoURL: url)
        } else {
            EmptyView()
        }
    }
}

// MARK: - Main View
struct StoryEditorView: View {
    // MARK: - Properties
    let existingStory: StoryEntity?
    let category: CategoryEntity?  // 传入的分类信息
    let onSaveComplete: (() -> Void)?
    
    // MARK: - Environment
    @Environment(\.managedObjectContext) private var context
    @EnvironmentObject private var coreData: CoreDataStack
    @Environment(\.dismiss) private var dismiss
    
    // MARK: - State
    @State private var title: String = ""
    @State private var content: String = ""
    @State private var locationInfo: LocationInfo?
    @State private var isSaving = false
    
    // MARK: - Media State
    @State private var mediaItems: [PhotosPickerItem] = []
    @State private var images: [UIImage] = []
    @State private var videoURLs: [URL] = []
    @State private var videoThumbnails: [UIImage] = []
    @State private var videoFileName: String?
    
    // MARK: - Video Player State
    @State private var showVideoPlayer = false
    @State private var selectedVideoURL: URL?
    
    // MARK: - Category Selection State
    @State private var selectedCategoryIds: Set<UUID> = []
    @State private var showCategoryPickerSheet = false
    
    // 分类ID（从传入的category初始化）
    private let categoryId: UUID?
    
    // MARK: - Services
    @State private var locationService = LocationService()
    @State private var mediaService = MediaStorageService()
    
    // MARK: - Computed Properties
    private var allowedMediaFilter: PHPickerFilter {
        if !videoURLs.isEmpty {
            return .videos
        } else if !images.isEmpty {
            return .images
        } else {
            return .any(of: [.images, .videos])
        }
    }
    
    private var canSave: Bool {
        !title.isEmpty || !content.isEmpty
    }
    
    // MARK: - Initializer
    init(existingStory: StoryEntity? = nil, category: CategoryEntity? = nil, onSaveComplete: (() -> Void)? = nil) {
        self.existingStory = existingStory
        self.category = category
        self.categoryId = category?.id
        self.onSaveComplete = onSaveComplete
        
        guard let story = existingStory else { return }
        
        // Initialize basic info
        _title = State(initialValue: story.title ?? "none")
        _content = State(initialValue: story.content ?? "")
        
        // Initialize location
        if let city = story.locationCity {
            _locationInfo = State(initialValue: LocationInfo(
                latitude: story.latitude,
                longitude: story.longitude,
                name: story.locationName,
                address: nil,
                city: city,
                country: nil
            ))
        }
        
        // Initialize media
        let mediaService = MediaStorageService()
        guard let mediaSet = story.media as? Set<MediaEntity> else { return }
        let medias = Array(mediaSet)
        
        // Load images
        let imageMedias = medias.filter { $0.type == "image" }
        let loadedImages = imageMedias.compactMap { media -> UIImage? in
            mediaService.loadImage(fileName: media.fileName ?? "")
        }
        _images = State(initialValue: loadedImages)
        
        // Load video
        let videoMedias = medias.filter { $0.type == "video" }
        if let videoMedia = videoMedias.first {
            _videoFileName = State(initialValue: videoMedia.fileName)
            
            if let videoURL = mediaService.loadVideoURL(fileName: videoMedia.fileName ?? "") {
                _videoURLs = State(initialValue: [videoURL])
            }
            
            if let thumbFileName = videoMedia.thumbnailFileName,
               let thumbnail = mediaService.loadVideoThumbnail(fileName: thumbFileName) {
                _videoThumbnails = State(initialValue: [thumbnail])
            }
        }
    }
    
    // MARK: - Body
    var body: some View {
        NavigationView {
            Form {
                titleSection
                categorySection
                contentSection
                mediaSection
                locationSection
            }
            .navigationTitle(existingStory != nil ? "story.edit".localized : "story.new".localized)
            .toolbar {
                toolbarContent
            }
            .fullScreenCover(isPresented: $showVideoPlayer) {
                VideoPlayerWrapper(videoURL: $selectedVideoURL)
            }
            .sheet(isPresented: $showCategoryPickerSheet) {
                SimpleCategoryPicker(selectedCategories: $selectedCategoryIds) {
                    showCategoryPickerSheet = false
                }
            }
            .onAppear {
                setupInitialCategorySelection()
            }

            .withLoadingIndicator()
        }
    }
    
    // MARK: - View Components
    private var titleSection: some View {
        Section(header: Text("story.title".localized)) {
            TextField("story.titlePlaceholder".localized, text: $title)
        }
    }
    
    private var categorySection: some View {
        Section(header: Text("story.category".localized)) {
            Button {
                showCategoryPickerSheet = true
            } label: {
                HStack {
                    Image(systemName: "folder.fill")
                        .foregroundColor(AppTheme.Colors.primary)
                    Text(selectedCategoryDisplayText)
                        .font(.body)
                        .foregroundColor(.secondary)
                    Spacer()
                    Image(systemName: "chevron.right")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                .contentShape(Rectangle())
            }
            .buttonStyle(PlainButtonStyle())
        }
    }
    
    private var selectedCategoryDisplayText: String {
        let service = CoreDataCategoryService(context: context)
        let names: [String] = selectedCategoryIds.compactMap { id in
            service.fetchCategory(id: id)?.name
        }
        return names.isEmpty ? "Default" : names.joined(separator: " >> ")
    }
    
    private var contentSection: some View {
        Section(header: Text("story.content".localized)) {
            TextEditor(text: $content)
                .frame(minHeight: 150)
        }
    }
    

    
    private var mediaSection: some View {
        Section(header: Text("story.media".localized)) {
            mediaPickerButton
            
            if !images.isEmpty {
                imageGridView
            }
            
            if (!videoURLs.isEmpty || videoFileName != nil), videoThumbnails.first != nil {
                videoThumbnailView
            }
        }
    }
    
    private var locationSection: some View {
        Section(header: Text("story.location".localized)) {
            if locationInfo != nil {
                locationDisplayView
            } else {
                locationAddButton
            }
        }
    }
    
    @ToolbarContentBuilder
    private var toolbarContent: some ToolbarContent {
        ToolbarItem(placement: .navigationBarLeading) {
            Button("common.cancel".localized) { dismiss() }
        }
        
        ToolbarItem(placement: .navigationBarTrailing) {
            Button(action: save) {
                if isSaving {
                    ProgressView()
                } else {
                    Text("common.save".localized)
                }
            }
            .disabled(!canSave)
        }
    }
    

    // MARK: - Media Picker
    private var mediaPickerButton: some View {
        PhotosPicker(
            selection: $mediaItems,
            maxSelectionCount: videoURLs.isEmpty ? 9 : 1,
            matching: allowedMediaFilter
        ) {
            Label("story.addMedia".localized, systemImage: "photo.on.rectangle")
        }
        .onChange(of: mediaItems) { items in
            handleMediaItemsChange(items)
        }
    }
    
    // MARK: - Image Grid
    private var imageGridView: some View {
        let columns = [
            GridItem(.flexible(), spacing: 8),
            GridItem(.flexible(), spacing: 8),
            GridItem(.flexible(), spacing: AppTheme.Spacing.s)
        ]
        
        return LazyVGrid(columns: columns, spacing: AppTheme.Spacing.s) {
            ForEach(Array(images.enumerated()), id: \.offset) { index, img in
                imageItemView(image: img, index: index)
            }
        }
        .padding(.vertical, AppTheme.Spacing.xs)
    }
    
    private func imageItemView(image: UIImage, index: Int) -> some View {
        ZStack(alignment: .topTrailing) {
            Image(uiImage: image)
                .resizable()
                .scaledToFill()
                .frame(width: (UIScreen.main.bounds.width - 64) / 3,
                       height: (UIScreen.main.bounds.width - 64) / 3)
                .clipped()
                .cornerRadius(AppTheme.Radius.s)
            
            Button {
                images.remove(at: index)
            } label: {
                Image(systemName: "xmark.circle.fill")
                    .foregroundColor(.white)
                    .background(Circle().fill(Color.black.opacity(0.6)))
            }
            .padding(AppTheme.Spacing.xs)
        }
    }
    
    // MARK: - Video Thumbnail
    private var videoThumbnailView: some View {
        let columns = [GridItem(.flexible(), spacing: 8)]
        
        return LazyVGrid(columns: columns, spacing: AppTheme.Spacing.s) {
            ZStack(alignment: .topTrailing) {
                if let thumbnail = videoThumbnails.first {
                    videoThumbnailButton(thumbnail: thumbnail)
                    videoDeleteButton
                }
            }
        }
        .padding(.vertical, AppTheme.Spacing.xs)
    }
    
    private func videoThumbnailButton(thumbnail: UIImage) -> some View {
        Button {
            handleVideoPlayback()
        } label: {
            ZStack(alignment: .center) {
                Image(uiImage: thumbnail)
                    .resizable()
                    .scaledToFill()
                    .frame(width: UIScreen.main.bounds.width - 64,
                           height: UIScreen.main.bounds.width - 64)
                    .clipped()
                    .cornerRadius(AppTheme.Radius.s)
                
                Circle()
                    .fill(Color.black.opacity(0.6))
                    .frame(width: 40, height: 40)
                
                Image(systemName: "play.fill")
                    .font(.system(size: 20))
                    .foregroundColor(.white)
            }
        }
        .buttonStyle(PlainButtonStyle())
    }
    
    private var videoDeleteButton: some View {
        Button {
            deleteVideo()
        } label: {
            Image(systemName: "xmark.circle.fill")
                .foregroundColor(.white)
                .background(Circle().fill(Color.black.opacity(0.6)))
        }
        .padding(AppTheme.Spacing.xs)
    }
    
    // MARK: - Location Views
    private var locationDisplayView: some View {
        HStack {
            Label(locationInfoText, systemImage: "mappin.circle.fill")
                .foregroundColor(AppTheme.Colors.primary)
            Spacer()
            Button {
                locationInfo = nil
            } label: {
                Image(systemName: "xmark.circle.fill")
                    .foregroundColor(.secondary)
            }
        }
    }
    
    private var locationAddButton: some View {
        Button {
            locationService.requestCurrentLocation { info in
                self.locationInfo = info
            }
        } label: {
            Label("story.addLocation".localized, systemImage: "mappin.circle")
        }
    }
    
    private var locationInfoText: String {
        locationInfo?.city ?? locationInfo?.name ?? "story.locationSelected".localized
    }
    
    // MARK: - Media Handling
    private func handleMediaItemsChange(_ items: [PhotosPickerItem]) {
        guard !items.isEmpty else { return }
        
        Task {
            await processMediaItems(items)
            mediaItems.removeAll()
        }
    }
    
    private func processMediaItems(_ items: [PhotosPickerItem]) async {
        // 判断媒体类型并清空对应数组
        if let firstItem = items.first {
            let isVideo = await checkIfVideo(item: firstItem)
            
            if isVideo {
                images.removeAll()
                LoadingIndicatorManager.shared.show(message: "story.videoLoading".localized)
            } else {
                videoURLs.removeAll()
                videoThumbnails.removeAll()
                videoFileName = nil
            }
        }
        
        // 处理每个项目
        for item in items {
            if let data = try? await item.loadTransferable(type: Data.self),
               let img = UIImage(data: data) {
                await handleImageLoad(img)
            } else if let movie = try? await item.loadTransferable(type: VideoTransferable.self) {
                await handleVideoLoad(movie.url)
            }
        }
    }
    
    private func handleImageLoad(_ image: UIImage) async {
        await MainActor.run {
            images.append(image)
        }
    }
    
    private func handleVideoLoad(_ url: URL) async {
        await MainActor.run {
            videoURLs.removeAll()
            videoThumbnails.removeAll()
            videoURLs.append(url)
        }
        
        // 异步生成缩略图
        if let thumbnail = await generateVideoThumbnailAsync(url: url) {
            await MainActor.run {
                videoThumbnails.append(thumbnail)
                LoadingIndicatorManager.shared.hide()
            }
        } else {
            await MainActor.run {
                LoadingIndicatorManager.shared.hide()
            }
        }
    }
    
    // MARK: - Video Playback
    private func handleVideoPlayback() {
        if let fileName = videoFileName {
            playVideoFromFile(fileName)
        } else if let videoURL = videoURLs.first {
            playVideoFromURL(videoURL)
        } else {
            print("❌ 无法获取视频URL")
        }
    }
    
    private func playVideoFromFile(_ fileName: String) {
        guard let url = mediaService.loadVideoURL(fileName: fileName) else {
            print("❌ 加载视频失败：无法解密视频文件")
            return
        }
        selectedVideoURL = url
        showVideoPlayer = true
    }
    
    private func playVideoFromURL(_ url: URL) {
        selectedVideoURL = url
        showVideoPlayer = true
    }
    
    private func deleteVideo() {
        videoURLs.removeAll()
        videoThumbnails.removeAll()
        videoFileName = nil
    }
    
    // 初始化分类选择（在视图出现时）
    private func setupInitialCategorySelection() {
        if !selectedCategoryIds.isEmpty { return }
        if let story = existingStory, let set = story.categories as? Set<CategoryEntity> {
            let ids = set.compactMap { $0.id }
            if !ids.isEmpty { selectedCategoryIds = Set(ids); return }
        }
        if let cid = categoryId { selectedCategoryIds = [cid]; return }
        if let defaultEntity = fetchDefaultCategory(), let did = defaultEntity.id {
            selectedCategoryIds = [did]
        }
    }
    
    // MARK: - Save Story
    private func save() {
        guard !isSaving else { return }
        isSaving = true
        
        let story = getOrCreateStory()
        updateStoryBasicInfo(story)
        updateStoryLocation(story)
        updateStoryCategories(story)  // ⚠️ 新增：关联分类
        
        if existingStory == nil {
            saveMediaToStory(story)
        }
        
        coreData.save()
        isSaving = false
        onSaveComplete?()
        dismiss()
    }
    
    private func getOrCreateStory() -> StoryEntity {
        let now = Date()
        
        if let existing = existingStory {
            existing.updatedAt = now
            return existing
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
        story.content = content.isEmpty ? nil : content
    }
    
    private func updateStoryLocation(_ story: StoryEntity) {
        guard let info = locationInfo else { return }
        
        story.locationName = info.name
        story.locationCity = info.city
        story.latitude = Double(truncating: NSNumber(value: info.latitude))
        story.longitude = Double(truncating: NSNumber(value: info.longitude))
    }
    
    // 更新故事分类关联
    private func updateStoryCategories(_ story: StoryEntity) {
        let categoryService = CoreDataCategoryService(context: context)
        var targetIds = selectedCategoryIds
        if targetIds.isEmpty {
            if let defaultEntity = fetchDefaultCategory(), let did = defaultEntity.id {
                targetIds = [did]
            }
        }
        // 移除未选择的分类
        if let current = story.categories as? Set<CategoryEntity> {
            let toRemove = current.filter { cat in
                guard let cid = cat.id else { return false }
                return !targetIds.contains(cid)
            }
            if !toRemove.isEmpty {
                story.removeFromCategories(NSSet(array: Array(toRemove)))
            }
        }
        // 添加选择的分类
        for id in targetIds {
            if let entity = categoryService.fetchCategory(id: id) {
                story.addToCategories(entity)
            }
        }
        print("✅ [故事编辑器] 更新分类关联: \(targetIds.count) 个分类 -> 故事: \(story.title ?? "Untitled")")
    }
        
    /// 获取或创建默认分类（Default）
    /// 返回第三级分类供故事关联
    private func fetchDefaultCategory() -> CategoryEntity? {
        let now = Date()
        
        // 1. 查找或创建一级分类 (L1 Default)
        let l1Request = CategoryEntity.fetchRequest()
        l1Request.predicate = NSPredicate(format: "name == %@ AND level == %d", "Default", 1)
        l1Request.fetchLimit = 1
        
        var level1: CategoryEntity?
        do {
            level1 = try context.fetch(l1Request).first
        } catch {
            print("⚠️ [故事编辑器] 查询一级默认分类失败: \(error)")
        }
        
        if level1 == nil {
            level1 = CategoryEntity(context: context)
            level1?.id = UUID()
            level1?.name = "Default"
            level1?.iconName = "folder.fill"
            level1?.colorHex = "#007AFF"
            level1?.level = 1
            level1?.sortOrder = 0
            level1?.createdAt = now
            print("✅ [故事编辑器] 创建一级默认分类 (L1 Default)")
        }
        
        guard let l1 = level1 else { return nil }
        
        // 2. 查找或创建二级分类 (L2 Default)
        let l2Request = CategoryEntity.fetchRequest()
        l2Request.predicate = NSPredicate(format: "name == %@ AND level == %d AND parent == %@", "Default", 2, l1)
        l2Request.fetchLimit = 1
        
        var level2: CategoryEntity?
        do {
            level2 = try context.fetch(l2Request).first
        } catch {
            print("⚠️ [故事编辑器] 查询二级默认分类失败: \(error)")
        }
        
        if level2 == nil {
            level2 = CategoryEntity(context: context)
            level2?.id = UUID()
            level2?.name = "Default"
            level2?.iconName = "folder.fill"
            level2?.colorHex = "#007AFF"
            level2?.level = 2
            level2?.sortOrder = 0
            level2?.createdAt = now
            level2?.parent = l1
            print("✅ [故事编辑器] 创建二级默认分类 (L2 Default)")
        }
        
        guard let l2 = level2 else { return nil }
        
        // 3. 查找或创建三级分类 (L3 Default)
        let l3Request = CategoryEntity.fetchRequest()
        l3Request.predicate = NSPredicate(format: "name == %@ AND level == %d AND parent == %@", "Default", 3, l2)
        l3Request.fetchLimit = 1
        
        var level3: CategoryEntity?
        do {
            level3 = try context.fetch(l3Request).first
        } catch {
            print("⚠️ [故事编辑器] 查询三级默认分类失败: \(error)")
        }
        
        if level3 == nil {
            level3 = CategoryEntity(context: context)
            level3?.id = UUID()
            level3?.name = "Default"
            level3?.iconName = "folder.fill"
            level3?.colorHex = "#007AFF"
            level3?.level = 3
            level3?.sortOrder = 0
            level3?.createdAt = now
            level3?.parent = l2
            print("✅ [故事编辑器] 创建三级默认分类 (L3 Default)")
        }
        
        // 保存所有变更
        do {
            try context.save()
            print("✅ [故事编辑器] 默认三级分类结构已就绪")
        } catch {
            print("⚠️ [故事编辑器] 保存默认分类失败: \(error)")
            return nil
        }
        
        // 返回三级分类供故事关联
        return level3
    }
    
    private func saveMediaToStory(_ story: StoryEntity) {
        let now = Date()
        
        // 保存图片
        for img in images {
            saveImage(img, to: story, createdAt: now)
        }
        
        // 保存视频
        for videoURL in videoURLs {
            saveVideo(videoURL, to: story, createdAt: now)
        }
    }
    
    private func saveImage(_ image: UIImage, to story: StoryEntity, createdAt: Date) {
        do {
            let res = try mediaService.saveImageWithThumbnail(image)
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
    
    // MARK: - Helper Methods
    private func generateVideoThumbnailAsync(url: URL) async -> UIImage? {
        return await Task.detached {
            let asset = AVAsset(url: url)
            let imageGenerator = AVAssetImageGenerator(asset: asset)
            imageGenerator.appliesPreferredTrackTransform = true
            imageGenerator.maximumSize = CGSize(width: 800, height: 800)
            imageGenerator.requestedTimeToleranceBefore = CMTime(seconds: 1, preferredTimescale: 60)
            imageGenerator.requestedTimeToleranceAfter = CMTime(seconds: 1, preferredTimescale: 60)
            let time = CMTime(seconds: 0.1, preferredTimescale: 60)
            
            do {
                let cgImage = try imageGenerator.copyCGImage(at: time, actualTime: nil)
                return UIImage(cgImage: cgImage)
            } catch {
                print("生成视频缩略图失败: \(error)")
                return nil
            }
        }.value
    }
    
    private func checkIfVideo(item: PhotosPickerItem) async -> Bool {
        if let _ = try? await item.loadTransferable(type: VideoTransferable.self) {
            return true
        }
        return false
    }
}
