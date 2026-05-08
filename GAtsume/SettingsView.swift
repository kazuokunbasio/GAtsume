import SwiftUI
import SwiftData

struct SettingsView: View {
    @AppStorage("soundEnabled") private var soundEnabled = true
    @Environment(\.modelContext) private var modelContext
    @Query private var sightings: [SightingRecord]
    @Query private var ownerships: [FurnitureOwnership]
    @Query private var wallets: [Wallet]
    @Query private var inventories: [BaitInventory]
    @Query private var activeBaits: [ActiveBait]
    @Query private var lastVisits: [LastVisit]
    @Query private var dailyLogins: [DailyLogin]
    @Query private var dailyMissions: [DailyMission]

    @State private var showResetConfirm = false
    @State private var showRestoreAlert = false
    @State private var showRemoveAdsAlert = false

    var body: some View {
        NavigationStack {
            List {
                Section("音") {
                    Toggle("効果音", isOn: $soundEnabled)
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

                Section("データ") {
                    Button(role: .destructive) {
                        showResetConfirm = true
                    } label: {
                        Label("すべてリセット", systemImage: "trash")
                    }
                }

                Section("情報") {
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
        modelContext.insert(Wallet(coins: 100))
        modelContext.insert(LastVisit())
        modelContext.insert(DailyLogin())
    }
}
