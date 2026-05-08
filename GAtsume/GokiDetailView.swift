import SwiftUI
import SwiftData

struct GokiDetailView: View {
    let kind: GokiKind
    @Environment(\.dismiss) private var dismiss
    @Query private var sightings: [SightingRecord]
    @AppStorage("favoriteGokiIds") private var favoriteGokiCSV = ""

    @State private var renderedShareImage: Image?

    private let allKinds = GokiLoader.loadAll()

    private var isFavorite: Bool {
        Favorites.parse(favoriteGokiCSV).contains(kind.id)
    }

    private var currentTitle: GameTitle? {
        let ctx = AchievementContext(sightings: sightings, allKinds: allKinds)
        return Titles.currentTitle(ctx)
    }

    private func toggleFavorite() {
        favoriteGokiCSV = Favorites.toggle(kind.id, in: favoriteGokiCSV)
    }

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
                        Text(kind.name).font(.title.bold())
                        rarityBadge
                    }

                    Text(kind.description)
                        .font(.body)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 24)
                        .foregroundStyle(.secondary)

                    VStack(spacing: 10) {
                        DetailRow(label: "好物", value: kind.favoriteFood)
                        if let season = kind.seasonLabel {
                            DetailRow(label: "出現", value: season)
                        }
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
                    Button(action: toggleFavorite) {
                        Image(systemName: isFavorite ? "star.fill" : "star")
                            .foregroundStyle(isFavorite ? .yellow : .secondary)
                    }
                }
                ToolbarItem(placement: .topBarLeading) {
                    if let img = renderedShareImage {
                        ShareLink(
                            item: img,
                            preview: SharePreview(kind.name, image: img)
                        ) {
                            Image(systemName: "square.and.arrow.up")
                        }
                    } else {
                        ProgressView().scaleEffect(0.7)
                    }
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button("閉じる") { dismiss() }
                }
            }
            .task { renderShareImage() }
        }
    }

    @MainActor
    private func renderShareImage() {
        let renderer = ImageRenderer(content: shareCard)
        renderer.scale = 3
        if let ui = renderer.uiImage {
            renderedShareImage = Image(uiImage: ui)
        }
    }

    private var shareCard: some View {
        VStack(spacing: 14) {
            HStack {
                Text("FIRST CAUGHT")
                    .font(.system(size: 10, weight: .bold))
                    .foregroundStyle(.secondary)
                Spacer()
                if let first = matching.first {
                    Text(first.caughtAt.formatted(.dateTime.year().month().day().hour().minute()))
                        .font(.system(size: 10, weight: .semibold).monospacedDigit())
                        .foregroundStyle(.secondary)
                }
            }
            .padding(.horizontal, 24)
            .padding(.top, 18)

            GokiVisual(kind: kind, size: 200)
                .padding(.top, 4)

            VStack(spacing: 6) {
                Text(kind.name)
                    .font(.system(size: 32, weight: .bold))
                Text(kind.rarity.label)
                    .font(.caption.bold())
                    .padding(.horizontal, 12)
                    .padding(.vertical, 4)
                    .background(rarityColor.opacity(0.18), in: .capsule)
                    .foregroundStyle(rarityColor)
            }

            Text(kind.description)
                .font(.subheadline)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 24)
                .foregroundStyle(.secondary)

            HStack(spacing: 14) {
                HStack(spacing: 4) {
                    Text("好物").font(.caption).foregroundStyle(.secondary)
                    Text(kind.favoriteFood).font(.caption.bold())
                }
                if matching.count > 1 {
                    HStack(spacing: 4) {
                        Text("捕獲数").font(.caption).foregroundStyle(.secondary)
                        Text("\(matching.count)匹").font(.caption.bold().monospacedDigit())
                    }
                }
            }

            Spacer()

            VStack(spacing: 6) {
                if let title = currentTitle {
                    HStack(spacing: 4) {
                        Image(systemName: title.icon)
                        Text(title.name)
                    }
                    .font(.caption.bold())
                    .foregroundStyle(.purple)
                }
                Text("#ゴキあつめ")
                    .font(.footnote.bold())
                    .foregroundStyle(.secondary)
            }
            .padding(.bottom, 16)
        }
        .frame(width: 480, height: 600)
        .background(Color(.systemBackground))
        .foregroundStyle(.primary)
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
