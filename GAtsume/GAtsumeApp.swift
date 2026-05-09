import SwiftUI
import SwiftData

@main
struct GAtsumeApp: App {
    init() {
        AdsBootstrap.startIfNeeded()
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
                .task { await PurchaseManager.shared.bootstrap() }
        }
        .modelContainer(for: [
            SightingRecord.self,
            FurnitureOwnership.self,
            Wallet.self,
            LastVisit.self,
            BaitInventory.self,
            ActiveBait.self,
            DailyLogin.self,
            DailyMission.self,
            WallpaperOwnership.self
        ])
    }
}
