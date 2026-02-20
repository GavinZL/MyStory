import SwiftUI
import UIKit
import AVKit

// MARK: - Main View
struct FullScreenStoryView: View {
    // MARK: - Properties
    let stories: [StoryEntity]
    let initialIndex: Int
    let onLoadMore: (() -> Void)?
    let hasMoreData: Bool
    
    // MARK: - State
    @State private var currentIndex: Int
    @StateObject private var coordinator: PageCoordinator
    @State private var navigateToCategoryList = false
    @State private var tappedCategoryNode: CategoryTreeNode?
    
    // MARK: - Initializer
    init(stories: [StoryEntity], initialIndex: Int, onLoadMore: (() -> Void)? = nil, hasMoreData: Bool = true) {
        self.stories = stories
        self.initialIndex = initialIndex
        self.onLoadMore = onLoadMore
        self.hasMoreData = hasMoreData
        self._currentIndex = State(initialValue: initialIndex)
        self._coordinator = StateObject(wrappedValue: PageCoordinator(stories: stories, initialIndex: initialIndex))
    }
    
    // MARK: - Body
    var body: some View {
        ZStack {
            pageViewController
                .navigationTitle(navigationTitle)
                .navigationBarTitleDisplayMode(.inline)
                .toolbar(.hidden, for: .tabBar)
            
            NavigationLink(destination: categoryDestinationView, isActive: $navigateToCategoryList) {
                EmptyView()
            }
            .hidden()
        }
        .onAppear {
            coordinator.onCategoryTap = { node in
                tappedCategoryNode = node
                navigateToCategoryList = true
            }
        }
    }
    
    @ViewBuilder
    private var categoryDestinationView: some View {
        if let node = tappedCategoryNode {
            CategoryStoryListView(category: node)
        } else {
            EmptyView()
        }
    }
    
    // MARK: - View Components
    private var pageViewController: some View {
        PageViewControllerWrapper(
            coordinator: coordinator,
            currentIndex: $currentIndex,
            onReachBoundary: handleBoundaryReached
        )
        .ignoresSafeArea(edges: .bottom)
    }
    
    private var navigationTitle: String {
        if currentIndex < stories.count {
            return stories[currentIndex].title ?? "unknown"
        }
        return "fullscreen.storyDetail".localized
    }
    
    // MARK: - Helper Methods
    private func handleBoundaryReached(_ boundaryType: PageCoordinator.BoundaryType) {
        switch boundaryType {
        case .left:
            // 第一个往左滑，加载更早的数据
            handleLoadEarlierData()
        case .right:
            // 最后一个往右滑，加载更新的数据
            handleLoadNewerData()
        }
    }
    
    private func handleLoadEarlierData() {
        if hasMoreData {
            onLoadMore?()
        }
    }
    
    private func handleLoadNewerData() {
        if hasMoreData {
            onLoadMore?()
        }
    }
}

// MARK: - Page Coordinator
class PageCoordinator: NSObject, ObservableObject, UIPageViewControllerDataSource, UIPageViewControllerDelegate {
    var controllers: [UIViewController]
    @Published var currentIndex: Int
    var onReachBoundary: ((BoundaryType) -> Void)?
    var onCategoryTap: ((CategoryTreeNode) -> Void)?
    
    enum BoundaryType {
        case left   // 第一个往左滑，加载更早的数据
        case right  // 最后一个往右滑，加载更新的数据
    }
    
    init(stories: [StoryEntity], initialIndex: Int, onCategoryTap: ((CategoryTreeNode) -> Void)? = nil) {
        self.onCategoryTap = onCategoryTap
        self.controllers = stories.map { story in
            UIHostingController(rootView: StoryDetailView(story: story, onCategoryTap: onCategoryTap))
        }
        self.currentIndex = initialIndex
        super.init()
    }
    
    func pageViewController(_ pageViewController: UIPageViewController, viewControllerBefore viewController: UIViewController) -> UIViewController? {
        guard let idx = controllers.firstIndex(of: viewController), idx > 0 else {
            // 已经是第一个，尝试向左滑动时触发加载更早的数据
            if let index = controllers.firstIndex(of: viewController), index == 0 {
                onReachBoundary?(.left)
            }
            return nil
        }
        return controllers[idx - 1]
    }
    
    func pageViewController(_ pageViewController: UIPageViewController, viewControllerAfter viewController: UIViewController) -> UIViewController? {
        guard let idx = controllers.firstIndex(of: viewController), idx < controllers.count - 1 else {
            // 已经是最后一个，尝试向右滑动时触发加载更新的数据
            if let index = controllers.firstIndex(of: viewController), index == controllers.count - 1 {
                onReachBoundary?(.right)
            }
            return nil
        }
        return controllers[idx + 1]
    }
    
    func pageViewController(_ pageViewController: UIPageViewController, didFinishAnimating finished: Bool, previousViewControllers: [UIViewController], transitionCompleted completed: Bool) {
        guard completed,
              let visibleViewController = pageViewController.viewControllers?.first,
              let index = controllers.firstIndex(of: visibleViewController) else { return }
        
        // 页面切换完成时，停止之前页面的视频播放
        if let previousVC = previousViewControllers.first as? UIHostingController<StoryDetailView> {
            // 通知之前的页面停止视频
            NotificationCenter.default.post(name: NSNotification.Name("StopVideoPlayback"), object: nil)
        }
        
        currentIndex = index
    }
}

// MARK: - Page View Controller Wrapper
private struct PageViewControllerWrapper: UIViewControllerRepresentable {
    @ObservedObject var coordinator: PageCoordinator
    @Binding var currentIndex: Int
    let onReachBoundary: (PageCoordinator.BoundaryType) -> Void
    
    func makeUIViewController(context: Context) -> UIPageViewController {
        let pageVC = UIPageViewController(
            transitionStyle: .scroll,
            navigationOrientation: .horizontal,
            options: nil
        )
        pageVC.dataSource = coordinator
        pageVC.delegate = coordinator
        
        // 设置边界回调
        coordinator.onReachBoundary = onReachBoundary
        
        let controllers = coordinator.controllers
        if coordinator.currentIndex < controllers.count {
            pageVC.setViewControllers(
                [controllers[coordinator.currentIndex]],
                direction: .forward,
                animated: false
            )
        }
        
        return pageVC
    }
    
    func updateUIViewController(_ pageViewController: UIPageViewController, context: Context) {
        // 同步当前索引
        DispatchQueue.main.async {
            if currentIndex != coordinator.currentIndex {
                currentIndex = coordinator.currentIndex
            }
        }
    }
}

// MARK: - Story Detail View
struct StoryDetailView: View {
    // MARK: - Properties
    let story: StoryEntity
    let onCategoryTap: ((CategoryTreeNode) -> Void)?
    
    // MARK: - State
    @State private var showImageViewer = false
    @State private var selectedImageIndex = 0
    @State private var playingVideoIndex: Int?
    @State private var videoPlayers: [Int: AVPlayer] = [:]
    
    // MARK: - Services
    private let mediaService = MediaStorageService()
    
    // MARK: - Computed Properties
    private var categoryNamesText: String? {
        guard let categories = story.categories as? Set<CategoryEntity>, !categories.isEmpty else { return nil }
        let names = categories.compactMap { $0.name?.trimmingCharacters(in: .whitespacesAndNewlines) }.filter { !$0.isEmpty }
        guard !names.isEmpty else { return nil }
        return names.joined(separator: " >> ")
    }
    
    private func categoryIconName() -> String? {
        guard let categories = story.categories as? Set<CategoryEntity>, let categoryEntity = categories.first else { return nil }
        let iconName = categoryEntity.iconName ?? "folder"
        print("DEBUG: Category iconName = \(iconName ?? "nil")")
        return iconName
    }
    
    /// 判断是否为 SF Symbols 图标
    private func isSystemSymbol(name: String) -> Bool {
        // SF Symbols 通常包含点号分隔，如 "folder.fill", "star.circle"
        // 或者是一些常见的 SF Symbols 名称模式
        let systemSymbols = [
            "folder", "folder.fill", "star", "star.fill",
            "heart", "heart.fill", "circle", "circle.fill",
            "square", "square.fill", "triangle", "triangle.fill"
        ]
        return systemSymbols.contains(name)
    }
    
    private func categoryNode() -> CategoryTreeNode? {
        guard let categories = story.categories as? Set<CategoryEntity>, let categoryEntity = categories.first else { return nil }
        return CategoryTreeNode(
            id: categoryEntity.id ?? UUID(),
            category: CategoryModel(
                id: categoryEntity.id ?? UUID(),
                name: categoryEntity.name ?? "",
                iconName: categoryEntity.iconName ?? "folder.fill",
                colorHex: categoryEntity.colorHex ?? "#007AFF",
                level: Int(categoryEntity.level),
                parentId: categoryEntity.parent?.id,
                sortOrder: Int(categoryEntity.sortOrder),
                createdAt: categoryEntity.createdAt ?? Date()
            ),
            children: [],
            isExpanded: false,
            storyCount: (categoryEntity.stories as? Set<StoryEntity>)?.count ?? 0,
            directStoryCount: (categoryEntity.stories as? Set<StoryEntity>)?.count ?? 0
        )
    }
    
    // MARK: - Media Properties
    private var mediaList: [MediaEntity] {
        guard let medias = story.media as? Set<MediaEntity> else { return [] }
        return medias.sorted { $0.createdAt! < $1.createdAt! }
    }
    
    private var imageMediaList: [MediaEntity] {
        mediaList.filter { $0.type == "image" }
    }
    
    private var videoMediaList: [MediaEntity] {
        mediaList.filter { $0.type == "video" }
    }
    
    // MARK: - Body
    var body: some View {
        GeometryReader { geometry in
            ScrollView {
                VStack(spacing: 0) {
                    // 1. 媒体内容区域
                    if !mediaList.isEmpty {
                        mediaDisplaySection
                    }
                    
                    // 2. 文字内容区域
                    if let content = story.content, !content.isEmpty {
                        contentTextSection
                    }
                    
                    // 3. 元数据区域（日期、分类、位置）
                    metadataSection
                }
            }
        }
        .fullScreenCover(isPresented: $showImageViewer) {
            imageGalleryViewer
        }
        .onDisappear {
            cleanupResources()
        }
        .onReceive(NotificationCenter.default.publisher(for: NSNotification.Name("StopVideoPlayback"))) { _ in
            // 收到停止视频通知时，停止所有视频播放
            stopAllVideos()
        }
    }
    
    // MARK: - View Components
    
    // 文字内容区域
    private var contentTextSection: some View {
        Text(story.content ?? "")
            .font(AppTheme.Typography.body)
            .foregroundColor(AppTheme.Colors.textPrimary)
            .lineSpacing(4)
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal, AppTheme.Spacing.l)
            .padding(.top, AppTheme.Spacing.l)
            .padding(.bottom, AppTheme.Spacing.m)
    }
    

    
    // 元数据区域（日期、分类、位置）
    private var metadataSection: some View {
        VStack(alignment: .leading, spacing: AppTheme.Spacing.m) {
            // 日期时间
            HStack(spacing: AppTheme.Spacing.s) {
                Image(systemName: "clock")
                    .font(.system(size: 14))
                    .foregroundColor(AppTheme.Colors.textSecondary)
                Text(formatFullDateTime(story.timestamp!))
                    .font(AppTheme.Typography.caption)
                    .foregroundColor(AppTheme.Colors.textSecondary)
            }
            
            // 分类
            if let text = categoryNamesText, let iconName = categoryIconName() {
                HStack(spacing: AppTheme.Spacing.s) {
                    Group {
                        if isSystemSymbol(name: iconName) {
                            // SF Symbols
                            Image(systemName: iconName)
                                .font(.system(size: 14))
                        } else {
                            // Assets 自定义图标
                            Image(iconName)
                                .resizable()
                                .scaledToFit()
                                .frame(width: 16, height: 16)
                        }
                    }
                    .foregroundColor(AppTheme.Colors.primary)
                    Text(text)
                        .font(AppTheme.Typography.caption)
                        .foregroundColor(AppTheme.Colors.textSecondary)
                }
                .onTapGesture {
                    if let node = categoryNode() {
                        onCategoryTap?(node)
                    }
                }
            }
            
            // 位置
            if let city = story.locationCity, !city.isEmpty {
                HStack(spacing: AppTheme.Spacing.s) {
                    Image("address")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 16, height: 16)
                        .foregroundColor(AppTheme.Colors.primary)
                    Text(city)
                        .font(AppTheme.Typography.caption)
                        .foregroundColor(AppTheme.Colors.textSecondary)
                }
            }
        }
        .padding(.horizontal, AppTheme.Spacing.l)
        .padding(.vertical, AppTheme.Spacing.m)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(AppTheme.Colors.surface.opacity(0.5))
        .cornerRadius(AppTheme.Radius.m)
        .padding(.horizontal, AppTheme.Spacing.l)
        .padding(.bottom, AppTheme.Spacing.xl)
    }
    

    

    
    private var imageGalleryViewer: some View {
        ImageGalleryViewer(
            images: loadAllImages(),
            initialIndex: selectedImageIndex,
            isPresented: $showImageViewer
        )
    }
    
    // MARK: - Media Display Section
    @ViewBuilder
    private var mediaDisplaySection: some View {
        VStack(spacing: 0) {
            if !imageMediaList.isEmpty {
                imageGallerySection
            }
            
            if !videoMediaList.isEmpty {
                videoSection
                    .padding(.top, imageMediaList.isEmpty ? 0 : 16)
            }
        }
        .frame(height: UIScreen.main.bounds.height * 0.6)
        .frame(maxWidth: .infinity)
        .clipped()
    }
    
    // MARK: - Image Gallery Section
    @ViewBuilder
    private var imageGallerySection: some View {
        if imageMediaList.count == 1 {
            singleImageView(media: imageMediaList[0], index: 0)
        } else {
            multipleImagesView
        }
    }
    
    private var multipleImagesView: some View {
        TabView {
            ForEach(Array(imageMediaList.enumerated()), id: \.element.id) { index, media in
                singleImageView(media: media, index: index)
            }
        }
        .tabViewStyle(.page(indexDisplayMode: .always))
        .indexViewStyle(.page(backgroundDisplayMode: .always))
    }
    
    @ViewBuilder
    private func singleImageView(media: MediaEntity, index: Int) -> some View {
        if let img = mediaService.loadImage(fileName: media.fileName ?? "") {
            Button {
                openImageViewer(at: index)
            } label: {
                GeometryReader { geometry in
                    Image(uiImage: img)
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .frame(width: geometry.size.width, height: geometry.size.height)
                        .clipped()
                }
            }
            .buttonStyle(PlainButtonStyle())
        }
    }
    
    // MARK: - Video Section
    @ViewBuilder
    private var videoSection: some View {
        VStack(spacing: AppTheme.Spacing.m) {
            ForEach(Array(videoMediaList.enumerated()), id: \.element.id) { index, media in
                videoPlayerView(media: media, index: index)
            }
        }
    }
    
    @ViewBuilder
    private func videoPlayerView(media: MediaEntity, index: Int) -> some View {
        if playingVideoIndex == index, let player = videoPlayers[index] {
            activeVideoPlayer(player: player)
        } else {
            videoThumbnailView(media: media, index: index)
        }
    }
    
    private func activeVideoPlayer(player: AVPlayer) -> some View {
        VideoPlayer(player: player)
            .frame(maxWidth: .infinity)
            .aspectRatio(contentMode: .fit)
    }
    
    @ViewBuilder
    private func videoThumbnailView(media: MediaEntity, index: Int) -> some View {
        if let thumbFileName = media.thumbnailFileName,
           let img = mediaService.loadVideoThumbnail(fileName: thumbFileName) {
            Button {
                playVideo(fileName: media.fileName ?? "", at: index)
            } label: {
                videoThumbnailContent(image: img)
            }
            .buttonStyle(PlainButtonStyle())
        }
    }
    
    private func videoThumbnailContent(image: UIImage) -> some View {
        ZStack(alignment: .center) {
            GeometryReader { geometry in
                Image(uiImage: image)
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .frame(width: geometry.size.width, height: geometry.size.height)
                    .clipped()
            }
            
            playButtonOverlay
        }
    }
    
    private var playButtonOverlay: some View {
        ZStack {
            Circle()
                .fill(Color.black.opacity(0.6))
                .frame(width: 80, height: 80)
            Image(systemName: "play.fill")
                .font(.system(size: 40))
                .foregroundColor(.white)
        }
    }
    
    // MARK: - Helper Methods
    private func loadAllImages() -> [UIImage] {
        imageMediaList.compactMap { media in
            mediaService.loadImage(fileName: media.fileName ?? "")
        }
    }
    
    private func openImageViewer(at index: Int) {
        selectedImageIndex = index
        showImageViewer = true
    }
    
    private func playVideo(fileName: String, at index: Int) {
        stopAllVideos()
        
        guard let url = mediaService.loadVideoURL(fileName: fileName) else { return }
        
        let player = AVPlayer(url: url)
        videoPlayers[index] = player
        playingVideoIndex = index
        player.play()
    }
    
    private func stopVideo(at index: Int) {
        videoPlayers[index]?.pause()
        videoPlayers[index] = nil
        playingVideoIndex = nil
    }
    
    private func stopAllVideos() {
        for (_, player) in videoPlayers {
            player.pause()
        }
        videoPlayers.removeAll()
        playingVideoIndex = nil
    }
    
    private func cleanupResources() {
        stopAllVideos()
    }
    
    // MARK: - Date Formatting
    
    /// 格式化日期数字（日）
    private func formatDayNumber(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "dd"
        return formatter.string(from: date)
    }
    
    /// 格式化年月和星期
    private func formatYearMonthWeekday(_ date: Date) -> String {
        let formatter = DateFormatter()
        
        let isChineseLocale = LocalizationManager.shared.currentLanguage == .chinese
        formatter.locale = Locale(identifier: isChineseLocale ? "zh-Hans" : "en")
        
        if isChineseLocale {
            formatter.dateFormat = "MM月 / E"
        } else {
            formatter.dateFormat = "MMM / EEE"
        }
        
        return formatter.string(from: date)
    }
    
    /// 格式化时间
    private func formatTime(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm"
        return formatter.string(from: date)
    }
    
    /// 格式化完整日期时间（小红书风格）
    private func formatFullDateTime(_ date: Date) -> String {
        let formatter = DateFormatter()
        let isChineseLocale = LocalizationManager.shared.currentLanguage == .chinese
        formatter.locale = Locale(identifier: isChineseLocale ? "zh-Hans" : "en")
        
        if isChineseLocale {
            formatter.dateFormat = "yyyy年MM月dd日 HH:mm"
        } else {
            formatter.dateFormat = "MMM dd, yyyy HH:mm"
        }
        
        return formatter.string(from: date)
    }
}

// MARK: - Image Gallery Viewer
struct ImageGalleryViewer: View {
    let images: [UIImage]
    let initialIndex: Int
    @Binding var isPresented: Bool
    @State private var currentIndex: Int
    @State private var scale: CGFloat = 1.0
    @State private var lastScale: CGFloat = 1.0
    @State private var offset: CGSize = .zero
    @State private var lastOffset: CGSize = .zero
    
    init(images: [UIImage], initialIndex: Int, isPresented: Binding<Bool>) {
        self.images = images
        self.initialIndex = initialIndex
        self._isPresented = isPresented
        self._currentIndex = State(initialValue: initialIndex)
    }
    
    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()
            
            TabView(selection: $currentIndex) {
                ForEach(Array(images.enumerated()), id: \.offset) { index, image in
                    zoomableImageView(image: image, index: index)
                        .tag(index)
                }
            }
            .tabViewStyle(.page(indexDisplayMode: .never))
            .ignoresSafeArea()
            
            VStack {
                HStack {
                    Spacer()
                    Button {
                        isPresented = false
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .font(.system(size: 32))
                            .foregroundColor(.white)
                            .shadow(radius: 4)
                    }
                    .padding()
                }
                Spacer()
                
                if images.count > 1 {
                    Text("\(currentIndex + 1) / \(images.count)")
                        .font(.subheadline)
                        .foregroundColor(.white)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(Color.black.opacity(0.6))
                        .cornerRadius(AppTheme.Radius.l)
                        .padding(.bottom, 20)
                }
            }
        }
    }
    
    @ViewBuilder
    private func zoomableImageView(image: UIImage, index: Int) -> some View {
        ZoomableImageView(
            image: image,
            isCurrentImage: index == currentIndex,
            onDismiss: { isPresented = false }
        )
    }
}

// MARK: - Zoomable Image View Component
struct ZoomableImageView: View {
    let image: UIImage
    let isCurrentImage: Bool
    let onDismiss: () -> Void
    
    @State private var scale: CGFloat = 1.0
    @State private var lastScale: CGFloat = 1.0
    @State private var offset: CGSize = .zero
    @State private var lastOffset: CGSize = .zero
    
    var body: some View {
        GeometryReader { geometry in
            Image(uiImage: image)
                .resizable()
                .scaledToFit()
                .frame(width: geometry.size.width, height: geometry.size.height)
                .scaleEffect(scale)
                .offset(offset)
                .gesture(
                    MagnificationGesture()
                        .onChanged { value in
                            let delta = value / lastScale
                            lastScale = value
                            scale = min(max(scale * delta, 1.0), 5.0)
                        }
                        .onEnded { _ in
                            lastScale = 1.0
                            if scale < 1.0 {
                                withAnimation {
                                    scale = 1.0
                                    offset = .zero
                                }
                            }
                        }
                )
                .highPriorityGesture(
                    // 只在放大时启用拖动手势，避免与 TabView 的滑动冲突
                    scale > 1.0 ? DragGesture()
                        .onChanged { value in
                            offset = CGSize(
                                width: lastOffset.width + value.translation.width,
                                height: lastOffset.height + value.translation.height
                            )
                        }
                        .onEnded { _ in
                            lastOffset = offset
                        } : nil
                )
                .onTapGesture(count: 2) {
                    withAnimation {
                        if scale > 1.0 {
                            scale = 1.0
                            offset = .zero
                            lastOffset = .zero
                        } else {
                            scale = 2.0
                        }
                    }
                }
                .onTapGesture(count: 1) {
                    // 单击图片退出全屏预览
                    onDismiss()
                }
        }
        .onChange(of: isCurrentImage) { newValue in
            // 切换图片时重置缩放状态
            if !newValue {
                scale = 1.0
                offset = .zero
                lastOffset = .zero
            }
        }
    }
}
