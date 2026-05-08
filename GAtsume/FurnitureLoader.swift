import Foundation

enum FurnitureLoader {
    static func loadAll() -> [FurnitureKind] {
        guard let url = Bundle.main.url(forResource: "furniture_data", withExtension: "json") else {
            print("❌ furniture_data.json not found in bundle")
            return []
        }
        do {
            let data = try Data(contentsOf: url)
            let file = try JSONDecoder().decode(FurnitureFile.self, from: data)
            return file.furniture
        } catch {
            print("❌ furniture_data.json decode error: \(error)")
            return []
        }
    }
}

private struct FurnitureFile: Codable {
    let furniture: [FurnitureKind]
}
