import Foundation
import SwiftData

@Model
final class BaitInventory {
    @Attribute(.unique) var baitId: String
    var count: Int

    init(baitId: String, count: Int = 0) {
        self.baitId = baitId
        self.count = count
    }
}
