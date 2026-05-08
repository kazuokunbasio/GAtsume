import SpriteKit

final class RoomScene: SKScene {
    var onCatch: ((String) -> Void)?
    var kinds: [GokiKind] = []
    var furniture: [FurnitureKind] = []
    var placedFurnitureIds: [String] = []
    var activeBait: BaitKind?

    private var spawnTimer: Timer?
    private let spawnInterval: TimeInterval = 4.0
    private let floorHeight: CGFloat = 140

    override func didMove(to view: SKView) {
        applyTimeBasedBackground()
        scaleMode = .resizeFill
        addFloor()
        refreshFurniture()
        startSpawning()
    }

    override func willMove(from view: SKView) {
        spawnTimer?.invalidate()
        spawnTimer = nil
    }

    private func applyTimeBasedBackground() {
        let hour = Calendar.current.component(.hour, from: .now)
        let isNight = hour >= 18 || hour < 6
        backgroundColor = isNight
            ? SKColor(red: 0.10, green: 0.10, blue: 0.16, alpha: 1.0)
            : SKColor(red: 0.20, green: 0.18, blue: 0.20, alpha: 1.0)
    }

    private func addFloor() {
        let floor = SKShapeNode(rectOf: CGSize(width: size.width * 1.4, height: floorHeight))
        floor.fillColor = SKColor(red: 0.30, green: 0.23, blue: 0.18, alpha: 1.0)
        floor.strokeColor = .clear
        floor.position = CGPoint(x: size.width / 2, y: floorHeight / 2)
        floor.zPosition = -1
        floor.name = "_floor"
        addChild(floor)

        let line = SKShapeNode(rectOf: CGSize(width: size.width * 1.4, height: 2))
        line.fillColor = SKColor.white.withAlphaComponent(0.18)
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
            let container = SKNode()
            container.name = "_fur_\(item.id)"
            container.position = CGPoint(x: spacing * CGFloat(idx + 1), y: floorHeight * 0.62)
            container.zPosition = -0.5

            let emoji = SKLabelNode(text: item.emoji)
            emoji.fontSize = 60
            emoji.verticalAlignmentMode = .center
            emoji.horizontalAlignmentMode = .center
            container.addChild(emoji)

            let name = SKLabelNode(text: item.name)
            name.fontSize = 12
            name.fontColor = SKColor.white.withAlphaComponent(0.6)
            name.verticalAlignmentMode = .top
            name.horizontalAlignmentMode = .center
            name.position = CGPoint(x: 0, y: -38)
            container.addChild(name)

            addChild(container)
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
        guard let kind = Spawner.pick(
            from: kinds,
            furniture: furniture,
            activeFurnitureIds: placedFurnitureIds,
            activeBait: activeBait
        ) else { return }

        let node = makeGokiNode(for: kind)

        let fromLeft = Bool.random()
        let y = CGFloat.random(in: (floorHeight + 40) ... (size.height * 0.85))
        let startX: CGFloat = fromLeft ? -60 : size.width + 60
        let endX: CGFloat = fromLeft ? size.width + 60 : -60

        node.position = CGPoint(x: startX, y: y)
        addChild(node)

        let walkDuration = Double.random(in: 7.0 ... 11.0)
        let walk = SKAction.moveTo(x: endX, duration: walkDuration)
        let wiggle = SKAction.repeatForever(
            SKAction.sequence([
                SKAction.rotate(byAngle: 0.08, duration: 0.18),
                SKAction.rotate(byAngle: -0.16, duration: 0.36),
                SKAction.rotate(byAngle: 0.08, duration: 0.18)
            ])
        )
        node.run(wiggle, withKey: "wiggle")
        node.run(SKAction.sequence([walk, .removeFromParent()]))
    }

    private func makeGokiNode(for kind: GokiKind) -> SKNode {
        if let name = kind.imageName, UIImage(named: name) != nil {
            let sprite = SKSpriteNode(imageNamed: name)
            let targetWidth: CGFloat = 80
            let aspect = sprite.size.width > 0 ? sprite.size.height / sprite.size.width : 1
            sprite.size = CGSize(width: targetWidth, height: targetWidth * aspect)
            sprite.name = kind.id
            return sprite
        } else {
            let label = SKLabelNode(text: kind.emoji)
            label.fontSize = 64
            label.name = kind.id
            label.verticalAlignmentMode = .center
            label.horizontalAlignmentMode = .center
            return label
        }
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
