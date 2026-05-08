import SpriteKit

final class RoomScene: SKScene {
    var onCatch: ((String) -> Void)?
    var kinds: [GokiKind] = []
    var furniture: [FurnitureKind] = []
    var placedFurnitureIds: [String] = []

    private var spawnTimer: Timer?
    private let spawnInterval: TimeInterval = 4.0
    private let floorHeight: CGFloat = 90

    override func didMove(to view: SKView) {
        backgroundColor = SKColor(red: 0.16, green: 0.13, blue: 0.14, alpha: 1.0)
        scaleMode = .resizeFill
        addFloor()
        refreshFurniture()
        startSpawning()
    }

    override func willMove(from view: SKView) {
        spawnTimer?.invalidate()
        spawnTimer = nil
    }

    private func addFloor() {
        let floor = SKShapeNode(rectOf: CGSize(width: size.width * 1.4, height: floorHeight))
        floor.fillColor = SKColor(red: 0.10, green: 0.08, blue: 0.07, alpha: 1.0)
        floor.strokeColor = .clear
        floor.position = CGPoint(x: size.width / 2, y: floorHeight / 2)
        floor.zPosition = -1
        floor.name = "_floor"
        addChild(floor)

        let line = SKShapeNode(rectOf: CGSize(width: size.width * 1.4, height: 1))
        line.fillColor = SKColor.white.withAlphaComponent(0.07)
        line.strokeColor = .clear
        line.position = CGPoint(x: size.width / 2, y: floorHeight)
        line.zPosition = 0
        line.name = "_floor_line"
        addChild(line)
    }

    func refreshFurniture() {
        for child in children where child.name?.hasPrefix("_fur_") == true {
            child.removeFromParent()
        }

        let placed = furniture.filter { placedFurnitureIds.contains($0.id) }
        guard !placed.isEmpty else { return }

        let spacing = size.width / CGFloat(placed.count + 1)
        for (idx, item) in placed.enumerated() {
            let label = SKLabelNode(text: item.emoji)
            label.fontSize = 56
            label.verticalAlignmentMode = .center
            label.horizontalAlignmentMode = .center
            label.name = "_fur_\(item.id)"
            label.position = CGPoint(x: spacing * CGFloat(idx + 1), y: floorHeight * 0.65)
            label.zPosition = -0.5
            addChild(label)
        }
    }

    private func startSpawning() {
        spawnTimer?.invalidate()
        spawnTimer = Timer.scheduledTimer(withTimeInterval: spawnInterval, repeats: true) { [weak self] _ in
            self?.spawnRandomGoki()
        }
        spawnRandomGoki()
    }

    private func spawnRandomGoki() {
        guard !kinds.isEmpty, let kind = pickWeighted() else { return }

        let label = SKLabelNode(text: kind.emoji)
        label.fontSize = 64
        label.name = kind.id
        label.verticalAlignmentMode = .center
        label.horizontalAlignmentMode = .center

        let fromLeft = Bool.random()
        let y = CGFloat.random(in: (floorHeight + 40) ... (size.height * 0.85))
        let startX: CGFloat = fromLeft ? -60 : size.width + 60
        let endX: CGFloat = fromLeft ? size.width + 60 : -60

        label.position = CGPoint(x: startX, y: y)
        addChild(label)

        let walkDuration = Double.random(in: 7.0 ... 11.0)
        let walk = SKAction.moveTo(x: endX, duration: walkDuration)
        let wiggle = SKAction.repeatForever(
            SKAction.sequence([
                SKAction.rotate(byAngle: 0.08, duration: 0.18),
                SKAction.rotate(byAngle: -0.16, duration: 0.36),
                SKAction.rotate(byAngle: 0.08, duration: 0.18)
            ])
        )
        label.run(wiggle, withKey: "wiggle")
        label.run(SKAction.sequence([walk, .removeFromParent()]))
    }

    private func pickWeighted() -> GokiKind? {
        let weighted = kinds.map { (kind: $0, weight: effectiveWeight(for: $0)) }
        let total = weighted.reduce(0.0) { $0 + $1.weight }
        guard total > 0 else { return nil }
        var r = Double.random(in: 0..<total)
        for entry in weighted {
            if r < entry.weight { return entry.kind }
            r -= entry.weight
        }
        return weighted.last?.kind
    }

    private func effectiveWeight(for goki: GokiKind) -> Double {
        let bonus = furniture
            .filter { placedFurnitureIds.contains($0.id) }
            .reduce(0.0) { $0 + ($1.boosts[goki.id] ?? 0) }
        return goki.spawnWeight + bonus
    }

    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let touch = touches.first else { return }
        let location = touch.location(in: self)
        for node in nodes(at: location) {
            guard let id = node.name, !id.hasPrefix("_") else { continue }
            onCatch?(id)
            catchAnimation(node: node)
            return
        }
    }

    private func catchAnimation(node: SKNode) {
        node.removeAllActions()
        let pop = SKAction.scale(to: 1.6, duration: 0.12)
        let fade = SKAction.fadeOut(withDuration: 0.25)
        node.run(SKAction.sequence([SKAction.group([pop, fade]), .removeFromParent()]))
    }
}
