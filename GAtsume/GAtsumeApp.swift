import SwiftUI
import SwiftData

@main
struct GAtsumeApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
        .modelContainer(for: [SightingRecord.self, PlacedFurniture.self])
    }
}
