import SwiftUI
import SwiftData
import Combine

struct RandomReviewView: View {
    @Query private var photos: [PhotoItem]

    @State private var currentPhoto: PhotoItem?
    @State private var timerRunning = false
    @State private var showLocation = true

    private let timer = Timer.publish(every: 5, on: .main, in: .common).autoconnect()

    var body: some View {
        VStack {
            if let photo = currentPhoto {
                VStack(spacing: 0) {
                    // Photo display
                    ZStack {
                        if let image = loadImage(for: photo) {
                            image
                                .resizable()
                                .aspectRatio(contentMode: .fit)
                        } else {
                            Rectangle()
                                .fill(.quaternary)
                                .aspectRatio(photoAspectRatio(for: photo), contentMode: .fit)
                        }
                    }

                    // Info footer
                    VStack(spacing: 4) {
                        if showLocation, let location = displayLocation(for: photo) {
                            Label(location, systemImage: "mappin.and.ellipse")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                        if let date = photo.takenDate {
                            Text(date, style: .date)
                                .font(.caption2)
                                .foregroundStyle(.tertiary)
                        }
                    }
                    .padding(12)
                }
                .background(.ultraThinMaterial)
                .clipShape(RoundedRectangle(cornerRadius: 12))
                .padding()
            } else {
                ContentUnavailableView(
                    "没有照片",
                    systemImage: "photo.on.rectangle.angled",
                    description: Text("添加旅行记录和照片后，在这里随机回顾那些美妙的瞬间")
                )
            }

            // Controls
            HStack(spacing: 24) {
                Button {
                    showLocation.toggle()
                } label: {
                    Image(systemName: showLocation ? "location.fill" : "location.slash")
                }

                Button {
                    timerRunning.toggle()
                } label: {
                    Image(systemName: timerRunning ? "pause.fill" : "play.fill")
                }

                Button {
                    pickRandom()
                } label: {
                    Image(systemName: "arrow.clockwise")
                }
            }
            .font(.title2)
            .padding()
        }
        .navigationTitle("随机回顾")
        .onAppear { pickRandom() }
        .onReceive(timer) { _ in
            if timerRunning { pickRandom() }
        }
    }

    private func pickRandom() {
        currentPhoto = photos.randomElement()
    }

    private func photoAspectRatio(for photo: PhotoItem) -> CGFloat {
        guard let w = photo.imageWidth, let h = photo.imageHeight, h > 0 else { return 3/2 }
        return CGFloat(w / h)
    }

    private func displayLocation(for photo: PhotoItem) -> String? {
        photo.locationName
    }

    private func loadImage(for photo: PhotoItem) -> Image? {
        if let thumbPath = photo.thumbnailImagePath {
            return FileStorageManager.shared.loadImage(from: thumbPath)
        }
        return FileStorageManager.shared.loadImage(from: photo.originalImagePath)
    }
}

#Preview {
    NavigationStack {
        RandomReviewView()
    }
    .modelContainer(for: [PhotoItem.self, TravelRecord.self, Travel.self], inMemory: true)
}
