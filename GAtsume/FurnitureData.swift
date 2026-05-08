import Foundation

struct FurnitureKind: Codable, Identifiable, Hashable {
    let id: String
    let name: String
    let emoji: String
    let description: String
    let boosts: [String: Double]
}
