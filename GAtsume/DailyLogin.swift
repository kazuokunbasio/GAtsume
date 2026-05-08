import Foundation
import SwiftData

@Model
final class DailyLogin {
    var lastClaimDate: String
    var streak: Int

    init(lastClaimDate: String = "", streak: Int = 0) {
        self.lastClaimDate = lastClaimDate
        self.streak = streak
    }
}

enum DailyKey {
    private static let formatter: DateFormatter = {
        let f = DateFormatter()
        f.calendar = .init(identifier: .gregorian)
        f.locale = .init(identifier: "en_US_POSIX")
        f.dateFormat = "yyyy-MM-dd"
        return f
    }()

    static func today(_ date: Date = .now) -> String {
        formatter.string(from: date)
    }

    static func yesterday(_ date: Date = .now) -> String {
        let y = Calendar.current.date(byAdding: .day, value: -1, to: date) ?? date
        return formatter.string(from: y)
    }
}

enum DailyLoginBonus {
    static func bonusFor(streak: Int) -> Int {
        min(50, 10 + streak * 5)
    }
}
