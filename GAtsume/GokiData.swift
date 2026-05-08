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
}
