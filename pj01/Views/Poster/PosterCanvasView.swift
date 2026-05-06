import SwiftUI

struct PosterCanvasView: View {
    let photo: PhotoItem

    @State private var showStylePicker = false

    var body: some View {
        VStack(spacing: 0) {
            // Image area
            ZStack(alignment: posterTextAlignment) {
                if let image = loadedImage {
                    image
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                } else {
                    Rectangle()
                        .fill(.quaternary)
                        .aspectRatio(photoAspectRatio, contentMode: .fit)
                }

                if photo.posterTextPositionEnum == .overlay,
                   let text = photo.posterText {
                    Text(text)
                        .font(posterFont)
                        .foregroundStyle(posterColor)
                        .padding(8)
                }
            }

            // Caption area (outside image)
            if photo.posterTextPositionEnum == .caption,
               let text = photo.posterText {
                HStack {
                    Text(text)
                        .font(posterFont)
                        .foregroundStyle(posterColor)
                    Spacer()
                }
                .padding(12)
                .background(.ultraThinMaterial)
            }
        }
        .clipShape(RoundedRectangle(cornerRadius: posterFrameCornerRadius))
        .overlay {
            RoundedRectangle(cornerRadius: posterFrameCornerRadius)
                .stroke(.secondary.opacity(0.3), lineWidth: 1)
        }
        .padding(.horizontal)
        .onTapGesture { showStylePicker = true }
        .sheet(isPresented: $showStylePicker) {
            PosterStylePicker(photo: photo)
        }
    }

    private var photoAspectRatio: CGFloat {
        guard let w = photo.imageWidth, let h = photo.imageHeight, h > 0 else { return 3/2 }
        return CGFloat(w / h)
    }

    private var posterTextAlignment: Alignment {
        .bottomLeading
    }

    private var posterFont: Font {
        if let fontName = photo.posterFontName {
            Font.custom(fontName, size: CGFloat(photo.posterTextSize ?? 24))
        } else {
            .system(size: CGFloat(photo.posterTextSize ?? 24), design: .serif)
        }
    }

    private var posterColor: Color {
        if let hex = photo.posterTextColorHex {
            Color(hex: hex)
        } else {
            .white
        }
    }

    private var posterFrameCornerRadius: CGFloat {
        photo.posterFrameStyle == nil ? 8 : 12
    }

    private var loadedImage: Image? {
        FileStorageManager.shared.loadImage(from: photo.originalImagePath)
    }
}
