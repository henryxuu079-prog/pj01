import Foundation
import ImageIO

final class ImageProcessingService {
    static let shared = ImageProcessingService()

    func extractEXIF(from imageURL: URL) -> EXIFMetadata {
        guard let source = CGImageSourceCreateWithURL(imageURL as CFURL, nil),
              let properties = CGImageSourceCopyPropertiesAtIndex(source, 0, nil) as? [CFString: Any] else {
            return EXIFMetadata()
        }

        let exif = properties[kCGImagePropertyExifDictionary] as? [CFString: Any]
        let tiff = properties[kCGImagePropertyTIFFDictionary] as? [CFString: Any]
        let gps = properties[kCGImagePropertyGPSDictionary] as? [CFString: Any]

        return EXIFMetadata(
            takenDate: parseExifDate(exif?[kCGImagePropertyExifDateTimeOriginal] as? String),
            cameraModel: tiff?[kCGImagePropertyTIFFModel] as? String,
            lensModel: exif?[kCGImagePropertyExifLensModel] as? String,
            focalLength: exif?[kCGImagePropertyExifFocalLength] as? Double,
            aperture: exif?[kCGImagePropertyExifFNumber] as? Double,
            shutterSpeed: exif?[kCGImagePropertyExifExposureTime] as? Double,
            iso: (exif?[kCGImagePropertyExifISOSpeedRatings] as? [Int])?.first,
            width: properties[kCGImagePropertyPixelWidth] as? Double,
            height: properties[kCGImagePropertyPixelHeight] as? Double,
            latitude: gps?[kCGImagePropertyGPSLatitude] as? Double,
            longitude: gps?[kCGImagePropertyGPSLongitude] as? Double
        )
    }

    func generateThumbnail(from imageURL: URL, maxSide: CGFloat, outputURL: URL) -> Bool {
        guard let source = CGImageSourceCreateWithURL(imageURL as CFURL, nil) else { return false }
        let options: [CFString: Any] = [
            kCGImageSourceCreateThumbnailFromImageAlways: true,
            kCGImageSourceThumbnailMaxPixelSize: maxSide,
            kCGImageSourceCreateThumbnailWithTransform: true
        ]
        guard let thumbnail = CGImageSourceCreateThumbnailAtIndex(source, 0, options as CFDictionary),
              let destination = CGImageDestinationCreateWithURL(outputURL as CFURL, "public.jpeg" as CFString, 1, nil) else {
            return false
        }
        CGImageDestinationAddImage(destination, thumbnail, nil)
        return CGImageDestinationFinalize(destination)
    }

    private func parseExifDate(_ string: String?) -> Date? {
        guard let string else { return nil }
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy:MM:dd HH:mm:ss"
        return formatter.date(from: string)
    }
}

struct EXIFMetadata {
    var takenDate: Date?
    var cameraModel: String?
    var lensModel: String?
    var focalLength: Double?
    var aperture: Double?
    var shutterSpeed: Double?
    var iso: Int?
    var width: Double?
    var height: Double?
    var latitude: Double?
    var longitude: Double?
}
