import Foundation
import SwiftData

@Model
final class ActiveBait {
    var baitId: String
    var expiresAt: Date

    init(baitId: String, expiresAt: Date) {
        self.baitId = baitId
        self.expiresAt = expiresAt
    }
}
