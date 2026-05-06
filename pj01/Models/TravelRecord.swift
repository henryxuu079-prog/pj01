import Foundation
import SwiftData

@Model
final class TravelRecord {
    var id: UUID
    var title: String
    var recordDescription: String?
    var timestamp: Date?
    var locationName: String?
    var latitude: Double?
    var longitude: Double?
    var sortOrder: Int
    var createdAt: Date

    @Relationship(deleteRule: .nullify) var travel: Travel?

    @Relationship(deleteRule: .cascade, inverse: \PhotoItem.record)
    var photos: [PhotoItem] = []

    init(title: String, sortOrder: Int = 0) {
        self.id = UUID()
        self.title = title
        self.sortOrder = sortOrder
        self.createdAt = Date()
    }
}
