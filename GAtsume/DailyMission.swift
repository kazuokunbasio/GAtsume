import Foundation
import SwiftData

@Model
final class DailyMission {
    var dateKey: String
    var kind: String
    var target: Int
    var progress: Int
    var rewardCoins: Int
    var claimed: Bool

    init(
        dateKey: String,
        kind: String,
        target: Int,
        progress: Int = 0,
        rewardCoins: Int,
        claimed: Bool = false
    ) {
        self.dateKey = dateKey
        self.kind = kind
        self.target = target
        self.progress = progress
        self.rewardCoins = rewardCoins
        self.claimed = claimed
    }
}
