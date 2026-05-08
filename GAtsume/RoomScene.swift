import SpriteKit

struct PlacedFurnitureInfo: Equatable {
    let furnitureId: String
    let positionFraction: CGPoint?
}

final class RoomScene: SKScene {
    var onCatch: ((String) -> Void)?
    var onFurnitureMoved: ((String, CGPoint) -> Void)?
    var kinds: [GokiKind] = []
    var furniture: [FurnitureKind] = []
    var placedFurniture: [PlacedFurnitureInfo] = []
    var activeBait: BaitKind?
    var wallpaper: WallpaperKind?

    private var spawnTimer: Timer?
    private let spawnInterval: TimeInterval = 4.0
    private let floorHeight: CGFloat = 140
    private weak var floorNode: SKShapeNode?
    private weak var draggingNode: SKNode?
    private weak var bgImageNode: SKSpriteNode?

    override func didMove(to view: SKView) {
        scaleMode = .resizeFill
        addFloor()
        applyWallpaper()
        refreshFurniture()
        startSpawning()
    }

    override func willMove(from view: SKView) {
        spawnTimer?.invalidate()
        spawnTimer = nil
    }

    func applyWallpaper() {
        let hour = Calendar.current.component(.hour, from: .now)
        let isNight = hour >= 18 || hour < 6
        let darken: Double = isNight ? 0.65 : 1.0

        let bg = wallpaper?.bgColor ?? [0.20, 0.18, 0.20]
        let fl = wallpaper?.floorColor ?? [0.30, 0.23, 0.18]

        bgImageNode?.removeFromParent()
        bgImageNode = nil

        backgroundColor = SKColor(
            red: CGFloat(bg[0] * darken),
            green: CGFloat(bg[1] * darken),
            blue: CGFloat(bg[2] * darken),
            alpha: 1.0
        )

        if let imgName = wallpaper?.bgImage, UIImage(named: imgName) != nil {
            let texture = SKTexture(imageNamed: imgName)
            let sprite = SKSpriteNode(texture: texture, size: CGSize(width: size.width, height: size.height))
            sprite.position = CGPoint(x: size.width / 2, y: size.height / 2)
            sprite.zPosition = -2
            sprite.colorBlendFactor = isNight ? 0.4 : 0
            sprite.color = .black
            addChild(sprite)
            bgImageNode = sprite
        }

        floorNode?.fillColor = SKColor(
            red: CGFloat(fl[0] * darken),
            green: CGFloat(fl[1] * darken),
            blue: CGFloat(fl[2] * darken),
            alpha: 1.0
        )
    }

    private func addFloor() {
        let floor = SKShapeNode(rectOf: CGSize(width: size.width * 1.4, height: floorHeight))
        floor.fillColor = SKColor(red: 0.30, green: 0.23, blue: 0.18, alpha: 1.0)
        floor.strokeColor = .clear
        floor.position = CGPoint(x: size.width / 2, y: floorHeight / 2)
        floor.zPosition = -1
        floor.name = "_floor"
        addChild(floor)
        self.floorNode = floor

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

        guard !placedFurniture.isEmpty else { return }

        let autoSpacing = size.width / CGFloat(placedFurniture.count + 1)

        for (idx, info) in placedFurniture.enumerated() {
            guard let item = furniture.first(where: { $0.id == info.furnitureId }) else { continue }

            let position: CGPoint
            if let frac = info.positionFraction {
                position = CGPoint(
                    x: size.width * CGFloat(frac.x),
                    y: size.height * CGFloat(frac.y)
                )
            } else {
                position = CGPoint(
                    x: autoSpacing * CGFloat(idx + 1),
                    y: floorHeight * 0.62
                )
            }

            let container = SKNode()
            container.name = "_fur_\(item.id)"
            container.position = position
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
            self?.spawnPulse()
        }
        spawnPulse()
    }

    private func spawnPulse() {
        let r = Double.random(in: 0..<1)
        let count: Int = r < 0.7 ? 1 : (r < 0.95 ? 2 : 3)
        for i in 0..<count {
            let delay = TimeInterval(i) * 0.4
            run(SKAction.sequence([
                SKAction.wait(forDuration: delay),
                SKAction.run { [weak self] in
                    self?.spawnRandomGoki()
                }
            ]))
        }
    }

    private func spawnRandomGoki() {
        guard let kind = Spawner.pick(
            from: kinds,
            furniture: furniture,
            activeFurnitureIds: placedFurniture.map(\.furnitureId),
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

    private func furnitureContainer(at location: CGPoint) -> SKNode? {
        for node in nodes(at: location) {
            var current: SKNode? = node
            while let n = current {
                if let name = n.name, name.hasPrefix("_fur_") {
                    return n
                }
                current = n.parent
            }
        }
        return nil
    }

    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let touch = touches.first else { return }
        let location = touch.location(in: self)

        if let furnitureNode = furnitureContainer(at: location) {
            draggingNode = furnitureNode
            furnitureNode.run(SKAction.scale(to: 1.1, duration: 0.1))
            return
        }

        for node in nodes(at: location) {
            guard let id = node.name, !id.hasPrefix("_") else { continue }
            onCatch?(id)
            catchAnimation(node: node, kindId: id)
            return
        }
    }

    override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let touch = touches.first, let node = draggingNode else { return }
        let location = touch.location(in: self)
        let clampedX = max(40, min(size.width - 40, location.x))
        let clampedY = max(20, min(size.height - 100, location.y))
        node.position = CGPoint(x: clampedX, y: clampedY)
    }

    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        finishDragging()
    }

    override func touchesCancelled(_ touches: Set<UITouch>, with event: UIEvent?) {
        finishDragging()
    }

    private func finishDragging() {
        guard let node = draggingNode, let name = node.name, name.hasPrefix("_fur_") else {
            draggingNode = nil
            return
        }
        node.run(SKAction.scale(to: 1.0, duration: 0.1))
        let id = String(name.dropFirst("_fur_".count))
        let frac = CGPoint(
            x: node.position.x / size.width,
            y: node.position.y / size.height
        )
        onFurnitureMoved?(id, frac)
        draggingNode = nil
    }

    private func catchAnimation(node: SKNode, kindId: String) {
        let position = node.position
        let rarity = kinds.first(where: { $0.id == kindId })?.rarity ?? .normal

        node.removeAllActions()
        let pop = SKAction.scale(to: 1.6, duration: 0.12)
        let fade = SKAction.fadeOut(withDuration: 0.25)
        node.run(SKAction.sequence([SKAction.group([pop, fade]), .removeFromParent()]))

        spawnBurst(at: position, rarity: rarity)
    }

    private func spawnBurst(at position: CGPoint, rarity: Rarity) {
        let count: Int
        let radius: CGFloat
        let distance: CGFloat
        let colors: [SKColor]

        switch rarity {
        case .normal:
            count = 6
            radius = 4
            distance = 60
            colors = [.white]
        case .rare:
            count = 14
            radius = 5
            distance = 90
            colors = [.yellow, .white, .orange]
        case .superRare:
            count = 28
            radius = 6
            distance = 130
            colors = [
                SKColor.systemRed, SKColor.systemOrange, SKColor.systemYellow,
                SKColor.systemGreen, SKColor.systemTeal, SKColor.systemBlue,
                SKColor.systemPurple, SKColor.systemPink
            ]
        }

        for i in 0..<count {
            let dot = SKShapeNode(circleOfRadius: radius)
            dot.fillColor = colors.randomElement() ?? .white
            dot.strokeColor = .clear
            dot.position = position
            dot.zPosition = 10
            addChild(dot)

            let baseAngle = CGFloat(i) / CGFloat(count) * .pi * 2
            let jitter = CGFloat.random(in: -0.3...0.3)
            let angle = baseAngle + jitter
            let dist = distance * CGFloat.random(in: 0.7...1.2)
            let dx = cos(angle) * dist
            let dy = sin(angle) * dist

            let move = SKAction.moveBy(x: dx, y: dy, duration: 0.7)
            move.timingMode = .easeOut
            let fade = SKAction.fadeOut(withDuration: 0.7)
            let scale = SKAction.scale(to: 0.2, duration: 0.7)

            dot.run(SKAction.sequence([
                SKAction.group([move, fade, scale]),
                .removeFromParent()
            ]))
        }
    }
}
