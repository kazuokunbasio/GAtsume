import Foundation

enum WallpaperLoader {
    static func loadAll() -> [WallpaperKind] {
        guard let url = Bundle.main.url(forResource: "wallpaper_data", withExtension: "json") else {
            print("❌ wallpaper_data.json not found in bundle")
            return []
        }
        do {
            let data = try Data(contentsOf: url)
            let file = try JSONDecoder().decode(WallpaperFile.self, from: data)
            return file.wallpapers
        } catch {
            print("❌ wallpaper_data.json decode error: \(error)")
            return []
        }
    }
}

private struct WallpaperFile: Codable {
    let wallpapers: [WallpaperKind]
}
