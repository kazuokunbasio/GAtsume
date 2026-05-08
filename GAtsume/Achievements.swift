import Foundation

struct AchievementContext {
    let sightings: [SightingRecord]
    let allKinds: [GokiKind]

    var totalCatches: Int { sightings.count }

    var uniqueIds: Set<String> {
        Set(sightings.map(\.gokiId))
    }

    var caughtKinds: [GokiKind] {
        allKinds.filter { uniqueIds.contains($0.id) }
    }
}

struct Achievement: Identifiable, Hashable {
    let id: String
    let title: String
    let detail: String
    let icon: String
    let check: (AchievementContext) -> Bool

    static func == (lhs: Achievement, rhs: Achievement) -> Bool {
        lhs.id == rhs.id
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
}

enum Achievements {
    static let all: [Achievement] = [
        Achievement(
            id: "first_catch",
            title: "初めての友",
            detail: "最初の1匹を捕獲",
            icon: "star",
            check: { $0.totalCatches >= 1 }
        ),
        Achievement(
            id: "five_unique",
            title: "なかま5種",
            detail: "5種類のゴキを発見",
            icon: "person.3.fill",
            check: { $0.uniqueIds.count >= 5 }
        ),
        Achievement(
            id: "ten_catches",
            title: "そこそこの友",
            detail: "10匹捕獲",
            icon: "star.fill",
            check: { $0.totalCatches >= 10 }
        ),
        Achievement(
            id: "find_rare",
            title: "珍客発見",
            detail: "レア種を1匹捕獲",
            icon: "sparkles",
            check: { ctx in ctx.caughtKinds.contains { $0.rarity == .rare } }
        ),
        Achievement(
            id: "find_nocturnal",
            title: "夜の住人",
            detail: "夜行性のゴキを発見",
            icon: "moon.fill",
            check: { ctx in ctx.caughtKinds.contains { $0.period == "night" } }
        ),
        Achievement(
            id: "find_super_rare",
            title: "伝説目撃",
            detail: "超レア種を1匹捕獲",
            icon: "crown.fill",
            check: { ctx in ctx.caughtKinds.contains { $0.rarity == .superRare } }
        ),
        Achievement(
            id: "all_normal",
            title: "ノーマル制覇",
            detail: "全ノーマル種を捕獲",
            icon: "checkmark.seal.fill",
            check: { ctx in
                let normals = ctx.allKinds.filter { $0.rarity == .normal }
                return !normals.isEmpty && normals.allSatisfy { ctx.uniqueIds.contains($0.id) }
            }
        ),
        Achievement(
            id: "hundred_catches",
            title: "G通",
            detail: "100匹捕獲",
            icon: "flame.fill",
            check: { $0.totalCatches >= 100 }
        ),
        Achievement(
            id: "complete",
            title: "完全コンプリート",
            detail: "全種コンプリート",
            icon: "trophy.fill",
            check: { ctx in
                !ctx.allKinds.isEmpty && ctx.allKinds.allSatisfy { ctx.uniqueIds.contains($0.id) }
            }
        )
    ]
}
