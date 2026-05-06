import PhotosUI
import SwiftUI

final class PhotoLibraryService {
    static let shared = PhotoLibraryService()

    func requestAuthorization() async -> Bool {
        let status = PHPhotoLibrary.authorizationStatus(for: .readWrite)
        if status == .authorized || status == .limited {
            return true
        }
        return await PHPhotoLibrary.requestAuthorization(for: .readWrite) == .authorized
    }

    func loadImageData(from item: PhotosPickerItem) async throws -> Data? {
        try await item.loadTransferable(type: Data.self)
    }
}
