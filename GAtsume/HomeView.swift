import SwiftUI
import SwiftData
import Charts

struct HomeView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var sightings: [SightingRecord]
    @Query private var wallets: [Wallet]
    @Query private var dailyLogins: [DailyLogin]
    @Query(sort: \DailyMission.kind) private var todayMissions: [DailyMission]
    @State private var showActivityLog = false
    @State private var showTimeline = false
    @AppStorage("homeShowChart") private var homeShowChart = true
    @AppStorage("homeShowAchievements") private var homeShowAchievements = true
    @AppStorage("homeShowActivity") private var homeShowActivity = true
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

    private var last7Days: [DayCount] {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: .now)
        return (0..<7).reversed().compactMap { offset in
            guard let date = calendar.date(byAdding: .day, value: -offset, to: today) else {
                return nil
            }
            let count = sightings.filter {
                calendar.isDate($0.caughtAt, inSameDayAs: date)
            }.count
            return DayCount(date: date, count: count)
        }
    }

    private var achievementCtx: AchievementContext {
        AchievementContext(sightings: sightings, allKinds: allKinds)
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 16) {
                    coinHero
                    if let title = Titles.currentTitle(achievementCtx) {
                        titleBadge(title)
                    }
                    if !seasonalKinds.isEmpty {
                        seasonalBanner
                    }
                    if let login = dailyLogins.first, login.lastClaimDate == DailyKey.today() {
                        loginBanner(streak: login.streak)
                    }
                    if !todayMissionsFiltered.isEmpty {
                        missionsSection
                    }
                    statsGrid
                    if homeShowChart {
                        weeklyChart
                    }
                    if homeShowActivity {
                        recentActivity
                    }
                    if let last = lastCatch {
                        lastCatchCard(kind: last.kind, at: last.at)
                    }
                    progressBar
                    if homeShowAchievements {
                        achievementsSection
                    }
                    timelineButton
                }
                .padding()
            }
            .navigationTitle("ゴキあつめ")
            .sheet(isPresented: $showActivityLog) {
                ActivityLogView()
            }
            .sheet(isPresented: $showTimeline) {
                DiscoveryTimelineView()
            }
        }
    }

    private var timelineButton: some View {
        Button {
            showTimeline = true
        } label: {
            HStack {
                Image(systemName: "calendar")
                Text("発見年表を見る")
                    .font(.subheadline.bold())
                Spacer()
                Image(systemName: "chevron.right")
                    .foregroundStyle(.secondary)
            }
            .padding()
            .background(.ultraThinMaterial, in: .rect(cornerRadius: 12))
        }
        .buttonStyle(.plain)
        .foregroundStyle(.primary)
    }

    private var seasonalKinds: [GokiKind] {
        let m = Calendar.current.component(.month, from: .now)
        return allKinds.filter { kind in
            guard let months = kind.availableMonths else { return false }
            return months.contains(m)
        }
    }

    private var seasonalBanner: some View {
        HStack(spacing: 12) {
            HStack(spacing: 4) {
                ForEach(seasonalKinds.prefix(4)) { k in
                    GokiVisual(kind: k, size: 32)
                }
            }
            VStack(alignment: .leading, spacing: 2) {
                Text("今月の限定")
                    .font(.caption.bold())
                    .foregroundStyle(.pink)
                Text("\(seasonalKinds.count)種が出現中")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }
            Spacer()
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 10)
        .background(.pink.opacity(0.12), in: .rect(cornerRadius: 12))
    }

    private func titleBadge(_ title: GameTitle) -> some View {
        HStack(spacing: 10) {
            Image(systemName: title.icon)
                .foregroundStyle(.purple)
                .font(.title3)
            VStack(alignment: .leading, spacing: 2) {
                Text("称号")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                Text(title.name)
                    .font(.headline)
            }
            Spacer()
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 10)
        .background(.purple.opacity(0.1), in: .rect(cornerRadius: 12))
    }

    private var recentActivity: some View {
        let recent = sightings
            .sorted { $0.caughtAt > $1.caughtAt }
            .prefix(5)
        return VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text("最近の活動")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Spacer()
                if !sightings.isEmpty {
                    Button("もっと見る") { showActivityLog = true }
                        .font(.caption.bold())
                }
            }
            if recent.isEmpty {
                Text("まだ何も捕まえていない。")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding(.vertical, 16)
            } else {
                ForEach(Array(recent), id: \.id) { record in
                    if let kind = allKinds.first(where: { $0.id == record.gokiId }) {
                        recentRow(kind: kind, at: record.caughtAt)
                    }
                }
            }
        }
        .padding()
        .background(.ultraThinMaterial, in: .rect(cornerRadius: 14))
    }

    private func recentRow(kind: GokiKind, at: Date) -> some View {
        HStack(spacing: 10) {
            GokiVisual(kind: kind, size: 32)
            Text(kind.name)
                .font(.subheadline)
            Spacer()
            Text(at.formatted(.relative(presentation: .named)))
                .font(.caption2)
                .foregroundStyle(.secondary)
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

    private var weeklyChart: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text("過去7日の捕獲")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Spacer()
                let total = last7Days.reduce(0) { $0 + $1.count }
                Text("計 \(total) 匹")
                    .font(.caption.bold().monospacedDigit())
                    .foregroundStyle(.secondary)
            }
            Chart(last7Days) { day in
                BarMark(
                    x: .value("日", day.date, unit: .day),
                    y: .value("匹", day.count)
                )
                .foregroundStyle(.yellow.gradient)
                .cornerRadius(4)
            }
            .chartXAxis {
                AxisMarks(values: .stride(by: .day)) { value in
                    AxisValueLabel(format: .dateTime.day().locale(.init(identifier: "ja_JP")))
                        .font(.caption2)
                }
            }
            .chartYAxis {
                AxisMarks(position: .leading) { _ in
                    AxisGridLine()
                    AxisValueLabel().font(.caption2)
                }
            }
            .frame(height: 140)
        }
        .padding()
        .background(.ultraThinMaterial, in: .rect(cornerRadius: 14))
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

private struct DayCount: Identifiable {
    let id = UUID()
    let date: Date
    let count: Int
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
