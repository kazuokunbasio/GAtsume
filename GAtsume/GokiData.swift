import Foundation

enum Rarity: String, Codable, Hashable {
    case normal
    case rare
    case superRare = "super_rare"

    var label: String {
        switch self {
        case .normal: return "ノーマル"
        case .rare: return "レア"
        case .superRare: return "超レア"
        }
    }
}

struct GokiKind: Codable, Identifiable, Hashable {
    let id: String
    let name: String
    let rarity: Rarity
    let description: String
    let favoriteFood: String
    let spawnWeight: Double
    let emoji: String
    let imageName: String?
    let period: String?
    let availableMonths: [Int]?

    func passesTimeFilter(now: Date = .now) -> Bool {
        let p = period ?? "any"
        if p == "any" { return true }
        let hour = Calendar.current.component(.hour, from: now)
        let isNight = hour >= 18 || hour < 6
        switch p {
        case "night": return isNight
        case "day": return !isNight
        default: return true
        }
    }

    func passesSeasonFilter(now: Date = .now) -> Bool {
        guard let months = availableMonths, !months.isEmpty else { return true }
        let month = Calendar.current.component(.month, from: now)
        return months.contains(month)
    }

    func isAvailable(now: Date = .now) -> Bool {
        passesTimeFilter(now: now) && passesSeasonFilter(now: now)
    }

    var seasonLabel: String? {
        guard let months = availableMonths, !months.isEmpty else { return nil }
        let s = Set(months)
        if s == [3, 4, 5] { return "春限定" }
        if s == [6, 7, 8] || s == [7, 8] { return "夏限定" }
        if s == [9, 10, 11] || s == [10] { return "秋限定" }
        if s == [12, 1, 2] { return "冬限定" }
        return "期間限定"
    }
}
