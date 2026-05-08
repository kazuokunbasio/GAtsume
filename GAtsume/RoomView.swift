import SwiftUI
import SwiftData
import SpriteKit

struct RoomView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(filter: #Predicate<FurnitureOwnership> { $0.isActive })
    private var activeFurniture: [FurnitureOwnership]
    @Query private var wallets: [Wallet]
    @Query private var activeBaits: [ActiveBait]

    @State private var scene = RoomScene()
    @State private var lastCaught: GokiKind?
    @State private var lastReward: Int = 0
    @State private var now: Date = .now

    private let allKinds = GokiLoader.loadAll()
    private let allFurniture = FurnitureLoader.loadAll()
    private let allBaits = BaitLoader.loadAll()

    private var activeIds: [String] {
        activeFurniture.map(\.furnitureId)
    }
    private var wallet: Wallet? { wallets.first }

    private var activeBaitKind: BaitKind? {
        guard let active = activeBaits.first, active.expiresAt > now else { return nil }
        return allBaits.first { $0.id == active.baitId }
    }

    private var activeBaitExpiresAt: Date? {
        activeBaits.first.flatMap { $0.expiresAt > now ? $0.expiresAt : nil }
    }

    var body: some View {
        ZStack(alignment: .top) {
            SpriteView(scene: scene)
                .ignoresSafeArea(edges: .top)

            HStack {
                if let bait = activeBaitKind, let expiresAt = activeBaitExpiresAt {
                    BaitHUD(bait: bait, expiresAt: expiresAt, now: now)
                        .padding(.leading, 16)
                }
                Spacer()
                CoinBadge(coins: wallet?.coins ?? 0)
                    .padding(.trailing, 16)
            }
            .padding(.top, 8)

            if let kind = lastCaught {
                CatchToast(kind: kind, reward: lastReward)
                    .padding(.top, 60)
                    .transition(.move(edge: .top).combined(with: .opacity))
            }
        }
        .onAppear {
            scene.scaleMode = .resizeFill
            scene.kinds = allKinds
            scene.furniture = allFurniture
            scene.placedFurnitureIds = activeIds
            scene.activeBait = activeBaitKind
            scene.refreshFurniture()
            scene.onCatch = { id in
                handleCatch(id)
            }
        }
        .onChange(of: activeIds) { _, newIds in
            scene.placedFurnitureIds = newIds
            scene.refreshFurniture()
        }
        .onChange(of: activeBaitKind) { _, newBait in
            scene.activeBait = newBait
        }
        .task {
            while !Task.isCancelled {
                try? await Task.sleep(for: .seconds(1))
                now = .now
            }
        }
    }

    private func handleCatch(_ id: String) {
        let record = SightingRecord(gokiId: id)
        modelContext.insert(record)

        guard let kind = allKinds.first(where: { $0.id == id }) else { return }
        let reward = Spawner.coinReward(for: kind.rarity)
        wallet?.coins += reward
        switch kind.rarity {
        case .normal: Sounds.catchNormal()
        case .rare: Sounds.catchRare()
        case .superRare: Sounds.catchSuperRare()
        }
        DailyMissions.record(.catchGoki(kind.rarity), modelContext: modelContext)
        DailyMissions.record(.earnCoins(reward), modelContext: modelContext)
        showToast(kind, reward: reward)
    }

    private func showToast(_ kind: GokiKind, reward: Int) {
        withAnimation(.spring()) {
            lastCaught = kind
            lastReward = reward
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.8) {
            withAnimation(.easeOut) { lastCaught = nil }
        }
    }
}

private struct CatchToast: View {
    let kind: GokiKind
    let reward: Int

    var body: some View {
        HStack(spacing: 10) {
            GokiVisual(kind: kind, size: 32)
            VStack(alignment: .leading, spacing: 2) {
                Text("つかまえた！").font(.caption).foregroundStyle(.secondary)
                Text(kind.name).font(.headline)
            }
            HStack(spacing: 3) {
                Image(systemName: "circle.hexagongrid.fill")
                    .foregroundStyle(.yellow)
                    .font(.caption)
                Text("+\(reward)")
                    .font(.subheadline.bold().monospacedDigit())
            }
            .padding(.leading, 4)
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 10)
        .background(.ultraThinMaterial, in: .rect(cornerRadius: 14))
        .shadow(radius: 4, y: 2)
    }
}

private struct BaitHUD: View {
    let bait: BaitKind
    let expiresAt: Date
    let now: Date

    private var remainingLabel: String {
        let total = max(0, Int(expiresAt.timeIntervalSince(now)))
        let m = total / 60
        let s = total % 60
        return String(format: "%d:%02d", m, s)
    }

    var body: some View {
        HStack(spacing: 6) {
            Text(bait.emoji).font(.title3)
            Text(remainingLabel)
                .font(.subheadline.monospacedDigit().weight(.semibold))
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 5)
        .background(.ultraThinMaterial, in: .capsule)
    }
}

struct GokiVisual: View {
    let kind: GokiKind
    let size: CGFloat

    var body: some View {
        if let name = kind.imageName, let uiImage = UIImage(named: name) {
            Image(uiImage: uiImage)
                .resizable()
                .scaledToFit()
                .frame(width: size, height: size)
        } else {
            Text(kind.emoji)
                .font(.system(size: size * 0.85))
                .frame(width: size, height: size)
        }
    }
}
