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

    enum DisplayMode: String, CaseIterable {
        case grid = "常规"
        case poster = "海报"
    }

    var body: some View {
        VStack(spacing: 0) {
            // Header
            VStack(alignment: .leading, spacing: 4) {
                Text(record.title)
                    .font(.title2.bold())
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
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal)
            .padding(.top, 8)

            // Mode picker
            Picker("显示模式", selection: $displayMode) {
                ForEach(DisplayMode.allCases, id: \.self) { mode in
                    Text(mode.rawValue).tag(mode)
                }
            }
            .pickerStyle(.segmented)
            .padding(.horizontal)
            .padding(.vertical, 8)

            // Content
            if record.photos.isEmpty {
                ContentUnavailableView(
                    "没有照片",
                    systemImage: "photo.on.rectangle.angled",
                    description: Text("点击右上角 + 添加照片")
                )
            } else {
                switch displayMode {
                case .grid:
                    photoGridView
                case .poster:
                    posterView
                }
            }
        }
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
                    .onDisappear {
                        if photo.posterText != nil {
                            photo.isPoster = true
                        }
                    }
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

    // MARK: - Grid Mode

    private var photoGridView: some View {
        ScrollView {
            LazyVGrid(columns: [GridItem(.adaptive(minimum: 100, maximum: 140), spacing: 4)], spacing: 4) {
                ForEach(record.photos) { photo in
                    ZStack(alignment: .topTrailing) {
                        thumbnailView(for: photo)
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
                                if !photo.isPoster {
                                    Button {
                                        makePoster(photo)
                                    } label: {
                                        Label("设为海报", systemImage: "rectangle.portrait.on.rectangle.portrait")
                                    }
                                }
                                Button(role: .destructive) {
                                    deletePhoto(photo)
                                } label: {
                                    Label("删除照片", systemImage: "trash")
                                }
                            }

                        // Poster badge
                        if photo.isPoster {
                            Image(systemName: "star.fill")
                                .font(.system(size: 10))
                                .foregroundStyle(.yellow)
                                .padding(4)
                                .background(.ultraThinMaterial)
                                .clipShape(Circle())
                                .padding(3)
                        }

                        // Delete button overlay
                        Button {
                            deletePhoto(photo)
                        } label: {
                            Image(systemName: "xmark.circle.fill")
                                .font(.system(size: 18))
                                .foregroundStyle(.white, .black.opacity(0.4))
                        }
                        .padding(2)
                        .opacity(0.6)
                    }
                }
            }
            .padding(4)
        }
    }

    private func thumbnailView(for photo: PhotoItem) -> some View {
        if let thumbPath = photo.thumbnailImagePath,
           let image = FileStorageManager.shared.loadImage(from: thumbPath) {
            return AnyView(image.resizable())
        }
        if let image = FileStorageManager.shared.loadImage(from: photo.originalImagePath) {
            return AnyView(image.resizable())
        }
        return AnyView(Rectangle().fill(.quaternary))
    }

    // MARK: - Poster Mode

    private var posterView: some View {
        let posterPhotos = record.photos.filter { $0.isPoster }
        let displayPhotos = posterPhotos.isEmpty ? record.photos : posterPhotos

        return ScrollView {
            VStack(spacing: 16) {
                ForEach(displayPhotos) { photo in
                    PosterCanvasView(photo: photo)
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
