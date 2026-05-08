import Foundation
import SwiftData

@Model
final class PlacedFurniture {
    @Attribute(.unique) var furnitureId: String
    var placedAt: Date

    init(furnitureId: String, placedAt: Date = .now) {
        self.furnitureId = furnitureId
        self.placedAt = placedAt
    }
}
