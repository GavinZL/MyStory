import SwiftUI
import PhotosUI
import AVFoundation

// MARK: - Main View
struct StoryEditorView: View {
    // MARK: - Properties
    let existingStory: StoryEntity?
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
    init(existingStory: StoryEntity? = nil, onSaveComplete: (() -> Void)? = nil) {
        self.existingStory = existingStory
        self.onSaveComplete = onSaveComplete
        
        guard let story = existingStory else { return }
        
        // Initialize basic info
        _title = State(initialValue: story.title)
        _content = State(initialValue: story.content ?? "")
        
        // Initialize location
        if let city = story.locationCity,
           let lat = story.latitude?.doubleValue,
           let lng = story.longitude?.doubleValue {
            _locationInfo = State(initialValue: LocationInfo(
                latitude: lat,
                longitude: lng,
                name: story.locationName,
                address: nil,
                city: city,
                country: nil
            ))
        }
        
        // Initialize media
        let mediaService = MediaStorageService()
        guard let medias = story.medias else { return }
        
        // Load images
        let imageMedias = medias.filter { $0.type == "image" }
        let loadedImages = imageMedias.compactMap { media -> UIImage? in
            mediaService.loadImage(fileName: media.fileName)
        }
        _images = State(initialValue: loadedImages)
        
        // Load video
        let videoMedias = medias.filter { $0.type == "video" }
        if let videoMedia = videoMedias.first {
            _videoFileName = State(initialValue: videoMedia.fileName)
            
            if let videoURL = mediaService.loadVideoURL(fileName: videoMedia.fileName) {
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
                contentSection
                mediaSection
                locationSection
            }
            .navigationTitle(existingStory != nil ? "编辑故事" : "新建故事")
            .toolbar {
                toolbarContent
            }
            .fullScreenCover(isPresented: $showVideoPlayer) {
                videoPlayerView
            }
            .withLoadingIndicator()
        }
    }
    
    // MARK: - View Components
    private var titleSection: some View {
        Section(header: Text("标题")) {
            TextField("请输入故事标题", text: $title)
        }
    }
    
    private var contentSection: some View {
        Section(header: Text("内容")) {
            TextEditor(text: $content)
                .frame(minHeight: 150)
        }
    }
    
    private var mediaSection: some View {
        Section(header: Text("媒体")) {
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
        Section(header: Text("位置")) {
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
            Button("取消") { dismiss() }
        }
        
        ToolbarItem(placement: .navigationBarTrailing) {
            Button(action: save) {
                if isSaving {
                    ProgressView()
                } else {
                    Text("保存")
                }
            }
            .disabled(!canSave)
        }
    }
    
    @ViewBuilder
    private var videoPlayerView: some View {
        if let url = selectedVideoURL {
            VideoPlayerView(videoURL: url)
        } else {
            EmptyView()
        }
    }
    
    // MARK: - Media Picker
    private var mediaPickerButton: some View {
        PhotosPicker(
            selection: $mediaItems,
            maxSelectionCount: videoURLs.isEmpty ? 9 : 1,
            matching: allowedMediaFilter
        ) {
            Label("添加图片/视频", systemImage: "photo.on.rectangle")
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
            GridItem(.flexible(), spacing: 8)
        ]
        
        return LazyVGrid(columns: columns, spacing: 8) {
            ForEach(Array(images.enumerated()), id: \.offset) { index, img in
                imageItemView(image: img, index: index)
            }
        }
        .padding(.vertical, 4)
    }
    
    private func imageItemView(image: UIImage, index: Int) -> some View {
        ZStack(alignment: .topTrailing) {
            Image(uiImage: image)
                .resizable()
                .scaledToFill()
                .frame(width: (UIScreen.main.bounds.width - 64) / 3,
                       height: (UIScreen.main.bounds.width - 64) / 3)
                .clipped()
                .cornerRadius(8)
            
            Button {
                images.remove(at: index)
            } label: {
                Image(systemName: "xmark.circle.fill")
                    .foregroundColor(.white)
                    .background(Circle().fill(Color.black.opacity(0.6)))
            }
            .padding(4)
        }
    }
    
    // MARK: - Video Thumbnail
    private var videoThumbnailView: some View {
        let columns = [GridItem(.flexible(), spacing: 8)]
        
        return LazyVGrid(columns: columns, spacing: 8) {
            ZStack(alignment: .topTrailing) {
                if let thumbnail = videoThumbnails.first {
                    videoThumbnailButton(thumbnail: thumbnail)
                    videoDeleteButton
                }
            }
        }
        .padding(.vertical, 4)
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
                    .cornerRadius(8)
                
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
        .padding(4)
    }
    
    // MARK: - Location Views
    private var locationDisplayView: some View {
        HStack {
            Label(locationInfoText, systemImage: "mappin.circle.fill")
                .foregroundColor(.blue)
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
            Label("添加位置", systemImage: "mappin.circle")
        }
    }
    
    private var locationInfoText: String {
        locationInfo?.city ?? locationInfo?.name ?? "已选择位置"
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
                LoadingIndicatorManager.shared.show(message: "正在加载视频...")
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
    
    // MARK: - Save Story
    private func save() {
        guard !isSaving else { return }
        isSaving = true
        
        let story = getOrCreateStory()
        updateStoryBasicInfo(story)
        updateStoryLocation(story)
        
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
        story.latitude = NSNumber(value: info.latitude)
        story.longitude = NSNumber(value: info.longitude)
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
