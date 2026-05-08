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
}
