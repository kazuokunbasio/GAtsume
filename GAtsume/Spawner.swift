import Foundation

enum Spawner {
    static func pick(
        from kinds: [GokiKind],
        furniture: [FurnitureKind],
        activeFurnitureIds: [String],
        activeBait: BaitKind? = nil,
        now: Date = .now
    ) -> GokiKind? {
        let eligible = kinds.filter { $0.passesTimeFilter(now: now) }
        guard !eligible.isEmpty else { return nil }
        let weighted = eligible.map { kind -> (GokiKind, Double) in
            (kind, weight(
                for: kind,
                furniture: furniture,
                activeIds: activeFurnitureIds,
                activeBait: activeBait
            ))
        }
        let total = weighted.reduce(0.0) { $0 + $1.1 }
        guard total > 0 else { return nil }
        var r = Double.random(in: 0..<total)
        for (kind, w) in weighted {
            if r < w { return kind }
            r -= w
        }
        return weighted.last?.0
    }

    static func weight(
        for goki: GokiKind,
        furniture: [FurnitureKind],
        activeIds: [String],
        activeBait: BaitKind? = nil
    ) -> Double {
        let furnBonus = furniture
            .filter { activeIds.contains($0.id) }
            .reduce(0.0) { $0 + ($1.boosts[goki.id] ?? 0) }
        let baitBonus = activeBait?.boosts[goki.id] ?? 0
        return goki.spawnWeight + furnBonus + baitBonus
    }

    static func coinReward(for rarity: Rarity) -> Int {
        switch rarity {
        case .normal: return 5
        case .rare: return 20
        case .superRare: return 100
        }
    }
}
