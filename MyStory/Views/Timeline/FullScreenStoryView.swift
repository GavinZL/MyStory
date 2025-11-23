import SwiftUI
import UIKit
import AVKit

struct FullScreenStoryView: View {
    let stories: [StoryEntity]
    let initialIndex: Int
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        ZStack(alignment: .topTrailing) {
            FullScreenPager(stories: stories, initialIndex: initialIndex)
                .ignoresSafeArea()
            
            Button {
                dismiss()
            } label: {
                Image(systemName: "xmark.circle.fill")
                    .font(.system(size: 32))
                    .foregroundColor(.white)
                    .shadow(radius: 4)
            }
            .padding()
        }
    }
}

private struct FullScreenPager: UIViewControllerRepresentable {
    let stories: [StoryEntity]
    let initialIndex: Int

    func makeUIViewController(context: Context) -> UIPageViewController {
        let pvc = UIPageViewController(transitionStyle: .scroll, navigationOrientation: .vertical, options: nil)
        pvc.dataSource = context.coordinator
        pvc.delegate = context.coordinator
        
        // 使用 Coordinator 中的 controllers
        let controllers = context.coordinator.controllers
        if initialIndex < controllers.count {
            pvc.setViewControllers([controllers[initialIndex]], direction: .forward, animated: false)
        } else if let first = controllers.first {
            pvc.setViewControllers([first], direction: .forward, animated: false)
        }
        return pvc
    }

    func updateUIViewController(_ uiViewController: UIPageViewController, context: Context) {}

    func makeCoordinator() -> Coordinator { Coordinator(stories: stories) }

    final class Coordinator: NSObject, UIPageViewControllerDataSource, UIPageViewControllerDelegate {
        let controllers: [UIViewController]

        init(stories: [StoryEntity]) {
            self.controllers = stories.map { story in
                UIHostingController(rootView: StoryDetailView(story: story))
            }
            super.init()
        }

        func pageViewController(_ pageViewController: UIPageViewController, viewControllerBefore viewController: UIViewController) -> UIViewController? {
            guard let idx = controllers.firstIndex(of: viewController), idx > 0 else { return nil }
            return controllers[idx - 1]
        }

        func pageViewController(_ pageViewController: UIPageViewController, viewControllerAfter viewController: UIViewController) -> UIViewController? {
            guard let idx = controllers.firstIndex(of: viewController), idx < controllers.count - 1 else { return nil }
            return controllers[idx + 1]
        }
    }
}

struct StoryDetailView: View {
    let story: StoryEntity
    @State private var showImageViewer = false
    @State private var selectedImageIndex = 0
    @State private var playingVideoIndex: Int?
    @State private var videoPlayers: [Int: AVPlayer] = [:]
    private let mediaService = MediaStorageService()

    private var mediaList: [MediaEntity] {
        guard let medias = story.medias as? Set<MediaEntity> else { return [] }
        return medias.sorted { ($0.createdAt ?? Date()) < ($1.createdAt ?? Date()) }
    }
    
    private var imageMediaList: [MediaEntity] {
        mediaList.filter { $0.type == "image" }
    }
    
    private var videoMediaList: [MediaEntity] {
        mediaList.filter { $0.type == "video" }
    }

    var body: some View {
        GeometryReader { geometry in
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    // 媒体展示区域
                    if !mediaList.isEmpty {
                        mediaDisplaySection
                    }

                    // 标题
                    Text(story.title ?? "无标题")
                        .font(.title)
                        .bold()
                        .padding(.horizontal)

                    // 正文内容
                    if let content = story.content, !content.isEmpty {
                        ScrollView {
                            Text(content)
                                .font(.body)
                                .padding(.horizontal)
                        }
                        .frame(maxHeight: geometry.size.height * 0.3)
                    }

                    // 位置信息
                    if let city = story.locationCity, !city.isEmpty {
                        HStack(spacing: 8) {
                            Image(systemName: "mappin.circle.fill").foregroundColor(.blue)
                            Text(city)
                        }
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .padding(.horizontal)
                    }
                    
                    Spacer()
                }
                .padding(.vertical)
                .frame(minHeight: geometry.size.height)
            }
            .scrollDisabled(true)
        }
        .fullScreenCover(isPresented: $showImageViewer) {
            ImageGalleryViewer(
                images: loadAllImages(),
                initialIndex: selectedImageIndex,
                isPresented: $showImageViewer
            )
        }
        .onDisappear {
            // 清理所有视频播放器
            stopAllVideos()
        }
    }
    
    // MARK: - Media Display Section
    @ViewBuilder
    private var mediaDisplaySection: some View {
        VStack(spacing: 0) {
            // 图片区域
            if !imageMediaList.isEmpty {
                imageGallerySection
            }
            
            // 视频区域
            if !videoMediaList.isEmpty {
                videoSection
                    .padding(.top, imageMediaList.isEmpty ? 0 : 16)
            }
        }.frame(height: UIScreen.main.bounds.height / 2)
    }
    
    // MARK: - Image Gallery Section
    @ViewBuilder
    private var imageGallerySection: some View {
        if imageMediaList.count == 1 {
            // 单张图片
            singleImageView(media: imageMediaList[0], index: 0)
        } else {
            // 多张图片 - 横向滑动
            TabView {
                ForEach(Array(imageMediaList.enumerated()), id: \.element.id) { index, media in
                    singleImageView(media: media, index: index)
                }
            }
            .tabViewStyle(.page(indexDisplayMode: .always))
            .frame(height: UIScreen.main.bounds.height * 0.5)
            .indexViewStyle(.page(backgroundDisplayMode: .always))
        }
    }
    
    @ViewBuilder
    private func singleImageView(media: MediaEntity, index: Int) -> some View {
        if let img = mediaService.loadImage(fileName: media.fileName ?? "") {
            Button {
                selectedImageIndex = index
                showImageViewer = true
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
        VStack(spacing: 12) {
            ForEach(Array(videoMediaList.enumerated()), id: \.element.id) { index, media in
                videoPlayerView(media: media, index: index)
            }
        }
        .padding(.horizontal)
    }
    
    @ViewBuilder
    private func videoPlayerView(media: MediaEntity, index: Int) -> some View {
        if playingVideoIndex == index, let player = videoPlayers[index] {
            // 正在播放状态
            VideoPlayer(player: player)
                .frame(maxWidth: .infinity)
                .aspectRatio(contentMode: .fit)
                .cornerRadius(8)
        } else {
            // 未播放状态 - 显示缩略图
            videoThumbnailView(media: media, index: index)
        }
    }
    
    @ViewBuilder
    private func videoThumbnailView(media: MediaEntity, index: Int) -> some View {
        if let thumbFileName = media.thumbnailFileName,
           let img = mediaService.loadVideoThumbnail(fileName: thumbFileName) {
            Button {
                playVideo(fileName: media.fileName ?? "", at: index)
            } label: {
                ZStack(alignment: .center) {
                    Image(uiImage: img)
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(maxWidth: .infinity)
                        .cornerRadius(8)
                    
                    Circle()
                        .fill(Color.black.opacity(0.6))
                        .frame(width: 80, height: 80)
                    Image(systemName: "play.fill")
                        .font(.system(size: 40))
                        .foregroundColor(.white)
                }
            }
            .buttonStyle(PlainButtonStyle())
        }
    }
    
    // MARK: - Helper Methods
    private func loadAllImages() -> [UIImage] {
        imageMediaList.compactMap { media in
            mediaService.loadImage(fileName: media.fileName ?? "")
        }
    }
    
    private func playVideo(fileName: String, at index: Int) {
        // 停止其他正在播放的视频
        stopAllVideos()
        
        // 加载并播放新视频
        if let url = mediaService.loadVideoURL(fileName: fileName) {
            let player = AVPlayer(url: url)
            videoPlayers[index] = player
            playingVideoIndex = index
            player.play()
        }
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
                        .cornerRadius(16)
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
