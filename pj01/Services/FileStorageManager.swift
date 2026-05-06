import Foundation
import SwiftUI

final class FileStorageManager {
    static let shared = FileStorageManager()

    private let fileManager = FileManager.default

    var originalsDirectory: URL {
        documentsDirectory.appendingPathComponent("Originals")
    }

    var thumbnailsDirectory: URL {
        documentsDirectory.appendingPathComponent("Thumbnails")
    }

    private var documentsDirectory: URL {
        fileManager.urls(for: .documentDirectory, in: .userDomainMask)[0]
    }

    init() {
        try? fileManager.createDirectory(at: originalsDirectory, withIntermediateDirectories: true)
        try? fileManager.createDirectory(at: thumbnailsDirectory, withIntermediateDirectories: true)
    }

    func saveOriginal(imageData: Data, fileExtension: String = "jpg") throws -> String {
        let filename = "\(UUID().uuidString).\(fileExtension)"
        let destination = originalsDirectory.appendingPathComponent(filename)
        try imageData.write(to: destination)
        return "Originals/\(filename)"
    }

    func generateThumbnail(for originalPath: String, maxSide: CGFloat = 400) throws -> String? {
        let sourceURL = url(for: originalPath)
        let thumbFilename = "\(UUID().uuidString).jpg"
        let destinationURL = thumbnailsDirectory.appendingPathComponent(thumbFilename)
        guard ImageProcessingService.shared.generateThumbnail(from: sourceURL, maxSide: maxSide, outputURL: destinationURL) else {
            return nil
        }
        return "Thumbnails/\(thumbFilename)"
    }

    func loadImage(from relativePath: String) -> Image? {
        let fileURL = url(for: relativePath)
        guard fileManager.fileExists(atPath: fileURL.path) else { return nil }
        #if canImport(AppKit)
        guard let nsImage = NSImage(contentsOf: fileURL) else { return nil }
        return Image(nsImage: nsImage)
        #else
        guard let uiImage = UIImage(contentsOfFile: fileURL.path) else { return nil }
        return Image(uiImage: uiImage)
        #endif
    }

    func url(for relativePath: String) -> URL {
        documentsDirectory.appendingPathComponent(relativePath)
    }

    func deleteFile(at relativePath: String) throws {
        let fileURL = url(for: relativePath)
        if fileManager.fileExists(atPath: fileURL.path) {
            try fileManager.removeItem(at: fileURL)
        }
    }
}
