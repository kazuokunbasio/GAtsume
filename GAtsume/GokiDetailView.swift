import SwiftUI
import SwiftData

struct GokiDetailView: View {
    let kind: GokiKind
    @Environment(\.dismiss) private var dismiss
    @Query private var sightings: [SightingRecord]

    private var matching: [SightingRecord] {
        sightings
            .filter { $0.gokiId == kind.id }
            .sorted { $0.caughtAt < $1.caughtAt }
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 22) {
                    GokiVisual(kind: kind, size: 140)
                        .padding(.top, 16)

                    VStack(spacing: 8) {
                        Text(kind.name)
                            .font(.title.bold())
                        rarityBadge
                    }

                    Text(kind.description)
                        .font(.body)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 24)
                        .foregroundStyle(.secondary)

                    VStack(spacing: 10) {
                        DetailRow(label: "好物", value: kind.favoriteFood)
                        DetailRow(label: "捕獲数", value: "\(matching.count) 匹")
                        if let first = matching.first {
                            DetailRow(label: "初回", value: format(first.caughtAt))
                        }
                        if matching.count > 1, let last = matching.last {
                            DetailRow(label: "最近", value: format(last.caughtAt))
                        }
                    }
                    .padding(.horizontal)

                    Spacer(minLength: 16)
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    ShareLink(item: shareText) {
                        Image(systemName: "square.and.arrow.up")
                    }
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button("閉じる") { dismiss() }
                }
            }
        }
    }

    private var shareText: String {
        """
        \(kind.name) (\(kind.rarity.label)) を捕まえた！
        \(kind.description)
        #ゴキあつめ
        """
    }

    private var rarityBadge: some View {
        Text(kind.rarity.label)
            .font(.caption.bold())
            .padding(.horizontal, 10)
            .padding(.vertical, 4)
            .background(rarityColor.opacity(0.18), in: .capsule)
            .foregroundStyle(rarityColor)
    }

    private var rarityColor: Color {
        switch kind.rarity {
        case .normal: return .gray
        case .rare: return .blue
        case .superRare: return .purple
        }
    }

    private func format(_ date: Date) -> String {
        date.formatted(date: .abbreviated, time: .shortened)
    }
}

private struct DetailRow: View {
    let label: String
    let value: String

    var body: some View {
        HStack {
            Text(label)
                .foregroundStyle(.secondary)
            Spacer()
            Text(value)
                .font(.body.weight(.medium))
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(.ultraThinMaterial, in: .rect(cornerRadius: 12))
    }
}
