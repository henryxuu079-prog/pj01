import SwiftUI
import MapKit

struct PhotoDetailView: View {
    let photo: PhotoItem

    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 0) {
                    // Full image
                    if let image = FileStorageManager.shared.loadImage(from: photo.originalImagePath) {
                        image
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                    } else {
                        Rectangle()
                            .fill(.quaternary)
                            .aspectRatio(photoAspectRatio, contentMode: .fit)
                            .overlay(Image(systemName: "photo").font(.largeTitle))
                    }

                    // EXIF panel
                    VStack(alignment: .leading, spacing: 12) {
                        if hasExifData {
                            SectionHeader("拍摄信息")

                            if let camera = photo.cameraModel {
                                InfoRow(icon: "camera.fill", label: "相机", value: camera)
                            }
                            if let lens = photo.lensModel {
                                InfoRow(icon: "camera.aperture", label: "镜头", value: lens)
                            }
                            if let focal = photo.focalLength {
                                InfoRow(icon: "f.circle", label: "焦距", value: focal)
                            }
                            if let aperture = photo.aperture {
                                InfoRow(icon: "camera.shutter.button", label: "光圈", value: aperture)
                            }
                            if let shutter = photo.shutterSpeed {
                                InfoRow(icon: "timer", label: "快门", value: shutter)
                            }
                            if let iso = photo.iso {
                                InfoRow(icon: "number.circle", label: "ISO", value: "\(iso)")
                            }
                        }

                        if let date = photo.takenDate {
                            SectionHeader(hasExifData ? "时间" : "拍摄信息")
                            InfoRow(icon: "calendar", label: "拍摄日期", value: date.formatted(date: .long, time: .shortened))
                        }

                        if hasLocationData {
                            SectionHeader("位置")
                            if let name = photo.locationName {
                                InfoRow(icon: "mappin.and.ellipse", label: "地点", value: name)
                            }
                            if let lat = photo.latitude, let lon = photo.longitude {
                                InfoRow(icon: "location.fill", label: "坐标", value: String(format: "%.4f, %.4f", lat, lon))
                                locationMap(lat: lat, lon: lon)
                            }
                        }

                        if let w = photo.imageWidth, let h = photo.imageHeight {
                            SectionHeader("尺寸")
                            InfoRow(icon: "rectangle.on.rectangle", label: "像素", value: "\(Int(w)) × \(Int(h))")
                        }

                        if photo.isPoster {
                            SectionHeader("展示")
                            InfoRow(icon: "star.fill", label: "状态", value: "海报模式")
                        }
                    }
                    .padding(16)
                    .frame(maxWidth: .infinity, alignment: .leading)
                }
            }
            .navigationTitle("照片详情")
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button {
                        #if os(macOS)
                        ShareService.shared.showSharePicker(for: photo)
                        #else
                        if let url = ShareService.shared.tempURL(for: photo) {
                            let av = UIActivityViewController(activityItems: [url], applicationActivities: nil)
                            if let scene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
                               let window = scene.windows.first,
                               let root = window.rootViewController {
                                root.present(av, animated: true)
                            }
                        }
                        #endif
                    } label: {
                        Label("分享", systemImage: "square.and.arrow.up")
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("关闭") { dismiss() }
                }
            }
        }
    }

    private var photoAspectRatio: CGFloat {
        guard let w = photo.imageWidth, let h = photo.imageHeight, h > 0 else { return 3/2 }
        return CGFloat(w / h)
    }

    private var hasExifData: Bool {
        photo.cameraModel != nil || photo.lensModel != nil || photo.aperture != nil
    }

    private var hasLocationData: Bool {
        photo.locationName != nil || photo.latitude != nil
    }

    @ViewBuilder
    private func locationMap(lat: Double, lon: Double) -> some View {
        let coordinate = CLLocationCoordinate2D(latitude: lat, longitude: lon)
        let region = MKCoordinateRegion(center: coordinate, span: MKCoordinateSpan(latitudeDelta: 0.01, longitudeDelta: 0.01))
        Map(initialPosition: .region(region)) {
            Marker(photo.locationName ?? "", coordinate: coordinate)
        }
        .frame(height: 160)
        .clipShape(RoundedRectangle(cornerRadius: 8))
        .padding(.top, 4)
    }
}

private struct SectionHeader: View {
    let title: String

    init(_ title: String) {
        self.title = title
    }

    var body: some View {
        Text(title)
            .font(.caption.weight(.semibold))
            .foregroundStyle(.secondary)
            .padding(.top, 4)
    }
}

private struct InfoRow: View {
    let icon: String
    let label: String
    let value: String

    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: icon)
                .frame(width: 20)
                .foregroundStyle(.secondary)
            Text(label)
                .font(.subheadline)
                .foregroundStyle(.secondary)
            Spacer()
            Text(value)
                .font(.subheadline.weight(.medium))
        }
    }
}

#Preview {
    PhotoDetailView(photo: PhotoItem(originalImagePath: ""))
}
