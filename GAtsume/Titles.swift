import Foundation

struct GameTitle: Identifiable, Hashable {
    let id: String
    let name: String
    let icon: String
    let priority: Int
    let check: (AchievementContext) -> Bool

    static func == (lhs: GameTitle, rhs: GameTitle) -> Bool { lhs.id == rhs.id }
    func hash(into hasher: inout Hasher) { hasher.combine(id) }
}

enum Titles {
    static let all: [GameTitle] = [
        GameTitle(
            id: "novice",
            name: "見習いG使い",
            icon: "leaf.fill",
            priority: 1,
            check: { $0.totalCatches >= 1 }
        ),
        GameTitle(
            id: "observer",
            name: "G観察員",
            icon: "eye.fill",
            priority: 2,
            check: { $0.totalCatches >= 10 }
        ),
        GameTitle(
            id: "scholar",
            name: "G博士",
            icon: "book.fill",
            priority: 3,
            check: { $0.uniqueIds.count >= 5 }
        ),
        GameTitle(
            id: "enthusiast",
            name: "G愛好家",
            icon: "heart.fill",
            priority: 4,
            check: { $0.totalCatches >= 50 }
        ),
        GameTitle(
            id: "expert",
            name: "G通",
            icon: "flame.fill",
            priority: 5,
            check: { $0.totalCatches >= 100 }
        ),
        GameTitle(
            id: "sage",
            name: "G賢者",
            icon: "sparkles",
            priority: 6,
            check: { ctx in
                let normals = ctx.allKinds.filter { $0.rarity == .normal }
                return !normals.isEmpty && normals.allSatisfy { ctx.uniqueIds.contains($0.id) }
            }
        ),
        GameTitle(
            id: "legend",
            name: "伝説の調教師",
            icon: "crown.fill",
            priority: 7,
            check: { ctx in ctx.caughtKinds.contains { $0.rarity == .superRare } }
        ),
        GameTitle(
            id: "king",
            name: "G王",
            icon: "trophy.fill",
            priority: 8,
            check: { ctx in
                !ctx.allKinds.isEmpty && ctx.allKinds.allSatisfy { ctx.uniqueIds.contains($0.id) }
            }
        )
    ]

    static func currentTitle(_ ctx: AchievementContext) -> GameTitle? {
        all
            .filter { $0.check(ctx) }
            .max(by: { $0.priority < $1.priority })
    }
}
