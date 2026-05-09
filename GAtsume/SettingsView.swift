import SwiftUI
import SwiftData

struct SettingsView: View {
    @AppStorage("soundEnabled") private var soundEnabled = true
    @AppStorage("bgmEnabled") private var bgmEnabled = false
    @AppStorage("bgmVolume") private var bgmVolume: Double = 0.4
    @AppStorage("notificationsEnabled") private var notificationsEnabled = false
    @Environment(\.modelContext) private var modelContext
    @Query private var sightings: [SightingRecord]
    @Query private var ownerships: [FurnitureOwnership]
    @Query private var wallets: [Wallet]
    @Query private var inventories: [BaitInventory]
    @Query private var activeBaits: [ActiveBait]
    @Query private var lastVisits: [LastVisit]
    @Query private var dailyLogins: [DailyLogin]
    @Query private var dailyMissions: [DailyMission]
    @Query private var wallpaperOwnerships: [WallpaperOwnership]
    @AppStorage("selectedWallpaperId") private var selectedWallpaperId = "default"
    @AppStorage("homeShowChart") private var homeShowChart = true
    @AppStorage("homeShowAchievements") private var homeShowAchievements = true
    @AppStorage("homeShowActivity") private var homeShowActivity = true

    @State private var showResetConfirm = false
    @State private var showRestoreAlert = false
    @State private var showRemoveAdsAlert = false
    @State private var showPrivacy = false
    @State private var exportURL: URL?

    var body: some View {
        NavigationStack {
            List {
                Section("音") {
                    Toggle("効果音", isOn: $soundEnabled)
                    Toggle("BGM", isOn: $bgmEnabled)
                        .onChange(of: bgmEnabled) { _, on in
                            BGM.setEnabled(on)
                        }
                    if bgmEnabled {
                        HStack {
                            Image(systemName: "speaker.wave.1.fill")
                                .foregroundStyle(.secondary)
                            Slider(value: $bgmVolume, in: 0...1)
                                .onChange(of: bgmVolume) { _, v in
                                    BGM.setVolume(Float(v))
                                }
                            Image(systemName: "speaker.wave.3.fill")
                                .foregroundStyle(.secondary)
                        }
                    }
                }

                Section("通知") {
                    Toggle("毎日19時にリマインド", isOn: $notificationsEnabled)
                        .onChange(of: notificationsEnabled) { _, on in
                            Task { await handleNotificationToggle(on) }
                        }
                }

                Section("購入") {
                    Button {
                        showRemoveAdsAlert = true
                    } label: {
                        HStack {
                            Label("広告削除", systemImage: "rectangle.slash")
                                .foregroundStyle(.primary)
                            Spacer()
                            Text("近日対応")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                    Button {
                        showRestoreAlert = true
                    } label: {
                        HStack {
                            Label("購入の復元", systemImage: "arrow.clockwise")
                                .foregroundStyle(.primary)
                            Spacer()
                            Text("近日対応")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                }

                Section("ホーム表示") {
                    Toggle("過去7日のチャート", isOn: $homeShowChart)
                    Toggle("最近の活動", isOn: $homeShowActivity)
                    Toggle("達成バッジ", isOn: $homeShowAchievements)
                }

                Section("データ") {
                    if let url = exportURL {
                        ShareLink(item: url) {
                            Label("エクスポートを共有", systemImage: "square.and.arrow.up")
                        }
                    } else {
                        Button {
                            exportURL = generateExport()
                        } label: {
                            Label("データをエクスポート", systemImage: "tray.and.arrow.up")
                        }
                    }
                    Button(role: .destructive) {
                        showResetConfirm = true
                    } label: {
                        Label("すべてリセット", systemImage: "trash")
                    }
                }

                Section("情報") {
                    Button {
                        showPrivacy = true
                    } label: {
                        Label("プライバシーポリシー", systemImage: "hand.raised.fill")
                            .foregroundStyle(.primary)
                    }
                    HStack {
                        Text("バージョン")
                        Spacer()
                        Text("0.1 (プロトタイプ)")
                            .foregroundStyle(.secondary)
                    }
                    HStack {
                        Text("コンセプト")
                        Spacer()
                        Text("奇妙な小さな住人")
                            .foregroundStyle(.secondary)
                    }
                }
            }
            .navigationTitle("設定")
            .alert("リセットしますか？", isPresented: $showResetConfirm) {
                Button("キャンセル", role: .cancel) {}
                Button("リセット", role: .destructive) { resetAll() }
            } message: {
                Text("捕獲記録・購入家具・コインがすべて消えます。")
            }
            .alert("近日対応", isPresented: $showRestoreAlert) {
                Button("OK", role: .cancel) {}
            } message: {
                Text("App内課金は次のアップデートで対応予定です。")
            }
            .alert("近日対応", isPresented: $showRemoveAdsAlert) {
                Button("OK", role: .cancel) {}
            } message: {
                Text("広告削除は次のアップデートで対応予定です。")
            }
            .sheet(isPresented: $showPrivacy) {
                PrivacyPolicyView()
            }
        }
    }

    @MainActor
    private func handleNotificationToggle(_ on: Bool) async {
        if on {
            let granted = await Notifications.requestPermission()
            if granted {
                Notifications.scheduleDaily()
            } else {
                notificationsEnabled = false
            }
        } else {
            Notifications.cancelDaily()
        }
    }

    private func generateExport() -> URL? {
        struct ExportSighting: Codable {
            let gokiId: String
            let caughtAt: Date
        }
        struct ExportPayload: Codable {
            let exportedAt: Date
            let totalCatches: Int
            let uniqueKinds: Int
            let coins: Int
            let streak: Int
            let sightings: [ExportSighting]
        }

        let payload = ExportPayload(
            exportedAt: .now,
            totalCatches: sightings.count,
            uniqueKinds: Set(sightings.map(\.gokiId)).count,
            coins: wallets.first?.coins ?? 0,
            streak: dailyLogins.first?.streak ?? 0,
            sightings: sightings
                .sorted { $0.caughtAt < $1.caughtAt }
                .map { ExportSighting(gokiId: $0.gokiId, caughtAt: $0.caughtAt) }
        )

        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        encoder.dateEncodingStrategy = .iso8601

        guard let data = try? encoder.encode(payload) else { return nil }

        let formatter = DateFormatter()
        formatter.dateFormat = "yyyyMMdd_HHmmss"
        formatter.locale = .init(identifier: "en_US_POSIX")
        let filename = "gatsume_export_\(formatter.string(from: .now)).json"
        let url = FileManager.default.temporaryDirectory.appendingPathComponent(filename)
        do {
            try data.write(to: url, options: .atomic)
            return url
        } catch {
            return nil
        }
    }

    private func resetAll() {
        for s in sightings { modelContext.delete(s) }
        for o in ownerships { modelContext.delete(o) }
        for w in wallets { modelContext.delete(w) }
        for i in inventories { modelContext.delete(i) }
        for b in activeBaits { modelContext.delete(b) }
        for v in lastVisits { modelContext.delete(v) }
        for l in dailyLogins { modelContext.delete(l) }
        for m in dailyMissions { modelContext.delete(m) }
        for w in wallpaperOwnerships { modelContext.delete(w) }
        selectedWallpaperId = "default"
        modelContext.insert(Wallet(coins: 100))
        modelContext.insert(LastVisit())
        modelContext.insert(DailyLogin())
        modelContext.insert(WallpaperOwnership(wallpaperId: "default"))
    }
}
