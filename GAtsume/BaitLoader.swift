import Foundation

enum BaitLoader {
    static func loadAll() -> [BaitKind] {
        guard let url = Bundle.main.url(forResource: "bait_data", withExtension: "json") else {
            print("❌ bait_data.json not found in bundle")
            return []
        }
        do {
            let data = try Data(contentsOf: url)
            let file = try JSONDecoder().decode(BaitFile.self, from: data)
            return file.bait
        } catch {
            print("❌ bait_data.json decode error: \(error)")
            return []
        }
    }
}

private struct BaitFile: Codable {
    let bait: [BaitKind]
}
