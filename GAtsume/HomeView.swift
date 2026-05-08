import SwiftUI
import SwiftData

struct HomeView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var sightings: [SightingRecord]
    @Query private var wallets: [Wallet]
    @Query private var dailyLogins: [DailyLogin]
    @Query(sort: \DailyMission.kind) private var todayMissions: [DailyMission]
    private let allKinds = GokiLoader.loadAll()

    private var todayMissionsFiltered: [DailyMission] {
        let today = DailyKey.today()
        return todayMissions.filter { $0.dateKey == today }
    }

    private var caughtIds: Set<String> {
        Set(sightings.map(\.gokiId))
    }

    private var totalCatches: Int { sightings.count }
    private var uniqueCount: Int { caughtIds.count }
    private var totalKinds: Int { allKinds.count }

    private var todayCount: Int {
        let today = Calendar.current.startOfDay(for: .now)
        return sightings.filter {
            Calendar.current.startOfDay(for: $0.caughtAt) == today
        }.count
    }

    private var streak: Int {
        let calendar = Calendar.current
        let dates = Set(sightings.map { calendar.startOfDay(for: $0.caughtAt) })
        let today = calendar.startOfDay(for: .now)
        var count = 0
        var d = today
        while dates.contains(d) {
            count += 1
            guard let prev = calendar.date(byAdding: .day, value: -1, to: d) else { break }
            d = prev
        }
        if count == 0 {
            guard let yesterday = calendar.date(byAdding: .day, value: -1, to: today) else {
                return 0
            }
            d = yesterday
            while dates.contains(d) {
                count += 1
                guard let prev = calendar.date(byAdding: .day, value: -1, to: d) else { break }
                d = prev
            }
        }
        return count
    }

    private var lastCatch: (kind: GokiKind, at: Date)? {
        guard let last = sightings.max(by: { $0.caughtAt < $1.caughtAt }),
              let kind = allKinds.first(where: { $0.id == last.gokiId }) else { return nil }
        return (kind, last.caughtAt)
    }

    private var achievementCtx: AchievementContext {
        AchievementContext(sightings: sightings, allKinds: allKinds)
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 16) {
                    coinHero
                    if let login = dailyLogins.first, login.lastClaimDate == DailyKey.today() {
                        loginBanner(streak: login.streak)
                    }
                    if !todayMissionsFiltered.isEmpty {
                        missionsSection
                    }
                    statsGrid
                    if let last = lastCatch {
                        lastCatchCard(kind: last.kind, at: last.at)
                    }
                    progressBar
                    achievementsSection
                }
                .padding()
            }
            .navigationTitle("ゴキあつめ")
        }
    }

    private func loginBanner(streak: Int) -> some View {
        let bonus = DailyLoginBonus.bonusFor(streak: streak)
        return HStack(spacing: 12) {
            Image(systemName: "flame.fill")
                .foregroundStyle(.orange)
                .font(.title2)
            VStack(alignment: .leading, spacing: 2) {
                Text("ログインボーナス受け取り済み")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Text("連続 \(streak) 日 (+\(bonus))")
                    .font(.subheadline.bold())
            }
            Spacer()
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 10)
        .background(.orange.opacity(0.12), in: .rect(cornerRadius: 12))
    }

    private var missionsSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("今日のミッション")
                .font(.caption)
                .foregroundStyle(.secondary)
            ForEach(todayMissionsFiltered) { mission in
                MissionRow(mission: mission, onClaim: { claim(mission) })
            }
        }
        .padding()
        .background(.ultraThinMaterial, in: .rect(cornerRadius: 14))
    }

    private func claim(_ mission: DailyMission) {
        guard !mission.claimed, mission.progress >= mission.target else { return }
        mission.claimed = true
        wallets.first?.coins += mission.rewardCoins
        Sounds.purchase()
    }

    private var achievementsSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text("達成バッジ")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Spacer()
                let unlocked = Achievements.all.filter { $0.check(achievementCtx) }.count
                Text("\(unlocked)/\(Achievements.all.count)")
                    .font(.caption.bold().monospacedDigit())
                    .foregroundStyle(.secondary)
            }
            LazyVGrid(
                columns: [GridItem(.adaptive(minimum: 90), spacing: 10)],
                spacing: 10
            ) {
                ForEach(Achievements.all) { ach in
                    AchievementBadge(
                        achievement: ach,
                        unlocked: ach.check(achievementCtx)
                    )
                }
            }
        }
        .padding()
        .background(.ultraThinMaterial, in: .rect(cornerRadius: 14))
    }

    private var coinHero: some View {
        HStack(spacing: 10) {
            Image(systemName: "circle.hexagongrid.fill")
                .foregroundStyle(.yellow)
                .font(.system(size: 32))
            Text("\(wallets.first?.coins ?? 0)")
                .font(.system(size: 40, weight: .bold).monospacedDigit())
            Spacer()
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 18)
        .frame(maxWidth: .infinity)
        .background(.ultraThinMaterial, in: .rect(cornerRadius: 18))
    }

    private var statsGrid: some View {
        LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
            StatCard(label: "累計捕獲", value: "\(totalCatches)", unit: "匹")
            StatCard(label: "図鑑進捗", value: "\(uniqueCount)", unit: "/\(totalKinds)")
            StatCard(label: "連続日数", value: "\(streak)", unit: "日")
            StatCard(label: "今日", value: "\(todayCount)", unit: "匹")
        }
    }

    private var progressBar: some View {
        let ratio = totalKinds > 0 ? Double(uniqueCount) / Double(totalKinds) : 0
        return VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text("コンプリート率")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Spacer()
                Text("\(Int(ratio * 100))%")
                    .font(.caption.bold().monospacedDigit())
            }
            GeometryReader { proxy in
                ZStack(alignment: .leading) {
                    Capsule().fill(.gray.opacity(0.2))
                    Capsule()
                        .fill(LinearGradient(colors: [.yellow, .orange], startPoint: .leading, endPoint: .trailing))
                        .frame(width: proxy.size.width * ratio)
                }
            }
            .frame(height: 10)
        }
        .padding()
        .background(.ultraThinMaterial, in: .rect(cornerRadius: 14))
    }

    private func lastCatchCard(kind: GokiKind, at: Date) -> some View {
        HStack(spacing: 14) {
            GokiVisual(kind: kind, size: 56)
            VStack(alignment: .leading, spacing: 4) {
                Text("最近のゴキ")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Text(kind.name).font(.headline)
                Text(at.formatted(.relative(presentation: .named)))
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }
            Spacer()
        }
        .padding()
        .background(.ultraThinMaterial, in: .rect(cornerRadius: 14))
    }
}

private struct MissionRow: View {
    let mission: DailyMission
    let onClaim: () -> Void

    private var ratio: Double {
        guard mission.target > 0 else { return 0 }
        return min(1, Double(mission.progress) / Double(mission.target))
    }

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: DailyMissions.icon(for: mission))
                .font(.title3)
                .foregroundStyle(mission.claimed ? .green : .yellow)
                .frame(width: 32)

            VStack(alignment: .leading, spacing: 4) {
                Text(DailyMissions.title(for: mission))
                    .font(.subheadline.bold())
                ProgressView(value: ratio)
                    .tint(mission.claimed ? .green : .yellow)
                HStack {
                    Text("\(mission.progress)/\(mission.target)")
                        .font(.caption2.monospacedDigit())
                        .foregroundStyle(.secondary)
                    Spacer()
                    HStack(spacing: 3) {
                        Image(systemName: "circle.hexagongrid.fill")
                            .foregroundStyle(.yellow)
                            .font(.caption2)
                        Text("+\(mission.rewardCoins)")
                            .font(.caption.bold().monospacedDigit())
                    }
                }
            }

            if mission.claimed {
                Image(systemName: "checkmark.circle.fill")
                    .foregroundStyle(.green)
                    .font(.title2)
            } else if mission.progress >= mission.target {
                Button(action: onClaim) {
                    Text("受け取る")
                        .font(.caption.bold())
                        .padding(.horizontal, 10)
                        .padding(.vertical, 6)
                        .background(.green, in: .capsule)
                        .foregroundStyle(.white)
                }
                .buttonStyle(.plain)
            }
        }
    }
}

private struct AchievementBadge: View {
    let achievement: Achievement
    let unlocked: Bool

    var body: some View {
        VStack(spacing: 6) {
            Image(systemName: achievement.icon)
                .font(.system(size: 26))
                .foregroundStyle(unlocked ? .yellow : .gray.opacity(0.4))
                .frame(height: 32)
            Text(achievement.title)
                .font(.caption2.bold())
                .foregroundStyle(unlocked ? .primary : .secondary)
                .multilineTextAlignment(.center)
                .lineLimit(2)
            Text(achievement.detail)
                .font(.system(size: 9))
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .lineLimit(2)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 10)
        .padding(.horizontal, 6)
        .background(
            unlocked ? Color.yellow.opacity(0.12) : Color.gray.opacity(0.08),
            in: .rect(cornerRadius: 10)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 10)
                .stroke(unlocked ? Color.yellow.opacity(0.4) : .clear, lineWidth: 1)
        )
    }
}

private struct StatCard: View {
    let label: String
    let value: String
    let unit: String

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(label)
                .font(.caption)
                .foregroundStyle(.secondary)
            HStack(alignment: .firstTextBaseline, spacing: 3) {
                Text(value)
                    .font(.title.bold().monospacedDigit())
                Text(unit)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, 14)
        .padding(.vertical, 12)
        .background(.ultraThinMaterial, in: .rect(cornerRadius: 12))
    }
}
