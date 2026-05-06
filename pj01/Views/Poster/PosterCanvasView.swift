import SwiftUI

struct PosterCanvasView: View {
    let photo: PhotoItem

    @State private var showStylePicker = false
    @State private var scale: CGFloat = 1.0
    @State private var lastScale: CGFloat = 1.0
    @State private var offset: CGSize = .zero
    @State private var lastOffset: CGSize = .zero

    var body: some View {
        VStack(spacing: 0) {
            ZStack(alignment: posterTextAlignment) {
                if let image = loadedImage {
                    image
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .scaleEffect(scale)
                        .offset(offset)
                        .gesture(
                            MagnifyGesture()
                                .onChanged { value in
                                    let newScale = lastScale * value.magnification
                                    scale = min(max(newScale, 1.0), 5.0)
                                }
                                .onEnded { _ in
                                    lastScale = scale
                                    if scale <= 1.0 {
                                        withAnimation(.spring) {
                                            scale = 1.0
                                            offset = .zero
                                            lastOffset = .zero
                                        }
                                    }
                                }
                        )
                        .simultaneousGesture(
                            scale > 1.0
                            ? DragGesture()
                                .onChanged { value in
                                    offset = CGSize(
                                        width: lastOffset.width + value.translation.width,
                                        height: lastOffset.height + value.translation.height
                                    )
                                }
                                .onEnded { _ in
                                    lastOffset = offset
                                }
                            : nil
                        )
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
                        .allowsHitTesting(false)
                }
            }
            .onTapGesture(count: 2) {
                withAnimation(.spring) {
                    scale = 1.0
                    lastScale = 1.0
                    offset = .zero
                    lastOffset = .zero
                }
            }
            .onTapGesture(count: 1) {
                showStylePicker = true
            }

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
        .overlay { frameOverlay }
        .padding(.horizontal)
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
        switch photo.posterFrameStyle {
        case "classic": return 4
        case "modern": return 0
        case "film": return 2
        default: return 8
        }
    }

    @ViewBuilder
    private var frameOverlay: some View {
        switch photo.posterFrameStyle {
        case "classic":
            classicFrame
        case "modern":
            modernFrame
        case "film":
            filmFrame
        default:
            RoundedRectangle(cornerRadius: 8)
                .stroke(.secondary.opacity(0.3), lineWidth: 1)
        }
    }

    private var classicFrame: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 4)
                .stroke(.brown.opacity(0.6), lineWidth: 12)
            RoundedRectangle(cornerRadius: 4)
                .stroke(.brown.opacity(0.3), lineWidth: 3)
            RoundedRectangle(cornerRadius: 4)
                .inset(by: 6)
                .stroke(.yellow.opacity(0.15), lineWidth: 1)
        }
    }

    private var modernFrame: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 0)
                .fill(.white.opacity(0.12))
                .padding(-16)
            RoundedRectangle(cornerRadius: 0)
                .inset(by: -16)
                .stroke(.primary.opacity(0.15), lineWidth: 1)
            RoundedRectangle(cornerRadius: 0)
                .inset(by: -16)
                .stroke(.white.opacity(0.05), lineWidth: 6)
        }
    }

    private var filmFrame: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 2)
                .fill(.black.opacity(0.3))
                .padding(-8)
            RoundedRectangle(cornerRadius: 2)
                .stroke(.black.opacity(0.6), lineWidth: 8)
        }
    }

    private var loadedImage: Image? {
        FileStorageManager.shared.loadImage(from: photo.originalImagePath)
    }
}
