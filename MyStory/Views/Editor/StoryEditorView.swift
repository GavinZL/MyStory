import SwiftUI
import PhotosUI

struct StoryEditorView: View {
    let existingStory: StoryEntity?
    let onSaveComplete: (() -> Void)?

    init(existingStory: StoryEntity? = nil, onSaveComplete: (() -> Void)? = nil) {
        self.existingStory = existingStory
        self.onSaveComplete = onSaveComplete
        if let s = existingStory {
            _title = State(initialValue: s.title)
            _content = State(initialValue: s.content ?? "")
            if let city = s.locationCity,
               let lat = s.latitude?.doubleValue,
               let lng = s.longitude?.doubleValue {
                _locationInfo = State(initialValue: LocationInfo(latitude: lat, longitude: lng, name: s.locationName, address: nil, city: city, country: nil))
            }
            // 加载已有图片
            if let medias = s.medias {
                let mediaService = MediaStorageService()
                let loadedImages = medias.compactMap { media -> UIImage? in
                    return mediaService.loadImage(fileName: media.fileName)
                }
                _images = State(initialValue: loadedImages)
            }
        }
    }
    @Environment(\.managedObjectContext) private var context
    @EnvironmentObject private var coreData: CoreDataStack
    @Environment(\.dismiss) private var dismiss

    @State private var title: String = ""
    @State private var content: String = ""
    @State private var mediaItems: [PhotosPickerItem] = []
    @State private var images: [UIImage] = []
    @State private var videoURLs: [URL] = []
    @State private var isSaving = false
    
    // 计算当前允许的媒体类型
    private var allowedMediaFilter: PHPickerFilter {
        if !videoURLs.isEmpty {
            return .videos  // 已有视频，只允许选择视频
        } else if !images.isEmpty {
            return .images  // 已有图片，只允许选择图片
        } else {
            return .any(of: [.images, .videos])  // 都没有，允许选择任意类型
        }
    }

    @State private var locationInfo: LocationInfo?
    @State private var locationService = LocationService()
    @State private var mediaService = MediaStorageService()

    private var isEditing: Bool { false/*existingStory != nil*/ }
    
        var body: some View {
        NavigationView {
            Form {
                Section(header: Text("标题")) {
                    TextField("请输入故事标题", text: $title)
                }

                Section(header: Text("内容")) {
                    TextEditor(text: $content)
                        .frame(minHeight: 150)
                }

                Section(header: Text("媒体")) {
                    if !isEditing {
                        PhotosPicker(
                            selection: $mediaItems,
                            maxSelectionCount: 9,
                            matching: allowedMediaFilter
                        ) {
                            Label("添加图片/视频", systemImage: "photo.on.rectangle")
                        }
                        .onChange(of: mediaItems) { items in
                            guard !items.isEmpty else { return }
                            
                            Task {
                                for item in items {
                                    // 尝试加载为图片
                                    if let data = try? await item.loadTransferable(type: Data.self),
                                       let img = UIImage(data: data) {
                                        images.append(img)
                                    }
                                    // 尝试加载为视频
                                    else if let movie = try? await item.loadTransferable(type: VideoTransferable.self) {
                                        videoURLs.append(movie.url)
                                    }
                                }
                                
                                // 处理完毕后清空选择器
                                mediaItems.removeAll()
                            }
                        }
                    }

                    if !images.isEmpty {
                        let columns = [
                            GridItem(.flexible(), spacing: 8),
                            GridItem(.flexible(), spacing: 8),
                            GridItem(.flexible(), spacing: 8)
                        ]
                        LazyVGrid(columns: columns, spacing: 8) {
                            ForEach(Array(images.enumerated()), id: \.offset) { index, img in
                                ZStack(alignment: .topTrailing) {
                                    Image(uiImage: img)
                                        .resizable()
                                        .scaledToFill()
                                        .frame(width: (UIScreen.main.bounds.width - 64) / 3, height: (UIScreen.main.bounds.width - 64) / 3)
                                        .clipped()
                                        .cornerRadius(8)
                                    
                                    if !isEditing {
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
                            }
                        }
                        .padding(.vertical, 4)
                    } else if isEditing {
                        Text("暂无图片")
                            .foregroundColor(.secondary)
                    }
                    
                    // 视频展示
                    if !videoURLs.isEmpty {
                        VStack(alignment: .leading, spacing: 8) {
                            ForEach(Array(videoURLs.enumerated()), id: \.offset) { index, url in
                                HStack {
                                    Image(systemName: "play.rectangle.fill")
                                        .foregroundColor(.blue)
                                    Text("视频 \(index + 1)")
                                        .font(.subheadline)
                                    Spacer()
                                    if !isEditing {
                                        Button {
                                            videoURLs.remove(at: index)
                                        } label: {
                                            Image(systemName: "xmark.circle.fill")
                                                .foregroundColor(.secondary)
                                        }
                                    }
                                }
                                .padding(.vertical, 4)
                            }
                        }
                    }
                }

                Section(header: Text("位置")) {
                    if locationInfo != nil {
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
                    } else {
                        Button {
                            locationService.requestCurrentLocation { info in
                                self.locationInfo = info
                            }
                        } label: {
                            Label("添加位置", systemImage: "mappin.circle")
                        }
                    }
                }
            }
            .navigationTitle(isEditing ? "编辑故事" : "新建故事")
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("取消") { dismiss() }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: save) {
                        if isSaving { ProgressView() } else { Text("保存") }
                    }.disabled(title.isEmpty && content.isEmpty)
                }
            }
        }
    }

    private var locationInfoText: String {
        if let info = locationInfo {
            return info.city ?? info.name ?? "已选择位置"
        }
        return "添加位置"
    }

    private func save() {
        guard !isSaving else { return }
        isSaving = true

        let now = Date()
        let story: StoryEntity
        if let existing = existingStory {
            story = existing
            story.updatedAt = now
        } else {
            story = StoryEntity(context: context)
            story.id = UUID()
            story.createdAt = now
            story.timestamp = now
            story.updatedAt = now
        }

        story.title = title
        story.content = content.isEmpty ? nil : content
        if let info = locationInfo {
            story.locationName = info.name
            story.locationCity = info.city
            story.latitude = NSNumber(value: info.latitude)
            story.longitude = NSNumber(value: info.longitude)
        }

        if existingStory == nil {
            // 保存图片
            for img in images {
                do {
                    let res = try mediaService.saveImageWithThumbnail(img)
                    let media = MediaEntity(context: context)
                    media.id = UUID()
                    media.type = "image"
                    media.fileName = res.fileName
                    media.thumbnailFileName = res.thumbFileName
                    media.createdAt = now
                    media.story = story
                } catch {
                    print("保存图片失败: \(error)")
                }
            }
            
            // 保存视频
            for videoURL in videoURLs {
                do {
                    let res = try mediaService.saveVideo(from: videoURL)
                    let media = MediaEntity(context: context)
                    media.id = UUID()
                    media.type = "video"
                    media.fileName = res.fileName
                    media.thumbnailFileName = res.thumbFileName
                    media.createdAt = now
                    media.story = story
                } catch {
                    print("保存视频失败: \(error)")
                }
            }
        }

        coreData.save()
        isSaving = false
        onSaveComplete?()
        dismiss()
    }
}
