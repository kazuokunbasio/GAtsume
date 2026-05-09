import SwiftUI
import SwiftData

struct AchievementDetailView: View {
    @Environment(\.dismiss) private var dismiss
    @Query private var sightings: [SightingRecord]
    private let allKinds = GokiLoader.loadAll()

    private var ctx: AchievementContext {
        AchievementContext(sightings: sightings, allKinds: allKinds)
    }

    private var unlockedCount: Int {
        Achievements.all.filter { $0.check(ctx) }.count
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 16) {
                    summaryHeader
                    LazyVGrid(
                        columns: [GridItem(.adaptive(minimum: 150), spacing: 12)],
                        spacing: 12
                    ) {
                        ForEach(Achievements.all) { ach in
                            AchievementBigCard(
                                achievement: ach,
                                isUnlocked: ach.check(ctx)
                            )
                        }
                    }
                }
                .padding()
            }
            .navigationTitle("達成バッジ")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("閉じる") { dismiss() }
                }
            }
        }
    }

    private var summaryHeader: some View {
        VStack(spacing: 8) {
            Text("\(unlockedCount) / \(Achievements.all.count)")
                .font(.system(size: 44, weight: .bold).monospacedDigit())
                .contentTransition(.numericText(countsDown: false))
            Text("獲得済みバッジ")
                .font(.caption)
                .foregroundStyle(.secondary)
            ProgressView(
                value: Double(unlockedCount),
                total: Double(Achievements.all.count)
            )
            .tint(.yellow)
        }
        .padding()
        .frame(maxWidth: .infinity)
        .background(.ultraThinMaterial, in: .rect(cornerRadius: 16))
    }
}

private struct AchievementBigCard: View {
    let achievement: Achievement
    let isUnlocked: Bool

    var body: some View {
        VStack(spacing: 10) {
            Image(systemName: achievement.icon)
                .font(.system(size: 38))
                .foregroundStyle(isUnlocked ? .yellow : .gray.opacity(0.35))
                .frame(height: 44)

            Text(achievement.title)
                .font(.headline)
                .foregroundStyle(isUnlocked ? .primary : .secondary)
                .multilineTextAlignment(.center)

            Text(achievement.detail)
                .font(.caption)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .lineLimit(2)
                .frame(minHeight: 28)

            Text(isUnlocked ? "達成" : "未達成")
                .font(.caption2.bold())
                .padding(.horizontal, 10)
                .padding(.vertical, 4)
                .background(
                    isUnlocked ? Color.green.opacity(0.18) : Color.gray.opacity(0.15),
                    in: .capsule
                )
                .foregroundStyle(isUnlocked ? .green : .secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 14)
        .padding(.horizontal, 10)
        .background(.ultraThinMaterial, in: .rect(cornerRadius: 14))
        .overlay(
            RoundedRectangle(cornerRadius: 14)
                .stroke(isUnlocked ? .yellow.opacity(0.45) : .clear, lineWidth: 1.5)
        )
    }
}
