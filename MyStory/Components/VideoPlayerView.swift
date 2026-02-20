import SwiftUI
import AVKit

struct VideoPlayerView: View {
    let videoURL: URL?
    @State private var player: AVPlayer?
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                Color.black.ignoresSafeArea()
                
                if let player = player {
                    // 使用 VideoPlayer 但禁用控件
                    VideoPlayer(player: player)
                        .ignoresSafeArea()
                        .disabled(true)  // 禁用 VideoPlayer 的手势响应
                        .allowsHitTesting(false)  // 不响应点击
                } else {
                    ProgressView()
                        .tint(.white)
                }
            }
            
            // 关闭按钮 - 放在左侧偏上位置，避免与 AVPlayer 控件和导航栏冲突
            Button {
                print("DEBUG: Close button tapped")
                player?.pause()
                dismiss()
            } label: {
                Image(systemName: "xmark.circle.fill")
                    .font(.system(size: 32))
                    .foregroundColor(.white)
                    .shadow(radius: AppTheme.Shadow.small.radius)
            }
            .padding(.top, 44)  // 向下偏移更多，避开可能的冲突区域
            .padding(.leading, AppTheme.Spacing.m)
            .allowsHitTesting(true)  // 确保按钮可以响应点击
        }
        .onAppear {
            if let url = videoURL {
                player = AVPlayer(url: url)
                player?.play()
            }else{
                print("url is null")
            }
        }
        .onDisappear {
            // 退出全屏时不暂停视频，让原视口继续播放
            // player?.pause()
            // player = nil
        }
    }
}
