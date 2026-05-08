import SwiftUI
import SwiftData

struct ContentView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.scenePhase) private var scenePhase
    @AppStorage("onboardingShown") private var onboardingShown = false

    @Query private var wallets: [Wallet]
    @Query private var lastVisits: [LastVisit]
    @Query private var ownerships: [FurnitureOwnership]
    @Query private var dailyLogins: [DailyLogin]
    @Query private var wallpaperOwnerships: [WallpaperOwnership]
    @Query private var allMissions: [DailyMission]

    @State private var summary: OfflineCatchSummary?
    @State private var streakMilestone: StreakMilestone?

    private var claimableCount: Int {
        let today = DailyKey.today()
        return allMissions.filter {
            $0.dateKey == today && !$0.claimed && $0.progress >= $0.target
        }.count
    }

    var body: some View {
        TabView {
            HomeView()
                .tabItem { Label("ホーム", systemImage: "house") }
                .badge(claimableCount)
            RoomView()
                .tabItem { Label("部屋", systemImage: "bed.double.fill") }
            FurnitureView()
                .tabItem { Label("家具", systemImage: "shippingbox.fill") }
            CollectionView()
                .tabItem { Label("図鑑", systemImage: "book.fill") }
            SettingsView()
                .tabItem { Label("設定", systemImage: "gearshape.fill") }
        }
        .task {
            initializeIfNeeded()
            handleVisit()
            DailyMissions.ensureToday(modelContext: modelContext)
            claimDailyLoginIfNeeded()
        }
        .onChange(of: scenePhase) { oldPhase, newPhase in
            if newPhase == .background {
                lastVisits.first?.at = .now
            } else if newPhase == .active && oldPhase != .active {
                handleVisit()
                DailyMissions.ensureToday(modelContext: modelContext)
                claimDailyLoginIfNeeded()
            }
        }
        .sheet(item: $summary) { s in
            OfflineCatchSummaryView(summary: s)
        }
        .sheet(item: $streakMilestone) { m in
            StreakCelebrationView(milestone: m)
        }
        .fullScreenCover(isPresented: .constant(!onboardingShown)) {
            OnboardingView()
        }
    }

    private func initializeIfNeeded() {
        if wallets.isEmpty {
            modelContext.insert(Wallet(coins: 100))
        }
        if lastVisits.isEmpty {
            modelContext.insert(LastVisit())
        }
        if dailyLogins.isEmpty {
            modelContext.insert(DailyLogin())
        }
        if !wallpaperOwnerships.contains(where: { $0.wallpaperId == "default" }) {
            modelContext.insert(WallpaperOwnership(wallpaperId: "default"))
        }
    }

    private func handleVisit() {
        guard let visit = lastVisits.first else { return }
        let elapsed = Date.now.timeIntervalSince(visit.at)
        if elapsed > 300 {
            simulateOffline(elapsed: elapsed)
        }
        visit.at = .now
    }

    private func claimDailyLoginIfNeeded() {
        guard let login = dailyLogins.first else { return }
        let today = DailyKey.today()
        guard login.lastClaimDate != today else { return }

        let yesterday = DailyKey.yesterday()
        let oldStreak = login.streak
        login.streak = login.lastClaimDate == yesterday ? login.streak + 1 : 1
        login.lastClaimDate = today

        let bonus = DailyLoginBonus.bonusFor(streak: login.streak)
        wallets.first?.coins += bonus

        let milestoneDays = [3, 7, 14, 30, 100]
        if milestoneDays.contains(login.streak), login.streak > oldStreak {
            let extra = streakMilestoneBonus(login.streak)
            wallets.first?.coins += extra
            streakMilestone = StreakMilestone(days: login.streak, bonusCoins: extra)
        }
    }

    private func streakMilestoneBonus(_ days: Int) -> Int {
        switch days {
        case 3: return 30
        case 7: return 100
        case 14: return 200
        case 30: return 500
        case 100: return 2000
        default: return 0
        }
    }

    private func simulateOffline(elapsed: TimeInterval) {
        let bounded = min(elapsed, 8 * 3600)
        let attempts = Int(bounded / 300)
        guard attempts > 0 else { return }

        let allKinds = GokiLoader.loadAll()
        let allFurniture = FurnitureLoader.loadAll()
        let activeIds = ownerships.filter(\.isActive).map(\.furnitureId)

        var counts: [String: Int] = [:]
        var coinsEarned = 0

        for _ in 0..<attempts {
            guard let kind = Spawner.pick(
                from: allKinds,
                furniture: allFurniture,
                activeFurnitureIds: activeIds
            ) else { continue }
            if Double.random(in: 0..<1) < 0.6 {
                modelContext.insert(SightingRecord(gokiId: kind.id))
                counts[kind.id, default: 0] += 1
                coinsEarned += Spawner.coinReward(for: kind.rarity)
            }
        }

        guard coinsEarned > 0 else { return }
        wallets.first?.coins += coinsEarned

        let entries = counts.compactMap { id, count -> OfflineCatchEntry? in
            guard let kind = allKinds.first(where: { $0.id == id }) else { return nil }
            return OfflineCatchEntry(kind: kind, count: count)
        }
        summary = OfflineCatchSummary(
            entries: entries,
            coinsEarned: coinsEarned,
            minutes: Int(bounded / 60)
        )
    }
}

#Preview {
    ContentView()
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
        ], inMemory: true)
}
