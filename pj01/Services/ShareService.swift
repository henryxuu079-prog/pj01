import Foundation
import SwiftUI

final class ShareService {
    static let shared = ShareService()

    func tempURL(for photo: PhotoItem) -> URL? {
        let originalURL = FileStorageManager.shared.url(for: photo.originalImagePath)
        guard FileManager.default.fileExists(atPath: originalURL.path) else { return nil }
        let ext = (originalURL.pathExtension.isEmpty) ? "jpg" : originalURL.pathExtension
        let tempURL = FileManager.default.temporaryDirectory
            .appendingPathComponent("pj01-share-\(photo.id).\(ext)")
        try? FileManager.default.removeItem(at: tempURL)
        try? FileManager.default.copyItem(at: originalURL, to: tempURL)
        return tempURL
    }

    #if os(macOS)
    func showSharePicker(for photo: PhotoItem) {
        guard let url = tempURL(for: photo) else { return }
        let picker = NSSharingServicePicker(items: [url])
        if let window = NSApp.keyWindow {
            picker.show(relativeTo: .zero, of: window.contentView!, preferredEdge: .minY)
        }
    }
    #endif
}
