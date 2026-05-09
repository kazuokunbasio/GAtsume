import SwiftUI
import SwiftData
import SpriteKit

struct RoomView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(filter: #Predicate<FurnitureOwnership> { $0.isActive })
    private var activeFurniture: [FurnitureOwnership]
    @Query private var wallets: [Wallet]
    @Query private var activeBaits: [ActiveBait]
    @Query private var sightings: [SightingRecord]
    @AppStorage("selectedWallpaperId") private var selectedWallpaperId = "default"

    @State private var scene = RoomScene()
    @State private var lastCaught: GokiKind?
    @State private var lastReward: Int = 0
    @State private var now: Date = .now
    @State private var combo: Int = 0
    @State private var comboExpiresAt: Date?
    @State private var flashColor: Color?
    @State private var screenShakeOffset: CGSize = .zero
    @State private var showSuperRareBanner = false

    private let comboWindow: TimeInterval = 3.0

    private var comboActive: Bool {
        guard let expires = comboExpiresAt else { return false }
        return combo > 1 && expires > now
    }

    private var comboProgress: Double {
        guard let expires = comboExpiresAt else { return 0 }
        let remaining = expires.timeIntervalSince(now)
        return max(0, min(1, remaining / comboWindow))
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

    private var paintingEmoji: String {
        let counts = Dictionary(grouping: sightings, by: \.gokiId).mapValues(\.count)
        guard let topId = counts.max(by: { $0.value < $1.value })?.key,
              let kind = allKinds.first(where: { $0.id == topId }) else {
            return "🫘"
        }
        return kind.emoji
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
                .offset(screenShakeOffset)

            if let color = flashColor {
                Rectangle()
                    .fill(color)
                    .ignoresSafeArea()
                    .allowsHitTesting(false)
            }

            HStack(spacing: 8) {
                TimeBadge(now: now)
                if let bait = activeBaitKind, let expiresAt = activeBaitExpiresAt {
                    BaitHUD(bait: bait, expiresAt: expiresAt, now: now)
                }
                Spacer()
                CoinBadge(coins: wallet?.coins ?? 0)
            }
            .padding(.horizontal, 16)
            .padding(.top, 8)

            if let kind = lastCaught {
                CatchToast(kind: kind, reward: lastReward)
                    .padding(.top, 60)
                    .transition(.move(edge: .top).combined(with: .opacity))
            }

            if comboActive {
                ComboBadge(combo: combo, progress: comboProgress)
                    .padding(.top, 110)
                    .transition(.scale.combined(with: .opacity))
            }

            if showSuperRareBanner {
                Text("SUPER RARE!")
                    .font(.system(size: 56, weight: .black))
                    .foregroundStyle(LinearGradient(
                        colors: [.pink, .yellow, .cyan, .purple],
                        startPoint: .leading, endPoint: .trailing
                    ))
                    .shadow(color: .black.opacity(0.4), radius: 12, y: 4)
                    .padding(.top, 200)
                    .transition(.scale(scale: 0.3).combined(with: .opacity))
                    .allowsHitTesting(false)
            }

            if sightings.isEmpty {
                VStack {
                    Spacer()
                    HStack(spacing: 8) {
                        Image(systemName: "hand.tap.fill")
                            .symbolEffect(.pulse, options: .repeat(.continuous))
                        Text("動いてるゴキをタップしてみよう")
                            .font(.subheadline.bold())
                    }
                    .foregroundStyle(.white)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 10)
                    .background(.black.opacity(0.5), in: .capsule)
                    .padding(.bottom, 40)
                }
                .allowsHitTesting(false)
                .transition(.opacity)
            }
        }
        .onAppear {
            scene.scaleMode = .resizeFill
            scene.kinds = allKinds
            scene.furniture = allFurniture
            scene.placedFurniture = placedInfo
            scene.activeBait = activeBaitKind
            scene.wallpaper = selectedWallpaper
            scene.paintingEmoji = paintingEmoji
            scene.refreshFurniture()
            scene.applyWallpaper()
            scene.onCatch = { id in
                handleCatch(id)
            }
            scene.onFurnitureMoved = { id, frac in
                handleFurnitureMove(id: id, fraction: frac)
            }
        }
        .onChange(of: paintingEmoji) { _, newValue in
            scene.paintingEmoji = newValue
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
        if kind.rarity == .superRare {
            shakeScreen()
        }
        DailyMissions.record(.catchGoki(kind.rarity), modelContext: modelContext)
        DailyMissions.record(.earnCoins(reward), modelContext: modelContext)
        showToast(kind, reward: reward)
    }

    private func shakeScreen() {
        let pattern: [(CGFloat, Double)] = [
            (12, 0.05), (-18, 0.07), (16, 0.07),
            (-14, 0.07), (8, 0.06), (0, 0.05)
        ]
        var elapsed: Double = 0
        for (dx, dur) in pattern {
            DispatchQueue.main.asyncAfter(deadline: .now() + elapsed) {
                withAnimation(.easeInOut(duration: dur)) {
                    screenShakeOffset = CGSize(width: dx, height: 0)
                }
            }
            elapsed += dur
        }
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
    let progress: Double

    private var color: Color {
        switch combo {
        case 2: return .yellow
        case 3: return .orange
        default: return .red
        }
    }

    var body: some View {
        VStack(spacing: 4) {
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

            ZStack(alignment: .leading) {
                Capsule()
                    .fill(color.opacity(0.3))
                    .frame(width: 100, height: 3)
                Capsule()
                    .fill(color)
                    .frame(width: 100 * progress, height: 3)
            }
        }
    }
}

private struct TimeBadge: View {
    let now: Date

    private var hour: Int {
        Calendar.current.component(.hour, from: now)
    }

    private var isNight: Bool {
        hour >= 18 || hour < 6
    }

    private var iconName: String {
        if hour >= 18 || hour < 5 { return "moon.stars.fill" }
        if hour < 8 { return "sunrise.fill" }
        if hour >= 16 { return "sunset.fill" }
        return "sun.max.fill"
    }

    private var iconColor: Color {
        if isNight { return .indigo }
        if hour < 8 || hour >= 16 { return .orange }
        return .yellow
    }

    var body: some View {
        HStack(spacing: 4) {
            Image(systemName: iconName)
                .foregroundStyle(iconColor)
                .font(.callout)
            Text(String(format: "%02d:%02d",
                        hour,
                        Calendar.current.component(.minute, from: now)))
                .font(.caption.monospacedDigit().weight(.semibold))
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 5)
        .background(.ultraThinMaterial, in: .capsule)
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
