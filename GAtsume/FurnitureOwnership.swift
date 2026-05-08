import Foundation
import SwiftData

@Model
final class FurnitureOwnership {
    @Attribute(.unique) var furnitureId: String
    var isActive: Bool
    var purchasedAt: Date
    var positionXFraction: Double?
    var positionYFraction: Double?

    init(
        furnitureId: String,
        isActive: Bool = true,
        purchasedAt: Date = .now,
        positionXFraction: Double? = nil,
        positionYFraction: Double? = nil
    ) {
        self.furnitureId = furnitureId
        self.isActive = isActive
        self.purchasedAt = purchasedAt
        self.positionXFraction = positionXFraction
        self.positionYFraction = positionYFraction
    }
}
