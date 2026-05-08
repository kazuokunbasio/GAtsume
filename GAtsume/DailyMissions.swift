import Foundation
import SwiftData

enum MissionKind: String {
    case catchTotal = "catch_total"
    case catchNormal = "catch_normal"
    case catchRare = "catch_rare"
    case earnCoins = "earn_coins"
    case useBait = "use_bait"
}

enum MissionEvent {
    case catchGoki(Rarity)
    case earnCoins(Int)
    case useBait
}

struct MissionTemplate {
    let kind: MissionKind
    let title: (Int) -> String
    let icon: String
    let targets: ClosedRange<Int>
    let rewardForTarget: (Int) -> Int
}

enum DailyMissions {
    static let templates: [MissionTemplate] = [
        MissionTemplate(
            kind: .catchTotal,
            title: { "ゴキを\($0)匹捕獲" },
            icon: "hand.tap.fill",
            targets: 5...12,
            rewardForTarget: { $0 * 3 }
        ),
        MissionTemplate(
            kind: .catchNormal,
            title: { "ノーマル種を\($0)匹" },
            icon: "circle.fill",
            targets: 3...8,
            rewardForTarget: { $0 * 4 }
        ),
        MissionTemplate(
            kind: .catchRare,
            title: { "レア種を\($0)匹捕獲" },
            icon: "sparkles",
            targets: 1...2,
            rewardForTarget: { $0 * 25 }
        ),
        MissionTemplate(
            kind: .earnCoins,
            title: { "\($0)コイン稼ぐ" },
            icon: "circle.hexagongrid.fill",
            targets: 30...80,
            rewardForTarget: { Int(Double($0) * 0.5) }
        ),
        MissionTemplate(
            kind: .useBait,
            title: { _ in "エサを使う" },
            icon: "fork.knife",
            targets: 1...1,
            rewardForTarget: { _ in 30 }
        )
    ]

    static func ensureToday(modelContext: ModelContext) {
        let today = DailyKey.today()
        let descriptor = FetchDescriptor<DailyMission>(
            predicate: #Predicate { $0.dateKey == today }
        )
        let existing = (try? modelContext.fetch(descriptor)) ?? []
        guard existing.isEmpty else { return }

        purgeOld(today: today, modelContext: modelContext)

        let pool = templates.shuffled().prefix(3)
        for template in pool {
            let target = Int.random(in: template.targets)
            let mission = DailyMission(
                dateKey: today,
                kind: template.kind.rawValue,
                target: target,
                rewardCoins: template.rewardForTarget(target)
            )
            modelContext.insert(mission)
        }
    }

    private static func purgeOld(today: String, modelContext: ModelContext) {
        let descriptor = FetchDescriptor<DailyMission>(
            predicate: #Predicate { $0.dateKey != today }
        )
        let old = (try? modelContext.fetch(descriptor)) ?? []
        for m in old { modelContext.delete(m) }
    }

    static func record(_ event: MissionEvent, modelContext: ModelContext) {
        let today = DailyKey.today()
        let descriptor = FetchDescriptor<DailyMission>(
            predicate: #Predicate { $0.dateKey == today && !$0.claimed }
        )
        let missions = (try? modelContext.fetch(descriptor)) ?? []

        for mission in missions where mission.progress < mission.target {
            let inc = increment(for: event, missionKind: mission.kind)
            if inc > 0 {
                mission.progress = min(mission.target, mission.progress + inc)
            }
        }
    }

    private static func increment(for event: MissionEvent, missionKind: String) -> Int {
        guard let kind = MissionKind(rawValue: missionKind) else { return 0 }
        switch (event, kind) {
        case (.catchGoki, .catchTotal): return 1
        case (.catchGoki(.normal), .catchNormal): return 1
        case (.catchGoki(.rare), .catchRare): return 1
        case (.catchGoki(.superRare), .catchRare): return 1
        case (.earnCoins(let n), .earnCoins): return n
        case (.useBait, .useBait): return 1
        default: return 0
        }
    }

    static func title(for mission: DailyMission) -> String {
        guard let kind = MissionKind(rawValue: mission.kind),
              let template = templates.first(where: { $0.kind == kind }) else {
            return mission.kind
        }
        return template.title(mission.target)
    }

    static func icon(for mission: DailyMission) -> String {
        guard let kind = MissionKind(rawValue: mission.kind),
              let template = templates.first(where: { $0.kind == kind }) else {
            return "questionmark"
        }
        return template.icon
    }
}
