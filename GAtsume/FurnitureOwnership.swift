import Foundation
import SwiftData

@Model
final class FurnitureOwnership {
    @Attribute(.unique) var furnitureId: String
    var isActive: Bool
    var purchasedAt: Date

    init(furnitureId: String, isActive: Bool = true, purchasedAt: Date = .now) {
        self.furnitureId = furnitureId
        self.isActive = isActive
        self.purchasedAt = purchasedAt
    }
}
