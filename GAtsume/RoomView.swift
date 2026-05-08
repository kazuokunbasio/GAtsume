import SwiftUI
import SwiftData
import SpriteKit

struct RoomView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var placed: [PlacedFurniture]

    @State private var scene = RoomScene()
    @State private var lastCaught: GokiKind?

    private let allKinds = GokiLoader.loadAll()
    private let allFurniture = FurnitureLoader.loadAll()

    private var placedIds: [String] {
        placed.map(\.furnitureId)
    }

    var body: some View {
        ZStack(alignment: .top) {
            SpriteView(scene: scene)
                .ignoresSafeArea()

            if let kind = lastCaught {
                CatchToast(kind: kind)
                    .padding(.top, 8)
                    .transition(.move(edge: .top).combined(with: .opacity))
            }
        }
        .onAppear {
            scene.scaleMode = .resizeFill
            scene.kinds = allKinds
            scene.furniture = allFurniture
            scene.placedFurnitureIds = placedIds
            scene.refreshFurniture()
            scene.onCatch = { id in
                let record = SightingRecord(gokiId: id)
                modelContext.insert(record)
                if let kind = allKinds.first(where: { $0.id == id }) {
                    showToast(kind)
                }
            }
        }
        .onChange(of: placedIds) { _, newIds in
            scene.placedFurnitureIds = newIds
            scene.refreshFurniture()
        }
    }

    private func showToast(_ kind: GokiKind) {
        withAnimation(.spring()) { lastCaught = kind }
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.8) {
            withAnimation(.easeOut) { lastCaught = nil }
        }
    }
}

private struct CatchToast: View {
    let kind: GokiKind

    var body: some View {
        HStack(spacing: 10) {
            Text(kind.emoji).font(.system(size: 28))
            VStack(alignment: .leading, spacing: 2) {
                Text("つかまえた！").font(.caption).foregroundStyle(.secondary)
                Text(kind.name).font(.headline)
            }
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 10)
        .background(.ultraThinMaterial, in: .rect(cornerRadius: 14))
        .shadow(radius: 4, y: 2)
    }
}
