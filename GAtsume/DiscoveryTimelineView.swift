import SwiftUI
import SwiftData

struct DiscoveryTimelineView: View {
    @Environment(\.dismiss) private var dismiss
    @Query(sort: \SightingRecord.caughtAt) private var sightings: [SightingRecord]
    private let allKinds = GokiLoader.loadAll()

    private struct MonthGroup: Identifiable {
        let id = UUID()
        let monthStart: Date
        let kinds: [GokiKind]
    }

    private var groups: [MonthGroup] {
        var firstByKind: [String: Date] = [:]
        for s in sightings {
            if firstByKind[s.gokiId] == nil {
                firstByKind[s.gokiId] = s.caughtAt
            }
        }
        let calendar = Calendar.current
        var byMonth: [Date: [GokiKind]] = [:]
        for (id, date) in firstByKind {
            guard let kind = allKinds.first(where: { $0.id == id }) else { continue }
            let comps = calendar.dateComponents([.year, .month], from: date)
            guard let monthStart = calendar.date(from: comps) else { continue }
            byMonth[monthStart, default: []].append(kind)
        }
        return byMonth
            .sorted { $0.key > $1.key }
            .map { MonthGroup(monthStart: $0.key, kinds: $0.value.sorted { $0.name < $1.name }) }
    }

    var body: some View {
        NavigationStack {
            if groups.isEmpty {
                emptyState
            } else {
                ScrollView {
                    VStack(alignment: .leading, spacing: 24) {
                        ForEach(groups) { group in
                            monthSection(group)
                        }
                    }
                    .padding()
                }
            }
        }
    }

    private var emptyState: some View {
        VStack(spacing: 12) {
            Image(systemName: "calendar")
                .font(.system(size: 48))
                .foregroundStyle(.secondary)
            Text("まだ何も発見していない。")
                .font(.headline)
            Text("ゴキを捕まえると年表に記録される。")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .navigationTitle("発見年表")
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button("閉じる") { dismiss() }
            }
        }
    }

    private func monthSection(_ group: MonthGroup) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(alignment: .firstTextBaseline) {
                Text(group.monthStart.formatted(.dateTime.year().month(.wide).locale(.init(identifier: "ja_JP"))))
                    .font(.headline)
                Spacer()
                Text("\(group.kinds.count) 種")
                    .font(.caption.bold().monospacedDigit())
                    .foregroundStyle(.secondary)
            }
            LazyVGrid(
                columns: [GridItem(.adaptive(minimum: 90), spacing: 10)],
                spacing: 10
            ) {
                ForEach(group.kinds) { kind in
                    VStack(spacing: 4) {
                        GokiVisual(kind: kind, size: 44)
                        Text(kind.name)
                            .font(.caption2.bold())
                            .lineLimit(1)
                        Text(kind.rarity.label)
                            .font(.system(size: 9))
                            .foregroundStyle(.secondary)
                    }
                    .padding(8)
                    .frame(maxWidth: .infinity)
                    .background(.ultraThinMaterial, in: .rect(cornerRadius: 10))
                }
            }
        }
    }
}
