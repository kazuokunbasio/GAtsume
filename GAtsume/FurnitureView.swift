import SwiftUI
import SwiftData

struct FurnitureView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var placed: [PlacedFurniture]
    private let kinds = FurnitureLoader.loadAll()

    private var placedIds: Set<String> {
        Set(placed.map(\.furnitureId))
    }

    var body: some View {
        NavigationStack {
            List {
                Section {
                    ForEach(kinds) { item in
                        FurnitureRow(
                            item: item,
                            isPlaced: placedIds.contains(item.id)
                        ) {
                            toggle(item, currentlyPlaced: placedIds.contains(item.id))
                        }
                    }
                } footer: {
                    Text("家具を置くと特定のゴキが集まりやすくなる。")
                        .font(.caption)
                }
            }
            .navigationTitle("家具")
        }
    }

    private func toggle(_ item: FurnitureKind, currentlyPlaced: Bool) {
        if currentlyPlaced {
            for p in placed where p.furnitureId == item.id {
                modelContext.delete(p)
            }
        } else {
            modelContext.insert(PlacedFurniture(furnitureId: item.id))
        }
    }
}

private struct FurnitureRow: View {
    let item: FurnitureKind
    let isPlaced: Bool
    let onToggle: () -> Void

    var body: some View {
        Button(action: onToggle) {
            HStack(spacing: 14) {
                Text(item.emoji)
                    .font(.system(size: 36))
                    .frame(width: 50)

                VStack(alignment: .leading, spacing: 3) {
                    Text(item.name)
                        .font(.headline)
                        .foregroundStyle(.primary)
                    Text(item.description)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                Spacer()

                Image(systemName: isPlaced ? "checkmark.circle.fill" : "circle")
                    .foregroundStyle(isPlaced ? .green : .secondary)
                    .font(.title2)
            }
            .contentShape(.rect)
        }
        .buttonStyle(.plain)
    }
}
