import Foundation

struct BaitKind: Codable, Identifiable, Hashable {
    let id: String
    let name: String
    let emoji: String
    let description: String
    let price: Int
    let durationSec: Int
    let boosts: [String: Double]
}
