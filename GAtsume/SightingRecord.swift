import Foundation
import SwiftData

@Model
final class SightingRecord {
    var gokiId: String
    var caughtAt: Date

    init(gokiId: String, caughtAt: Date = .now) {
        self.gokiId = gokiId
        self.caughtAt = caughtAt
    }
}
