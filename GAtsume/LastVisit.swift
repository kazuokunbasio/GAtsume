import Foundation
import SwiftData

@Model
final class LastVisit {
    var at: Date

    init(at: Date = .now) {
        self.at = at
    }
}
