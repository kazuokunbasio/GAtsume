import SwiftUI
import SwiftData

private enum RarityFilter: String, CaseIterable, Identifiable {
    case all, normal, rare, superRare
    var id: String { rawValue }
    var label: String {
        switch self {
        case .all: return "全て"
        case .normal: return "ノーマル"
        case .rare: return "レア"
        case .superRare: return "超レア"
        }
    }
}

private enum CaughtFilter: String, CaseIterable, Identifiable {
    case all, caught, uncaught
    var id: String { rawValue }
    var label: String {
        switch self {
        case .all: return "全て"
        case .caught: return "発見済み"
        case .uncaught: return "未発見"
        }
    }
}

private enum SortMode: String, CaseIterable, Identifiable {
    case standard, name, rarity, count
    var id: String { rawValue }
    var label: String {
        switch self {
        case .standard: return "通常順"
        case .name: return "名前順"
        case .rarity: return "レア度順"
        case .count: return "捕獲数順"
        }
    }
}

struct CollectionView: View {
    @Query private var sightings: [SightingRecord]
    @AppStorage("favoriteGokiIds") private var favoriteGokiCSV = ""
    @State private var selected: GokiKind?
    @State private var rarityFilter: RarityFilter = .all
    @State private var caughtFilter: CaughtFilter = .all
    @State private var sortMode: SortMode = .standard
    @State private var favoritesOnly = false
    private let kinds = GokiLoader.loadAll()

    private var caughtCounts: [String: Int] {
        Dictionary(grouping: sightings, by: \.gokiId).mapValues(\.count)
    }

    private var favoriteIds: Set<String> {
        Favorites.parse(favoriteGokiCSV)
    }

    private var displayedKinds: [GokiKind] {
        var list = kinds.filter { kind in
            let count = caughtCounts[kind.id] ?? 0
            let passesRarity: Bool = {
                switch rarityFilter {
                case .all: return true
                case .normal: return kind.rarity == .normal
                case .rare: return kind.rarity == .rare
                case .superRare: return kind.rarity == .superRare
                }
            }()
            let passesCaught: Bool = {
                switch caughtFilter {
                case .all: return true
                case .caught: return count > 0
                case .uncaught: return count == 0
                }
            }()
            let passesFav = !favoritesOnly || favoriteIds.contains(kind.id)
            return passesRarity && passesCaught && passesFav
        }
        switch sortMode {
        case .standard: break
        case .name: list.sort { $0.name < $1.name }
        case .rarity:
            list.sort { rarityOrder($0.rarity) < rarityOrder($1.rarity) }
        case .count:
            list.sort { (caughtCounts[$0.id] ?? 0) > (caughtCounts[$1.id] ?? 0) }
        }
        return list
    }

    private func rarityOrder(_ r: Rarity) -> Int {
        switch r {
        case .normal: return 0
        case .rare: return 1
        case .superRare: return 2
        }
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                LazyVGrid(
                    columns: [GridItem(.adaptive(minimum: 110), spacing: 12)],
                    spacing: 12
                ) {
                    ForEach(displayedKinds) { kind in
                        let count = caughtCounts[kind.id] ?? 0
                        Button {
                            if count > 0 { selected = kind }
                        } label: {
                            CollectionCard(
                                kind: kind,
                                caughtCount: count,
                                isFavorite: favoriteIds.contains(kind.id)
                            )
                        }
                        .buttonStyle(.plain)
                        .disabled(count == 0)
                    }
                }
                .padding()
            }
            .navigationTitle("図鑑")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Menu {
                        Toggle("お気に入りのみ", isOn: $favoritesOnly)
                        Picker("レア度", selection: $rarityFilter) {
                            ForEach(RarityFilter.allCases) { r in
                                Text(r.label).tag(r)
                            }
                        }
                        Picker("状態", selection: $caughtFilter) {
                            ForEach(CaughtFilter.allCases) { c in
                                Text(c.label).tag(c)
                            }
                        }
                        Picker("並び替え", selection: $sortMode) {
                            ForEach(SortMode.allCases) { s in
                                Text(s.label).tag(s)
                            }
                        }
                    } label: {
                        Image(systemName: "line.3.horizontal.decrease.circle")
                    }
                }
            }
            .sheet(item: $selected) { kind in
                GokiDetailView(kind: kind)
            }
        }
    }
}

private struct CollectionCard: View {
    let kind: GokiKind
    let caughtCount: Int
    let isFavorite: Bool

    private var isCaught: Bool { caughtCount > 0 }

    var body: some View {
        VStack(spacing: 6) {
            ZStack(alignment: .topTrailing) {
                Group {
                    if isCaught {
                        GokiVisual(kind: kind, size: 56)
                    } else {
                        Text("？")
                            .font(.system(size: 48))
                            .opacity(0.25)
                    }
                }
                .frame(maxWidth: .infinity)
                if isFavorite && isCaught {
                    Image(systemName: "star.fill")
                        .font(.caption)
                        .foregroundStyle(.yellow)
                }
            }
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
