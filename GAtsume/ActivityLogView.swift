import SwiftUI
import SwiftData

struct ActivityLogView: View {
    @Environment(\.dismiss) private var dismiss
    @Query(sort: \SightingRecord.caughtAt, order: .reverse) private var sightings: [SightingRecord]
    private let allKinds = GokiLoader.loadAll()

    private var entries: [Entry] {
        sightings.compactMap { record -> Entry? in
            guard let kind = allKinds.first(where: { $0.id == record.gokiId }) else { return nil }
            return Entry(record: record, kind: kind)
        }
    }

    var body: some View {
        NavigationStack {
            List {
                if entries.isEmpty {
                    Text("まだ何も捕まえていない。")
                        .foregroundStyle(.secondary)
                        .frame(maxWidth: .infinity, alignment: .center)
                        .padding(.vertical, 40)
                } else {
                    ForEach(entries) { entry in
                        ActivityRow(entry: entry)
                    }
                }
            }
            .navigationTitle("活動履歴")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("閉じる") { dismiss() }
                }
            }
        }
    }
}

struct Entry: Identifiable {
    let id = UUID()
    let record: SightingRecord
    let kind: GokiKind
}

private struct ActivityRow: View {
    let entry: Entry

    var body: some View {
        HStack(spacing: 12) {
            GokiVisual(kind: entry.kind, size: 36)

            VStack(alignment: .leading, spacing: 2) {
                Text(entry.kind.name).font(.subheadline.bold())
                Text(entry.kind.rarity.label)
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }

            Spacer()

            VStack(alignment: .trailing, spacing: 2) {
                Text(entry.record.caughtAt.formatted(date: .abbreviated, time: .shortened))
                    .font(.caption.monospacedDigit())
                Text(entry.record.caughtAt.formatted(.relative(presentation: .named)))
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }
        }
    }
}
