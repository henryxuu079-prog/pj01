import Foundation
import SwiftData

enum PosterTextPosition: String, CaseIterable, Codable {
    case overlay = "overlay"
    case caption = "caption"
}

@Model
final class PhotoItem {
    var id: UUID

    // MARK: - File paths
    var originalImagePath: String
    var thumbnailImagePath: String?

    // MARK: - Dimensions
    var imageWidth: Double?
    var imageHeight: Double?

    // MARK: - EXIF metadata
    var takenDate: Date?
    var cameraModel: String?
    var lensModel: String?
    var focalLength: String?
    var aperture: String?
    var shutterSpeed: String?
    var iso: Int?

    // MARK: - Location
    var latitude: Double?
    var longitude: Double?
    var locationName: String?

    // MARK: - Poster config
    var posterText: String?
    var posterFontName: String?
    var posterTextSize: Double?
    var posterTextColorHex: String?
    var posterTextPosition: String?
    var posterFrameStyle: String?
    var isPoster: Bool = false

    var createdAt: Date

    @Relationship(deleteRule: .nullify) var record: TravelRecord?

    var posterTextPositionEnum: PosterTextPosition {
        PosterTextPosition(rawValue: posterTextPosition ?? "") ?? .overlay
    }

    init(originalImagePath: String) {
        self.id = UUID()
        self.originalImagePath = originalImagePath
        self.createdAt = Date()
    }
}
