import SwiftUI
import SwiftData
import Combine

struct RandomReviewView: View {
    @Query private var photos: [PhotoItem]

    @State private var currentPhoto: PhotoItem?
    @State private var timerRunning = false

    private let timer = Timer.publish(every: 5, on: .main, in: .common).autoconnect()

    var body: some View {
        VStack {
            if let photo = currentPhoto {
                PosterCanvasView(photo: photo)
                    .id(photo.id)
            } else {
                ContentUnavailableView(
                    "没有照片",
                    systemImage: "photo.on.rectangle.angled",
                    description: Text("添加旅行记录和照片后，在这里随机回顾那些美妙的瞬间")
                )
            }

            Spacer()

            HStack(spacing: 32) {
                Button {
                    timerRunning.toggle()
                } label: {
                    Image(systemName: timerRunning ? "pause.circle.fill" : "play.circle.fill")
                        .font(.system(size: 36))
                }

                Button {
                    pickRandom()
                } label: {
                    Image(systemName: "arrow.clockwise.circle.fill")
                        .font(.system(size: 36))
                }
            }
            .foregroundStyle(.secondary)
            .padding(.bottom, 32)
        }
        .navigationTitle("回忆")
        .onAppear { pickRandom() }
        .onReceive(timer) { _ in
            if timerRunning { pickRandom() }
        }
    }

    private func pickRandom() {
        withAnimation(.easeInOut(duration: 0.4)) {
            currentPhoto = photos.randomElement()
        }
    }
}

#Preview {
    NavigationStack {
        RandomReviewView()
    }
    .modelContainer(for: [PhotoItem.self, TravelRecord.self, Travel.self], inMemory: true)
}
