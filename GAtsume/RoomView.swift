import SwiftUI
import SwiftData
import SpriteKit

struct RoomView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(filter: #Predicate<FurnitureOwnership> { $0.isActive })
    private var activeFurniture: [FurnitureOwnership]
    @Query private var wallets: [Wallet]
    @Query private var activeBaits: [ActiveBait]
    @AppStorage("selectedWallpaperId") private var selectedWallpaperId = "default"

    @State private var scene = RoomScene()
    @State private var lastCaught: GokiKind?
    @State private var lastReward: Int = 0
    @State private var now: Date = .now
    @State private var combo: Int = 0
    @State private var comboExpiresAt: Date?
    @State private var flashColor: Color?

    private let comboWindow: TimeInterval = 3.0

    private var comboActive: Bool {
        guard let expires = comboExpiresAt else { return false }
        return combo > 1 && expires > now
    }

    private func multiplier(forCombo combo: Int) -> Double {
        switch combo {
        case ..<2: return 1.0
        case 2: return 1.5
        case 3: return 2.0
        default: return 3.0
        }
    }

    private let allKinds = GokiLoader.loadAll()
    private let allFurniture = FurnitureLoader.loadAll()
    private let allBaits = BaitLoader.loadAll()
    private let allWallpapers = WallpaperLoader.loadAll()

    private var selectedWallpaper: WallpaperKind? {
        allWallpapers.first { $0.id == selectedWallpaperId }
            ?? allWallpapers.first
    }

    private var activeIds: [String] {
        activeFurniture.map(\.furnitureId)
    }
    private var placedInfo: [PlacedFurnitureInfo] {
        activeFurniture.map { ownership in
            let frac: CGPoint?
            if let x = ownership.positionXFraction, let y = ownership.positionYFraction {
                frac = CGPoint(x: x, y: y)
            } else {
                frac = nil
            }
            return PlacedFurnitureInfo(furnitureId: ownership.furnitureId, positionFraction: frac)
        }
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

            if let color = flashColor {
                Rectangle()
                    .fill(color)
                    .ignoresSafeArea()
                    .allowsHitTesting(false)
            }

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

            if comboActive {
                ComboBadge(combo: combo)
                    .padding(.top, 110)
                    .transition(.scale.combined(with: .opacity))
            }
        }
        .onAppear {
            scene.scaleMode = .resizeFill
            scene.kinds = allKinds
            scene.furniture = allFurniture
            scene.placedFurniture = placedInfo
            scene.activeBait = activeBaitKind
            scene.wallpaper = selectedWallpaper
            scene.refreshFurniture()
            scene.applyWallpaper()
            scene.onCatch = { id in
                handleCatch(id)
            }
            scene.onFurnitureMoved = { id, frac in
                handleFurnitureMove(id: id, fraction: frac)
            }
        }
        .onChange(of: placedInfo) { _, newInfo in
            scene.placedFurniture = newInfo
            scene.refreshFurniture()
        }
        .onChange(of: activeBaitKind) { _, newBait in
            scene.activeBait = newBait
        }
        .onChange(of: selectedWallpaperId) { _, _ in
            scene.wallpaper = selectedWallpaper
            scene.applyWallpaper()
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

        let nowDate = Date.now
        if let expires = comboExpiresAt, expires > nowDate {
            combo += 1
        } else {
            combo = 1
        }
        comboExpiresAt = nowDate.addingTimeInterval(comboWindow)

        let baseReward = Spawner.coinReward(for: kind.rarity)
        let reward = Int(Double(baseReward) * multiplier(forCombo: combo))
        wallet?.coins += reward

        switch kind.rarity {
        case .normal: Sounds.catchNormal()
        case .rare: Sounds.catchRare()
        case .superRare: Sounds.catchSuperRare()
        }
        flash(for: kind.rarity)
        DailyMissions.record(.catchGoki(kind.rarity), modelContext: modelContext)
        DailyMissions.record(.earnCoins(reward), modelContext: modelContext)
        showToast(kind, reward: reward)
    }

    private func flash(for rarity: Rarity) {
        let color: Color?
        switch rarity {
        case .normal: color = nil
        case .rare: color = .white.opacity(0.25)
        case .superRare: color = .yellow.opacity(0.45)
        }
        guard let c = color else { return }
        withAnimation(.easeOut(duration: 0.05)) { flashColor = c }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.12) {
            withAnimation(.easeIn(duration: 0.5)) { flashColor = nil }
        }
    }

    private func handleFurnitureMove(id: String, fraction: CGPoint) {
        if let ownership = activeFurniture.first(where: { $0.furnitureId == id }) {
            ownership.positionXFraction = fraction.x
            ownership.positionYFraction = fraction.y
        }
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

private struct ComboBadge: View {
    let combo: Int

    private var color: Color {
        switch combo {
        case 2: return .yellow
        case 3: return .orange
        default: return .red
        }
    }

    var body: some View {
        HStack(spacing: 4) {
            Image(systemName: "flame.fill")
                .font(.callout)
            Text("Combo ×\(combo)")
                .font(.title3.bold().monospacedDigit())
        }
        .foregroundStyle(.white)
        .padding(.horizontal, 14)
        .padding(.vertical, 8)
        .background(color, in: .capsule)
        .shadow(color: color.opacity(0.4), radius: 8)
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
