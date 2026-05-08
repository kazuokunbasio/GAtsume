import SwiftUI
import SwiftData

@main
struct GAtsumeApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
        .modelContainer(for: [
            SightingRecord.self,
            FurnitureOwnership.self,
            Wallet.self,
            LastVisit.self,
            BaitInventory.self,
            ActiveBait.self,
            DailyLogin.self,
            DailyMission.self
        ])
    }
}
