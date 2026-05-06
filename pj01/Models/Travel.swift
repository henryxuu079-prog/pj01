import Foundation
import SwiftData

@Model
final class Travel {
    var id: UUID
    var title: String
    var startDate: Date?
    var endDate: Date?
    var summary: String?
    var coverImagePath: String?
    var createdAt: Date
    var updatedAt: Date

    @Relationship(deleteRule: .cascade, inverse: \TravelRecord.travel)
    var records: [TravelRecord] = []

    init(title: String, startDate: Date? = nil, endDate: Date? = nil) {
        self.id = UUID()
        self.title = title
        self.startDate = startDate
        self.endDate = endDate
        self.createdAt = Date()
        self.updatedAt = Date()
    }
}
