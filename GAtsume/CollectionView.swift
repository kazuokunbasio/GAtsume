import SwiftUI
import SwiftData

struct CollectionView: View {
    @Query private var sightings: [SightingRecord]
    private let kinds = GokiLoader.loadAll()

    private var caughtCounts: [String: Int] {
        Dictionary(grouping: sightings, by: \.gokiId).mapValues(\.count)
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                LazyVGrid(
                    columns: [GridItem(.adaptive(minimum: 110), spacing: 12)],
                    spacing: 12
                ) {
                    ForEach(kinds) { kind in
                        CollectionCard(
                            kind: kind,
                            caughtCount: caughtCounts[kind.id] ?? 0
                        )
                    }
                }
                .padding()
            }
            .navigationTitle("図鑑")
        }
    }
}

private struct CollectionCard: View {
    let kind: GokiKind
    let caughtCount: Int

    private var isCaught: Bool { caughtCount > 0 }

    var body: some View {
        VStack(spacing: 6) {
            Text(isCaught ? kind.emoji : "？")
                .font(.system(size: 48))
                .opacity(isCaught ? 1 : 0.25)
                .frame(height: 60)

            Text(isCaught ? kind.name : "？？？")
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(isCaught ? .primary : .secondary)
                .lineLimit(1)

            Text(kind.rarity.label)
                .font(.caption2)
                .foregroundStyle(.secondary)

            if isCaught {
                Text("× \(caughtCount)")
                    .font(.caption2.monospacedDigit())
                    .foregroundStyle(.secondary)
            } else {
                Text(" ")
                    .font(.caption2)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(10)
        .background(.ultraThinMaterial, in: .rect(cornerRadius: 14))
    }
}
