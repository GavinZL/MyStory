import SwiftUI
import UIKit

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
        let controllers = pageControllers()
        if initialIndex < controllers.count {
            pvc.setViewControllers([controllers[initialIndex]], direction: .forward, animated: false)
        } else if let first = controllers.first {
            pvc.setViewControllers([first], direction: .forward, animated: false)
        }
        return pvc
    }

    func updateUIViewController(_ uiViewController: UIPageViewController, context: Context) {}

    func makeCoordinator() -> Coordinator { Coordinator(parent: self) }

    private func pageControllers() -> [UIViewController] {
        stories.map { story in
            let vc = UIHostingController(rootView: StoryDetailView(story: story))
            return vc
        }
    }

    final class Coordinator: NSObject, UIPageViewControllerDataSource, UIPageViewControllerDelegate {
        let parent: FullScreenPager
        private var controllers: [UIViewController]

        init(parent: FullScreenPager) {
            self.parent = parent
            self.controllers = parent.pageControllers()
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
    @State private var showVideoPlayer = false
    @State private var videoURL: URL?
    private let mediaService = MediaStorageService()

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                if let first = story.medias?.first {
                    if first.type == "video" {
                        // 视频封面，点击播放
                        if let img = mediaService.loadImage(fileName: first.thumbnailFileName ?? first.fileName) {
                            Button {
                                loadAndPlayVideo(fileName: first.fileName)
                            } label: {
                                ZStack(alignment: .center) {
                                    Image(uiImage: img)
                                        .resizable()
                                        .scaledToFit()
                                        .frame(maxWidth: .infinity)
                                    
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
                    } else {
                        // 图片直接展示
                        if let img = mediaService.loadImage(fileName: first.fileName) {
                            Image(uiImage: img)
                                .resizable()
                                .scaledToFit()
                                .frame(maxWidth: .infinity)
                        }
                    }
                }

                Text(story.title)
                    .font(.title)
                    .bold()

                if let content = story.content {
                    Text(content)
                        .font(.body)
                }

                if let city = story.locationCity {
                    HStack(spacing: 8) {
                        Image(systemName: "mappin.circle.fill").foregroundColor(.blue)
                        Text(city)
                    }
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                }
            }
            .padding()
        }
        .fullScreenCover(isPresented: $showVideoPlayer) {
            if let url = videoURL {
                VideoPlayerView(videoURL: url)
            }
        }
    }
    
    private func loadAndPlayVideo(fileName: String) {
        if let url = mediaService.loadVideoURL(fileName: fileName) {
            videoURL = url
            showVideoPlayer = true
        }
    }
}
