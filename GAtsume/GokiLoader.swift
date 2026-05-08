import Foundation

enum GokiLoader {
    static func loadAll() -> [GokiKind] {
        guard let url = Bundle.main.url(forResource: "goki_data", withExtension: "json") else {
            print("❌ goki_data.json not found in bundle")
            return []
        }
        do {
            let data = try Data(contentsOf: url)
            let file = try JSONDecoder().decode(GokiFile.self, from: data)
            return file.goki
        } catch {
            print("❌ goki_data.json decode error: \(error)")
            return []
        }
    }
}

private struct GokiFile: Codable {
    let goki: [GokiKind]
}
