import SwiftUI
import SwiftData

struct FurnitureView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var ownerships: [FurnitureOwnership]
    @Query private var wallets: [Wallet]
    @Query private var inventories: [BaitInventory]
    @Query private var activeBaits: [ActiveBait]
    @Query private var wallpaperOwnerships: [WallpaperOwnership]
    @AppStorage("selectedWallpaperId") private var selectedWallpaperId = "default"

    private let furnitureKinds = FurnitureLoader.loadAll()
    private let baitKinds = BaitLoader.loadAll()
    private let wallpaperKinds = WallpaperLoader.loadAll()

    private var ownedWallpaperIds: Set<String> {
        Set(wallpaperOwnerships.map(\.wallpaperId))
    }

    private var ownershipMap: [String: FurnitureOwnership] {
        Dictionary(uniqueKeysWithValues: ownerships.map { ($0.furnitureId, $0) })
    }
    private var inventoryMap: [String: BaitInventory] {
        Dictionary(uniqueKeysWithValues: inventories.map { ($0.baitId, $0) })
    }
    private var wallet: Wallet? { wallets.first }
    private var coins: Int { wallet?.coins ?? 0 }
    private var hasActiveBait: Bool {
        guard let active = activeBaits.first else { return false }
        return active.expiresAt > .now
    }

    var body: some View {
        NavigationStack {
            List {
                Section {
                    ForEach(furnitureKinds) { item in
                        FurnitureRow(
                            item: item,
                            ownership: ownershipMap[item.id],
                            canAfford: coins >= item.price,
                            onBuy: { buy(item) },
                            onToggle: { toggle(item) }
                        )
                    }
                } header: {
                    Text("家具")
                } footer: {
                    Text("家具を置くと特定のゴキが集まりやすくなる。")
                        .font(.caption)
                }

                Section {
                    ForEach(baitKinds) { item in
                        BaitRow(
                            item: item,
                            owned: inventoryMap[item.id]?.count ?? 0,
                            canAfford: coins >= item.price,
                            isAnyBaitActive: hasActiveBait,
                            onBuy: { buyBait(item) },
                            onUse: { useBait(item) }
                        )
                    }
                } header: {
                    Text("エサ")
                } footer: {
                    Text("エサは時間限定でゴキを引き寄せる。同時に効くのは1種類だけ。")
                        .font(.caption)
                }

                Section {
                    ForEach(wallpaperKinds) { item in
                        WallpaperRow(
                            item: item,
                            isOwned: ownedWallpaperIds.contains(item.id),
                            isSelected: selectedWallpaperId == item.id,
                            canAfford: coins >= item.price,
                            onBuy: { buyWallpaper(item) },
                            onSelect: { selectedWallpaperId = item.id }
                        )
                    }
                } header: {
                    Text("壁紙")
                } footer: {
                    Text("購入した壁紙はタップで切り替え可能。部屋の見た目が変わる。")
                        .font(.caption)
                }
            }
            .navigationTitle("家具・エサ")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    CoinBadge(coins: coins)
                }
            }
        }
    }

    private func buy(_ item: FurnitureKind) {
        guard let wallet, wallet.coins >= item.price else { return }
        guard ownershipMap[item.id] == nil else { return }
        wallet.coins -= item.price
        modelContext.insert(FurnitureOwnership(furnitureId: item.id, isActive: true))
        Sounds.purchase()
    }

    private func toggle(_ item: FurnitureKind) {
        guard let owner = ownershipMap[item.id] else { return }
        owner.isActive.toggle()
    }

    private func buyBait(_ item: BaitKind) {
        guard let wallet, wallet.coins >= item.price else { return }
        wallet.coins -= item.price
        if let inv = inventoryMap[item.id] {
            inv.count += 1
        } else {
            modelContext.insert(BaitInventory(baitId: item.id, count: 1))
        }
        Sounds.purchase()
    }

    private func useBait(_ item: BaitKind) {
        guard let inv = inventoryMap[item.id], inv.count > 0 else { return }
        inv.count -= 1
        for old in activeBaits {
            modelContext.delete(old)
        }
        let expires = Date.now.addingTimeInterval(TimeInterval(item.durationSec))
        modelContext.insert(ActiveBait(baitId: item.id, expiresAt: expires))
        Sounds.purchase()
        DailyMissions.record(.useBait, modelContext: modelContext)
    }

    private func buyWallpaper(_ item: WallpaperKind) {
        guard !ownedWallpaperIds.contains(item.id) else { return }
        if item.price > 0 {
            guard let wallet, wallet.coins >= item.price else { return }
            wallet.coins -= item.price
        }
        modelContext.insert(WallpaperOwnership(wallpaperId: item.id))
        Sounds.purchase()
    }
}

private struct WallpaperRow: View {
    let item: WallpaperKind
    let isOwned: Bool
    let isSelected: Bool
    let canAfford: Bool
    let onBuy: () -> Void
    let onSelect: () -> Void

    var body: some View {
        Button {
            if isOwned { onSelect() } else if canAfford { onBuy() }
        } label: {
            HStack(spacing: 14) {
                ZStack {
                    if let bgName = item.bgImage, let ui = UIImage(named: bgName) {
                        Image(uiImage: ui)
                            .resizable()
                            .scaledToFill()
                            .frame(width: 50, height: 50)
                            .clipShape(RoundedRectangle(cornerRadius: 10))
                    } else {
                        RoundedRectangle(cornerRadius: 10)
                            .fill(swatchColor)
                            .frame(width: 50, height: 50)
                    }
                    Text(item.emoji)
                        .font(.title2)
                }

                VStack(alignment: .leading, spacing: 3) {
                    Text(item.name).font(.headline)
                    Text(isOwned ? "購入済み" : "未購入")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                Spacer()

                if isOwned {
                    Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                        .foregroundStyle(isSelected ? .green : .secondary)
                        .font(.title2)
                } else {
                    HStack(spacing: 3) {
                        Image(systemName: "circle.hexagongrid.fill")
                            .foregroundStyle(.yellow)
                            .font(.caption2)
                        Text("\(item.price)")
                            .font(.caption.bold().monospacedDigit())
                    }
                    .padding(.horizontal, 10)
                    .padding(.vertical, 6)
                    .background(canAfford ? Color.yellow.opacity(0.85) : Color.gray.opacity(0.25), in: .capsule)
                    .foregroundStyle(canAfford ? .black : .secondary)
                }
            }
            .contentShape(.rect)
        }
        .buttonStyle(.plain)
        .disabled(!isOwned && !canAfford)
    }

    private var swatchColor: Color {
        Color(red: item.bgColor[0], green: item.bgColor[1], blue: item.bgColor[2])
    }
}

struct CoinBadge: View {
    let coins: Int

    var body: some View {
        HStack(spacing: 4) {
            Image(systemName: "circle.hexagongrid.fill")
                .foregroundStyle(.yellow)
            Text("\(coins)")
                .font(.subheadline.monospacedDigit().weight(.semibold))
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 5)
        .background(.ultraThinMaterial, in: .capsule)
    }
}

private struct FurnitureRow: View {
    let item: FurnitureKind
    let ownership: FurnitureOwnership?
    let canAfford: Bool
    let onBuy: () -> Void
    let onToggle: () -> Void

    var body: some View {
        HStack(spacing: 14) {
            Text(item.emoji)
                .font(.system(size: 36))
                .frame(width: 50)

            VStack(alignment: .leading, spacing: 3) {
                Text(item.name).font(.headline)
                Text(item.description)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Spacer()
            trailing
        }
        .contentShape(.rect)
    }

    @ViewBuilder
    private var trailing: some View {
        if let owner = ownership {
            Button(action: onToggle) {
                Image(systemName: owner.isActive ? "checkmark.circle.fill" : "circle")
                    .foregroundStyle(owner.isActive ? .green : .secondary)
                    .font(.title2)
            }
            .buttonStyle(.plain)
        } else {
            Button(action: onBuy) {
                priceBadge
            }
            .buttonStyle(.plain)
            .disabled(!canAfford)
        }
    }

    private var priceBadge: some View {
        HStack(spacing: 3) {
            Image(systemName: "circle.hexagongrid.fill")
                .foregroundStyle(.yellow)
                .font(.caption2)
            Text("\(item.price)")
                .font(.caption.bold().monospacedDigit())
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 6)
        .background(canAfford ? Color.yellow.opacity(0.85) : Color.gray.opacity(0.25), in: .capsule)
        .foregroundStyle(canAfford ? .black : .secondary)
    }
}

private struct BaitRow: View {
    let item: BaitKind
    let owned: Int
    let canAfford: Bool
    let isAnyBaitActive: Bool
    let onBuy: () -> Void
    let onUse: () -> Void

    var body: some View {
        HStack(spacing: 14) {
            Text(item.emoji)
                .font(.system(size: 36))
                .frame(width: 50)

            VStack(alignment: .leading, spacing: 3) {
                HStack(spacing: 6) {
                    Text(item.name).font(.headline)
                    if owned > 0 {
                        Text("× \(owned)")
                            .font(.caption.monospacedDigit())
                            .foregroundStyle(.secondary)
                    }
                }
                Text(item.description)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Spacer()

            VStack(spacing: 6) {
                Button(action: onBuy) {
                    HStack(spacing: 3) {
                        Image(systemName: "circle.hexagongrid.fill")
                            .foregroundStyle(.yellow)
                            .font(.caption2)
                        Text("\(item.price)")
                            .font(.caption.bold().monospacedDigit())
                    }
                    .padding(.horizontal, 10)
                    .padding(.vertical, 6)
                    .background(canAfford ? Color.yellow.opacity(0.85) : Color.gray.opacity(0.25), in: .capsule)
                    .foregroundStyle(canAfford ? .black : .secondary)
                }
                .buttonStyle(.plain)
                .disabled(!canAfford)

                Button(action: onUse) {
                    Text(isAnyBaitActive ? "使用中" : "使う")
                        .font(.caption.bold())
                        .padding(.horizontal, 10)
                        .padding(.vertical, 5)
                        .background(useEnabled ? Color.green.opacity(0.85) : Color.gray.opacity(0.25), in: .capsule)
                        .foregroundStyle(useEnabled ? .white : .secondary)
                }
                .buttonStyle(.plain)
                .disabled(!useEnabled)
            }
        }
        .contentShape(.rect)
    }

    private var useEnabled: Bool {
        owned > 0 && !isAnyBaitActive
    }
}
