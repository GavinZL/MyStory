import SwiftUI

struct StoryCardView: View {
    let story: StoryEntity
    let firstImage: UIImage?
    
    private var firstMedia: MediaEntity? {
        story.medias?.first
    }
    
    private var isVideo: Bool {
        firstMedia?.type == "video"
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 24) {
            if let uiImg = firstImage {
                ZStack(alignment: .center) {
                    Image(uiImage: uiImg)
                        .resizable()
                        .scaledToFill()
                        .frame(maxWidth: .infinity)
                        .frame(height: 200)
                        .clipped()
                        .cornerRadius(8)
                    
                    if isVideo {
                        Circle()
                            .fill(Color.black.opacity(0.6))
                            .frame(width: 60, height: 60)
                        Image(systemName: "play.fill")
                            .font(.system(size: 28))
                            .foregroundColor(.white)
                    }
                }
            } else {
                RoundedRectangle(cornerRadius: 8)
                    .fill(Color.gray.opacity(0.15))
                    .frame(maxWidth: .infinity)
                    .frame(height: 200)
                    .overlay(
                        Image(systemName: "photo")
                            .font(.system(size: 28))
                            .foregroundColor(.gray)
                    )
            }

            Text(story.title)
                .font(.headline)
                .lineLimit(2)
                .foregroundColor(.primary)

            if let city = story.locationCity, !city.isEmpty {
                HStack(spacing: 6) {
                    Image(systemName: "mappin.circle.fill").foregroundColor(.blue)
                    Text(city)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .lineLimit(1)
                }
            }

            if let content = story.content, !content.isEmpty {
                Text(content)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .lineLimit(3)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 8)
                .stroke(Color.red, lineWidth: 2)
        )
    }

}
