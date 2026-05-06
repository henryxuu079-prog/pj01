import SwiftUI
import SwiftData

struct RecordDetailView: View {
    let record: TravelRecord

    @Environment(\.modelContext) private var modelContext
    @State private var displayMode: DisplayMode = .grid
    @State private var selectedPhoto: PhotoItem?
    @State private var showPosterEditor = false
    @State private var showRecordEditor = false
    @State private var showPhotoDetail = false
    @State private var detailPhoto: PhotoItem?
    @State private var showShareSheet = false
    @State private var sharePhoto: PhotoItem?

    enum DisplayMode: String {
        case grid, poster
    }

    var body: some View {
        VStack(spacing: 0) {
            // Header
            VStack(alignment: .leading, spacing: 4) {
                HStack(alignment: .firstTextBaseline) {
                    Text(record.title)
                        .font(.title2.bold())
                    Spacer()
                    // Mode toggle buttons
                    HStack(spacing: 0) {
                        modeButton(.grid, icon: "square.grid.2x2", label: "常规")
                        modeButton(.poster, icon: "rectangle.portrait.on.rectangle.portrait", label: "海报")
                    }
                    .background(.quaternary.opacity(0.5))
                    .clipShape(RoundedRectangle(cornerRadius: 8))
                }
                if let desc = record.recordDescription {
                    Text(desc)
                        .font(.body)
                        .foregroundStyle(.secondary)
                }
                if let location = record.locationName {
                    Label(location, systemImage: "mappin.and.ellipse")
                        .font(.caption)
                        .foregroundStyle(.tertiary)
                }
            }
            .padding(.horizontal)
            .padding(.top, 8)

            // Content
            if record.photos.isEmpty {
                ContentUnavailableView(
                    "没有照片",
                    systemImage: "photo.on.rectangle.angled",
                    description: Text("点击右上角铅笔图标添加照片")
                )
            } else {
                switch displayMode {
                case .grid:
                    photoGridView
                        .transition(.opacity.combined(with: .scale(scale: 0.95)))
                case .poster:
                    posterView
                        .transition(.opacity.combined(with: .scale(scale: 1.05)))
                }
            }
        }
        .animation(.spring(response: 0.35, dampingFraction: 0.85), value: displayMode)
        .navigationTitle("")
        #if os(iOS)
        .navigationBarTitleDisplayMode(.inline)
        #endif
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button {
                    showRecordEditor = true
                } label: {
                    Label("编辑记录", systemImage: "pencil")
                }
            }
        }
        .sheet(isPresented: $showPosterEditor) {
            if let photo = selectedPhoto {
                PosterStylePicker(photo: photo)
            }
        }
        .sheet(isPresented: $showRecordEditor) {
            RecordEditorView(existingRecord: record)
        }
        .sheet(isPresented: $showPhotoDetail) {
            if let photo = detailPhoto {
                PhotoDetailView(photo: photo)
            }
        }
        .sheet(isPresented: $showShareSheet) {
            if let photo = sharePhoto, let url = ShareService.shared.tempURL(for: photo) {
                #if os(iOS)
                ShareSheetView(items: [url])
                #endif
            }
        }
    }

    // MARK: - Mode Button

    private func modeButton(_ mode: DisplayMode, icon: String, label: String) -> some View {
        Button {
            withAnimation { displayMode = mode }
        } label: {
            HStack(spacing: 4) {
                Image(systemName: icon)
                    .font(.caption.weight(.medium))
                Text(label)
                    .font(.caption)
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 6)
            .background(displayMode == mode ? .blue : .clear)
            .foregroundStyle(displayMode == mode ? .white : .secondary)
        }
        .buttonStyle(.plain)
    }

    // MARK: - Grid Mode

    private var photoGridView: some View {
        ScrollView {
            LazyVGrid(columns: [GridItem(.adaptive(minimum: 100, maximum: 140), spacing: 4)], spacing: 4) {
                ForEach(record.photos) { photo in
                    ZStack(alignment: .topTrailing) {
                        gridThumbnail(for: photo)
                            .aspectRatio(1, contentMode: .fill)
                            .clipShape(Rectangle())
                            .contextMenu {
                                Button {
                                    detailPhoto = photo
                                    showPhotoDetail = true
                                } label: {
                                    Label("查看详情", systemImage: "info.circle")
                                }
                                Button {
                                    sharePhoto = photo
                                    #if os(macOS)
                                    ShareService.shared.showSharePicker(for: photo)
                                    #else
                                    showShareSheet = true
                                    #endif
                                } label: {
                                    Label("分享照片", systemImage: "square.and.arrow.up")
                                }
                                Button {
                                    detailPhoto = photo
                                    makePoster(photo)
                                } label: {
                                    Label(photo.isPoster ? "编辑海报" : "设为海报", systemImage: "rectangle.portrait.on.rectangle.portrait")
                                }
                                Button(role: .destructive) {
                                    deletePhoto(photo)
                                } label: {
                                    Label("删除照片", systemImage: "trash")
                                }
                            }

                        // Tappable poster badge
                        Button {
                            if photo.isPoster {
                                photo.isPoster = false
                            } else {
                                makePoster(photo)
                            }
                        } label: {
                            Image(systemName: photo.isPoster ? "star.fill" : "star")
                                .font(.system(size: 10))
                                .foregroundStyle(photo.isPoster ? .yellow : .secondary.opacity(0.4))
                                .padding(4)
                                .background(.ultraThinMaterial)
                                .clipShape(Circle())
                        }
                        .padding(3)

                        // Delete overlay
                        Button {
                            deletePhoto(photo)
                        } label: {
                            Image(systemName: "xmark.circle.fill")
                                .font(.system(size: 16))
                                .foregroundStyle(.white, .black.opacity(0.3))
                        }
                        .padding(2)
                        .opacity(0.5)
                    }
                }
            }
            .padding(4)
        }
    }

    @ViewBuilder
    private func gridThumbnail(for photo: PhotoItem) -> some View {
        if let thumbPath = photo.thumbnailImagePath,
           let image = FileStorageManager.shared.loadImage(from: thumbPath) {
            image.resizable()
        } else {
            // No thumbnail yet — show placeholder, trigger generation
            Rectangle()
                .fill(.quaternary)
                .overlay {
                    Image(systemName: "photo")
                        .font(.caption)
                        .foregroundStyle(.tertiary)
                }
                .task {
                    if let thumbPath = try? FileStorageManager.shared.generateThumbnail(for: photo.originalImagePath) {
                        await MainActor.run { photo.thumbnailImagePath = thumbPath }
                    }
                }
        }
    }

    // MARK: - Poster Mode

    private var posterView: some View {
        let posterPhotos = record.photos.filter { $0.isPoster }
        let displayPhotos = posterPhotos.isEmpty ? record.photos : posterPhotos

        return ScrollView {
            VStack(spacing: 20) {
                if posterPhotos.isEmpty {
                    HStack {
                        Image(systemName: "info.circle")
                        Text("未标记海报，显示全部照片。点击照片上的 ☆ 设为海报")
                            .font(.caption)
                    }
                    .foregroundStyle(.secondary)
                    .padding(.horizontal)
                }

                ForEach(displayPhotos) { photo in
                    VStack(spacing: 4) {
                        PosterCanvasView(photo: photo)

                        // Edit button for poster
                        HStack(spacing: 12) {
                            Button {
                                makePoster(photo)
                            } label: {
                                Label("编辑文字", systemImage: "pencil")
                                    .font(.caption)
                            }
                            .buttonStyle(.bordered)

                            if !photo.isPoster {
                                Button {
                                    photo.isPoster = true
                                } label: {
                                    Label("设为海报", systemImage: "star")
                                        .font(.caption)
                                }
                                .buttonStyle(.bordered)
                            }

                            Button {
                                detailPhoto = photo
                                showPhotoDetail = true
                            } label: {
                                Label("详情", systemImage: "info.circle")
                                    .font(.caption)
                            }
                            .buttonStyle(.bordered)
                        }
                    }
                }
            }
            .padding(.vertical, 8)
        }
    }

    // MARK: - Actions

    private func makePoster(_ photo: PhotoItem) {
        selectedPhoto = photo
        showPosterEditor = true
    }

    private func deletePhoto(_ photo: PhotoItem) {
        try? FileStorageManager.shared.deleteFile(at: photo.originalImagePath)
        if let thumb = photo.thumbnailImagePath {
            try? FileStorageManager.shared.deleteFile(at: thumb)
        }
        modelContext.delete(photo)
    }
}

#Preview {
    NavigationStack {
        RecordDetailView(record: TravelRecord(title: "预览记录"))
    }
}
