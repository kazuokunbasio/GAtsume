import Foundation
import SwiftData

@Model
final class WallpaperOwnership {
    @Attribute(.unique) var wallpaperId: String
    var purchasedAt: Date

    init(wallpaperId: String, purchasedAt: Date = .now) {
        self.wallpaperId = wallpaperId
        self.purchasedAt = purchasedAt
    }
}
