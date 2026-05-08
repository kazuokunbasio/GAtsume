import Foundation

struct WallpaperKind: Codable, Identifiable, Hashable {
    let id: String
    let name: String
    let emoji: String
    let price: Int
    let bgColor: [Double]
    let floorColor: [Double]
}
