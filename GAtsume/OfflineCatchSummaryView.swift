import SwiftUI

struct OfflineCatchEntry: Identifiable, Hashable {
    let id = UUID()
    let kind: GokiKind
    let count: Int
}

struct OfflineCatchSummary: Identifiable {
    let id = UUID()
    let entries: [OfflineCatchEntry]
    let coinsEarned: Int
    let minutes: Int
}

struct OfflineCatchSummaryView: View {
    let summary: OfflineCatchSummary
    @Environment(\.dismiss) private var dismiss

    private var totalCount: Int {
        summary.entries.reduce(0) { $0 + $1.count }
    }

    private var awayLabel: String {
        let h = summary.minutes / 60
        let m = summary.minutes % 60
        if h > 0 { return "\(h)時間\(m)分" }
        return "\(m)分"
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 22) {
                    Text("おかえり！")
                        .font(.largeTitle.bold())
                        .padding(.top, 12)

                    Text("\(awayLabel) のあいだに")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)

                    Text("\(totalCount) 匹つかまえた")
                        .font(.title2.bold())

                    HStack(spacing: 10) {
                        Image(systemName: "circle.hexagongrid.fill")
                            .foregroundStyle(.yellow)
                            .font(.title2)
                        Text("+\(summary.coinsEarned)")
                            .font(.title.bold().monospacedDigit())
                    }
                    .padding(.horizontal, 18)
                    .padding(.vertical, 12)
                    .background(.yellow.opacity(0.15), in: .rect(cornerRadius: 14))

                    LazyVGrid(
                        columns: [GridItem(.adaptive(minimum: 100), spacing: 10)],
                        spacing: 10
                    ) {
                        ForEach(summary.entries.sorted { $0.count > $1.count }) { entry in
                            VStack(spacing: 4) {
                                GokiVisual(kind: entry.kind, size: 50)
                                Text(entry.kind.name)
                                    .font(.caption)
                                    .lineLimit(1)
                                Text("× \(entry.count)")
                                    .font(.caption2.monospacedDigit())
                                    .foregroundStyle(.secondary)
                            }
                            .padding(8)
                            .frame(maxWidth: .infinity)
                            .background(.ultraThinMaterial, in: .rect(cornerRadius: 12))
                        }
                    }
                    .padding(.horizontal)

                    Spacer(minLength: 16)
                }
                .padding()
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("受け取る") { dismiss() }
                        .font(.body.bold())
                }
            }
        }
    }
}
