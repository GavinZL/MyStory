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
    @State private var showTopToast = false
    @State private var showBottomToast = false
    @State private var topToastMessage = ""
    @State private var bottomToastMessage = ""
    
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
            
            // 顶部提示
            if showTopToast {
                topToastView
            }
            
            // 底部提示
            if showBottomToast {
                bottomToastView
            }
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
    
    private var topToastView: some View {
        VStack {
            Text(topToastMessage)
                .font(.subheadline)
                .foregroundColor(.white)
                .padding(.horizontal, 20)
                .padding(.vertical, AppTheme.Spacing.m)
                .background(
                    Capsule()
                        .fill(Color.black.opacity(0.7))
                )
                .padding(.top, 10)
            Spacer()
        }
        .transition(.move(edge: .top).combined(with: .opacity))
        .animation(.easeInOut(duration: 0.3), value: showTopToast)
    }
    
    private var bottomToastView: some View {
        VStack {
            Spacer()
            Text(bottomToastMessage)
                .font(.subheadline)
                .foregroundColor(.white)
                .padding(.horizontal, 20)
                .padding(.vertical, AppTheme.Spacing.m)
                .background(
                    Capsule()
                        .fill(Color.black.opacity(0.7))
                )
                .padding(.bottom, 50)
        }
        .transition(.move(edge: .bottom).combined(with: .opacity))
        .animation(.easeInOut(duration: 0.3), value: showBottomToast)
    }
    
    // MARK: - Helper Methods
    private func handleBoundaryReached(_ boundaryType: PageCoordinator.BoundaryType) {
        switch boundaryType {
        case .top:
            // 第一个往上滑，加载更早的数据
            handleLoadEarlierData()
        case .bottom:
            // 最后一个往下滑，加载更新的数据
            handleLoadNewerData()
        }
    }
    
    private func handleLoadEarlierData() {
        if hasMoreData {
            onLoadMore?()
            showTopToast("fullscreen.loadingEarlier".localized)
        } else {
            showTopToast("fullscreen.noMoreNewer".localized)
        }
    }
    
    private func handleLoadNewerData() {
        if hasMoreData {
            onLoadMore?()
            showBottomToast("fullscreen.loadingNewer".localized)
        } else {
            showBottomToast("fullscreen.noMoreEarlier".localized)
        }
    }
    
    private func showTopToast(_ message: String) {
        topToastMessage = message
        withAnimation {
            showTopToast = true
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
            withAnimation {
                showTopToast = false
            }
        }
    }
    
    private func showBottomToast(_ message: String) {
        bottomToastMessage = message
        withAnimation {
            showBottomToast = true
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
            withAnimation {
                showBottomToast = false
            }
        }
    }
}

// MARK: - Page Coordinator
class PageCoordinator: NSObject, ObservableObject, UIPageViewControllerDataSource, UIPageViewControllerDelegate {
    let controllers: [UIViewController]
    @Published var currentIndex: Int
    var onReachBoundary: ((BoundaryType) -> Void)?
    
    enum BoundaryType {
        case top    // 第一个往上滑，加载更早的数据
        case bottom // 最后一个往下滑，加载更新的数据
    }
    
    init(stories: [StoryEntity], initialIndex: Int) {
        self.controllers = stories.map { story in
            UIHostingController(rootView: StoryDetailView(story: story))
        }
        self.currentIndex = initialIndex
        super.init()
    }
    
    func pageViewController(_ pageViewController: UIPageViewController, viewControllerBefore viewController: UIViewController) -> UIViewController? {
        guard let idx = controllers.firstIndex(of: viewController), idx > 0 else {
            // 已经是第一个，尝试向上滑动时触发加载更早的数据
            if let index = controllers.firstIndex(of: viewController), index == 0 {
                onReachBoundary?(.top)
            }
            return nil
        }
        return controllers[idx - 1]
    }
    
    func pageViewController(_ pageViewController: UIPageViewController, viewControllerAfter viewController: UIViewController) -> UIViewController? {
        guard let idx = controllers.firstIndex(of: viewController), idx < controllers.count - 1 else {
            // 已经是最后一个，尝试向下滑动时触发加载更新的数据
            if let index = controllers.firstIndex(of: viewController), index == controllers.count - 1 {
                onReachBoundary?(.bottom)
            }
            return nil
        }
        return controllers[idx + 1]
    }
    
    func pageViewController(_ pageViewController: UIPageViewController, didFinishAnimating finished: Bool, previousViewControllers: [UIViewController], transitionCompleted completed: Bool) {
        guard completed,
              let visibleViewController = pageViewController.viewControllers?.first,
              let index = controllers.firstIndex(of: visibleViewController) else { return }
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
            navigationOrientation: .vertical,
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
    
    // MARK: - State
    @State private var showImageViewer = false
    @State private var selectedImageIndex = 0
    @State private var playingVideoIndex: Int?
    @State private var videoPlayers: [Int: AVPlayer] = [:]
    
    // MARK: - Services
    private let mediaService = MediaStorageService()
    
    // MARK: - Computed Properties
    private var mediaList: [MediaEntity] {
        guard let medias = story.media as? Set<MediaEntity> else { return [] }
        return medias.sorted { ($0.createdAt ?? Date()) < ($1.createdAt ?? Date()) }
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
                contentContainer(geometry: geometry)
            }
            .scrollDisabled(true)
        }
        .fullScreenCover(isPresented: $showImageViewer) {
            imageGalleryViewer
        }
        .onDisappear {
            cleanupResources()
        }
    }
    
    // MARK: - View Components
    @ViewBuilder
    private func contentContainer(geometry: GeometryProxy) -> some View {
        VStack(alignment: .leading, spacing: AppTheme.Spacing.l) {
            if !mediaList.isEmpty {
                mediaDisplaySection
            }
            titleSection
            contentSection(geometry: geometry)
            locationSection
            Spacer()
        }
        .padding(.vertical)
        .frame(minHeight: geometry.size.height)
    }
    
    private var titleSection: some View {
        Text(story.title ?? "无标题")
            .font(.title)
            .bold()
            .padding(.horizontal)
    }
    
    @ViewBuilder
    private func contentSection(geometry: GeometryProxy) -> some View {
        if let content = story.content, !content.isEmpty {
            ScrollView {
                Text(content)
                    .font(.body)
                    .padding(.horizontal)
            }
            .frame(maxHeight: geometry.size.height * 0.3)
        }
    }
    
    @ViewBuilder
    private var locationSection: some View {
        if let city = story.locationCity, !city.isEmpty {
            HStack(spacing: 8) {
                Image(systemName: "mappin.circle.fill")
                    .foregroundColor(AppTheme.Colors.primary)
                Text(city)
            }
            .font(.subheadline)
            .foregroundColor(.secondary)
            .padding(.horizontal)
        }
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
        .frame(height: UIScreen.main.bounds.height / 2)
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
        .frame(height: UIScreen.main.bounds.height * 0.5)
        .indexViewStyle(.page(backgroundDisplayMode: .always))
    }
    
    @ViewBuilder
    private func singleImageView(media: MediaEntity, index: Int) -> some View {
        if let img = mediaService.loadImage(fileName: media.fileName ?? "") {
            Button {
                openImageViewer(at: index)
            } label: {
                Image(uiImage: img)
                    .resizable()
                    .scaledToFit()
                    .frame(maxWidth: .infinity)
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
        .padding(.horizontal)
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
            .cornerRadius(AppTheme.Radius.s)
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
            Image(uiImage: image)
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(maxWidth: .infinity)
                .cornerRadius(AppTheme.Radius.s)
            
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
                    zoomableImageView(image: image)
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
    private func zoomableImageView(image: UIImage) -> some View {
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
                .simultaneousGesture(
                    DragGesture()
                        .onChanged { value in
                            if scale > 1.0 {
                                offset = CGSize(
                                    width: lastOffset.width + value.translation.width,
                                    height: lastOffset.height + value.translation.height
                                )
                            }
                        }
                        .onEnded { _ in
                            lastOffset = offset
                        }
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
        }
    }
}
