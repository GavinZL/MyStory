import SwiftUI
import AVKit

struct VideoPlayerView: View {
    let videoURL: URL?
    @State private var player: AVPlayer?
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()
            
            if let player = player {
                VideoPlayer(player: player)
                    .ignoresSafeArea()
            } else {
                ProgressView()
                    .tint(.white)
            }
            
            VStack {
                HStack {
                    Spacer()
                    Button {
                        player?.pause()
                        dismiss()
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .font(.system(size: 32))
                            .foregroundColor(.white)
                            .shadow(radius: AppTheme.Shadow.small.radius)
                    }
                    .padding()
                }
                Spacer()
            }
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
            player?.pause()
            player = nil
        }
    }
}
