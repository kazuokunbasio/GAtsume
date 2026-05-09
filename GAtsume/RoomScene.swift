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
    var paintingEmoji: String = "🫘" {
        didSet { updatePainting() }
    }

    private var spawnTimer: Timer?
    private let spawnInterval: TimeInterval = 4.0
    private let floorHeight: CGFloat = 140
    private weak var floorNode: SKShapeNode?
    private weak var draggingNode: SKNode?
    private weak var bgImageNode: SKSpriteNode?
    private weak var windowNode: SKShapeNode?

    override func didMove(to view: SKView) {
        scaleMode = .resizeFill
        addFloor()
        addRoomDetails()
        addWindow()
        applyWallpaper()
        addAmbientParticles()
        refreshFurniture()
        startSpawning()
    }

    private func addRoomDetails() {
        let ceiling = SKShapeNode(rectOf: CGSize(width: size.width * 1.4, height: 2))
        ceiling.fillColor = SKColor.white.withAlphaComponent(0.1)
        ceiling.strokeColor = .clear
        ceiling.position = CGPoint(x: size.width / 2, y: size.height - 6)
        ceiling.zPosition = -1.4
        ceiling.name = "_ceiling"
        addChild(ceiling)

        let baseboard = SKShapeNode(rectOf: CGSize(width: size.width * 1.4, height: 10))
        baseboard.fillColor = SKColor.black.withAlphaComponent(0.32)
        baseboard.strokeColor = .clear
        baseboard.position = CGPoint(x: size.width / 2, y: floorHeight + 6)
        baseboard.zPosition = -0.95
        baseboard.name = "_baseboard"
        addChild(baseboard)

        let painting = SKShapeNode(
            rectOf: CGSize(width: 76, height: 56),
            cornerRadius: 4
        )
        painting.fillColor = SKColor(red: 0.32, green: 0.22, blue: 0.42, alpha: 0.85)
        painting.strokeColor = SKColor.white.withAlphaComponent(0.45)
        painting.lineWidth = 2
        painting.position = CGPoint(x: size.width * 0.22, y: size.height * 0.62)
        painting.zPosition = -1.55
        painting.name = "_painting_frame"
        addChild(painting)

        let paintingIcon = SKLabelNode(text: paintingEmoji)
        paintingIcon.fontSize = 30
        paintingIcon.position = painting.position
        paintingIcon.zPosition = -1.5
        paintingIcon.verticalAlignmentMode = .center
        paintingIcon.horizontalAlignmentMode = .center
        paintingIcon.name = "_painting_art"
        addChild(paintingIcon)
    }

    private func updatePainting() {
        if let label = childNode(withName: "_painting_art") as? SKLabelNode {
            label.text = paintingEmoji
        }
    }

    private func addWindow() {
        let windowWidth = size.width * 0.45
        let windowHeight: CGFloat = 110

        let frame = SKShapeNode(
            rectOf: CGSize(width: windowWidth, height: windowHeight),
            cornerRadius: 6
        )
        frame.position = CGPoint(x: size.width * 0.7, y: size.height * 0.66)
        frame.zPosition = -1.6
        frame.strokeColor = SKColor.white.withAlphaComponent(0.35)
        frame.lineWidth = 2.5
        frame.fillColor = .clear
        frame.name = "_window_frame"
        addChild(frame)

        let inner = SKShapeNode(
            rectOf: CGSize(width: windowWidth - 6, height: windowHeight - 6),
            cornerRadius: 4
        )
        inner.position = frame.position
        inner.zPosition = -1.7
        inner.strokeColor = .clear
        inner.fillColor = SKColor(red: 0.55, green: 0.78, blue: 0.95, alpha: 1.0)
        inner.name = "_window_sky"
        addChild(inner)
        self.windowNode = inner

        let crossPath = CGMutablePath()
        crossPath.move(to: CGPoint(x: -windowWidth / 2 + 6, y: 0))
        crossPath.addLine(to: CGPoint(x: windowWidth / 2 - 6, y: 0))
        crossPath.move(to: CGPoint(x: 0, y: -windowHeight / 2 + 6))
        crossPath.addLine(to: CGPoint(x: 0, y: windowHeight / 2 - 6))
        let cross = SKShapeNode(path: crossPath)
        cross.position = frame.position
        cross.zPosition = -1.55
        cross.strokeColor = SKColor.white.withAlphaComponent(0.35)
        cross.lineWidth = 1.5
        cross.name = "_window_cross"
        addChild(cross)
    }

    private func updateWindowSky() {
        let hour = Calendar.current.component(.hour, from: .now)
        let color: SKColor
        switch hour {
        case 0..<5, 21...:
            color = SKColor(red: 0.05, green: 0.06, blue: 0.20, alpha: 1.0)
        case 5..<7:
            color = SKColor(red: 0.65, green: 0.45, blue: 0.55, alpha: 1.0)
        case 7..<16:
            color = SKColor(red: 0.55, green: 0.78, blue: 0.95, alpha: 1.0)
        case 16..<18:
            color = SKColor(red: 0.95, green: 0.55, blue: 0.35, alpha: 1.0)
        case 18..<21:
            color = SKColor(red: 0.30, green: 0.20, blue: 0.45, alpha: 1.0)
        default:
            color = SKColor(red: 0.55, green: 0.78, blue: 0.95, alpha: 1.0)
        }
        windowNode?.fillColor = color
    }

    private func addAmbientParticles() {
        for _ in 0..<10 {
            let particle = SKShapeNode(circleOfRadius: CGFloat.random(in: 1.0...2.5))
            particle.fillColor = SKColor.white.withAlphaComponent(0.15)
            particle.strokeColor = .clear
            particle.position = CGPoint(
                x: CGFloat.random(in: 0...size.width),
                y: CGFloat.random(in: floorHeight + 30 ... size.height - 30)
            )
            particle.zPosition = -1.5
            particle.alpha = 0
            particle.name = "_ambient"
            addChild(particle)
            animateParticle(particle)
        }
    }

    private func animateParticle(_ particle: SKNode) {
        let fadeIn = SKAction.fadeAlpha(to: CGFloat.random(in: 0.1 ... 0.3), duration: 2.0)
        let drift = SKAction.moveBy(
            x: CGFloat.random(in: -40...40),
            y: CGFloat.random(in: -20...40),
            duration: TimeInterval.random(in: 7...11)
        )
        let fadeOut = SKAction.fadeOut(withDuration: 2.0)
        let reset = SKAction.run { [weak self, weak particle] in
            guard let self, let particle else { return }
            particle.position = CGPoint(
                x: CGFloat.random(in: 0...self.size.width),
                y: CGFloat.random(in: self.floorHeight + 30 ... self.size.height - 30)
            )
            self.animateParticle(particle)
        }
        particle.run(SKAction.sequence([fadeIn, drift, fadeOut, reset]))
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

        updateWindowSky()
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
            applyFurnitureBehavior(container: container, emoji: emoji, item: item)
        }
    }

    private func applyFurnitureBehavior(container: SKNode, emoji: SKLabelNode, item: FurnitureKind) {
        switch item.id {
        case "neon_light":
            let flicker = SKAction.repeatForever(SKAction.sequence([
                SKAction.wait(forDuration: TimeInterval.random(in: 1.5...4.0)),
                SKAction.fadeAlpha(to: 0.4, duration: 0.05),
                SKAction.fadeAlpha(to: 1.0, duration: 0.05),
                SKAction.fadeAlpha(to: 0.55, duration: 0.04),
                SKAction.fadeAlpha(to: 1.0, duration: 0.06)
            ]))
            emoji.run(flicker)

        case "humidifier":
            let spawnPuff = SKAction.run { [weak self, weak container] in
                guard let self, let container else { return }
                let puff = SKShapeNode(circleOfRadius: 5)
                puff.fillColor = SKColor.white.withAlphaComponent(0.3)
                puff.strokeColor = .clear
                puff.position = CGPoint(
                    x: container.position.x + CGFloat.random(in: -8...8),
                    y: container.position.y + 22
                )
                puff.zPosition = -0.4
                self.addChild(puff)
                let rise = SKAction.moveBy(
                    x: CGFloat.random(in: -15...15),
                    y: CGFloat.random(in: 50...80),
                    duration: 1.6
                )
                let fade = SKAction.fadeOut(withDuration: 1.6)
                let scale = SKAction.scale(to: 2.4, duration: 1.6)
                puff.run(SKAction.sequence([
                    SKAction.group([rise, fade, scale]),
                    .removeFromParent()
                ]))
            }
            let cycle = SKAction.repeatForever(SKAction.sequence([
                spawnPuff,
                SKAction.wait(forDuration: TimeInterval.random(in: 2.5...4.0))
            ]))
            container.run(cycle)

        case "fermented":
            let aura = SKAction.repeatForever(SKAction.sequence([
                SKAction.scale(to: 1.05, duration: 1.6),
                SKAction.scale(to: 1.0, duration: 1.6)
            ]))
            emoji.run(aura)

        case "old_fridge", "wood_box", "trash_bag":
            let wobble = SKAction.repeatForever(SKAction.sequence([
                SKAction.rotate(byAngle: 0.025, duration: 1.6),
                SKAction.rotate(byAngle: -0.05, duration: 3.2),
                SKAction.rotate(byAngle: 0.025, duration: 1.6),
                SKAction.wait(forDuration: TimeInterval.random(in: 3.5...6.5))
            ]))
            emoji.run(wobble)

        default:
            break
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

    private var activeGokiCount: Int {
        children.reduce(0) { count, node in
            guard let name = node.name, !name.hasPrefix("_") else { return count }
            return count + 1
        }
    }

    private func spawnRandomGoki() {
        guard activeGokiCount < 8 else { return }
        guard let kind = Spawner.pick(
            from: kinds,
            furniture: furniture,
            activeFurnitureIds: placedFurniture.map(\.furnitureId),
            activeBait: activeBait
        ) else { return }

        let node = makeGokiNode(for: kind)

        let fromLeft = Bool.random()
        let startY = CGFloat.random(in: (floorHeight + 40) ... (size.height * 0.85))
        let startX: CGFloat = fromLeft ? -50 : size.width + 50

        node.position = CGPoint(x: startX, y: startY)
        addChild(node)

        let wigglePeriod = TimeInterval.random(in: 0.16...0.26)
        let wiggleAmt: CGFloat = CGFloat.random(in: 0.08...0.13)
        let wiggle = SKAction.repeatForever(
            SKAction.sequence([
                SKAction.rotate(byAngle: wiggleAmt, duration: wigglePeriod),
                SKAction.rotate(byAngle: -wiggleAmt * 2, duration: wigglePeriod * 2),
                SKAction.rotate(byAngle: wiggleAmt, duration: wigglePeriod)
            ])
        )
        node.run(wiggle, withKey: "wiggle")

        let path = makeMovementPath(for: kind, startPoint: node.position, fromLeft: fromLeft)
        node.run(SKAction.sequence(path + [.removeFromParent()]))
    }

    private func makeMovementPath(for kind: GokiKind, startPoint: CGPoint, fromLeft: Bool) -> [SKAction] {
        var actions: [SKAction] = []
        let direction: CGFloat = fromLeft ? 1 : -1
        let exitX: CGFloat = fromLeft ? size.width + 60 : -60
        var currentPoint = startPoint

        let attractive = furniture.filter { item in
            placedFurniture.contains(where: { $0.furnitureId == item.id })
                && (item.boosts[kind.id] ?? 0) > 0
        }

        if let furn = attractive.randomElement(),
           Double.random(in: 0..<1) < 0.55,
           let furnNode = childNode(withName: "_fur_\(furn.id)") {
            let stopPoint = CGPoint(
                x: furnNode.position.x + CGFloat.random(in: -25...25),
                y: max(floorHeight + 35, furnNode.position.y + CGFloat.random(in: 28...58))
            )
            actions.append(contentsOf: walkSegment(from: currentPoint, to: stopPoint))
            actions.append(SKAction.wait(forDuration: TimeInterval.random(in: 0.9...1.8)))
            actions.append(SKAction.rotate(byAngle: 0.35, duration: 0.18))
            actions.append(SKAction.rotate(byAngle: -0.7, duration: 0.32))
            actions.append(SKAction.rotate(byAngle: 0.35, duration: 0.18))
            currentPoint = stopPoint
        }

        let segmentCount = Int.random(in: 3...6)
        for i in 0..<segmentCount {
            let isLast = i == segmentCount - 1
            let progress = CGFloat(i + 1) / CGFloat(segmentCount)
            let stepX = isLast
                ? exitX
                : currentPoint.x + (exitX - currentPoint.x) * progress * CGFloat.random(in: 0.45...0.85)
            let clampedX = direction > 0
                ? min(stepX, exitX)
                : max(stepX, exitX)
            let stepY = max(
                floorHeight + 30,
                min(size.height - 30, currentPoint.y + CGFloat.random(in: -55...55))
            )
            let target = CGPoint(x: clampedX, y: stepY)

            actions.append(contentsOf: walkSegment(from: currentPoint, to: target))

            if !isLast {
                if Double.random(in: 0..<1) < 0.35 {
                    actions.append(SKAction.wait(forDuration: TimeInterval.random(in: 0.3...0.9)))
                    if Double.random(in: 0..<1) < 0.4 {
                        let look = CGFloat.random(in: -0.5...0.5)
                        actions.append(SKAction.rotate(byAngle: look, duration: 0.15))
                        actions.append(SKAction.rotate(byAngle: -look, duration: 0.15))
                    }
                }
            }
            currentPoint = target
        }

        return actions
    }

    private func walkSegment(from: CGPoint, to: CGPoint) -> [SKAction] {
        let distance = hypot(to.x - from.x, to.y - from.y)
        let dart = Double.random(in: 0..<1) < 0.18
        let speed: CGFloat = dart
            ? CGFloat.random(in: 220...300)
            : CGFloat.random(in: 70...140)
        let duration = TimeInterval(distance / max(speed, 1))
        let move = SKAction.move(to: to, duration: duration)
        move.timingMode = dart ? .easeOut : .easeInEaseOut
        return [move]
    }

    private func makeGokiNode(for kind: GokiKind) -> SKNode {
        let body: SKNode

        if let name = kind.imageName, UIImage(named: name) != nil {
            let sprite = SKSpriteNode(imageNamed: name)
            let targetWidth: CGFloat = 80
            let aspect = sprite.size.width > 0 ? sprite.size.height / sprite.size.width : 1
            sprite.size = CGSize(width: targetWidth, height: targetWidth * aspect)
            sprite.name = kind.id
            body = sprite
        } else {
            let label = SKLabelNode(text: kind.emoji)
            label.fontSize = 64
            label.name = kind.id
            label.verticalAlignmentMode = .center
            label.horizontalAlignmentMode = .center
            body = label
        }

        let shadow = SKShapeNode(ellipseOf: CGSize(width: 50, height: 14))
        shadow.fillColor = SKColor.black.withAlphaComponent(0.22)
        shadow.strokeColor = .clear
        shadow.position = CGPoint(x: 0, y: -34)
        shadow.zPosition = -0.1
        body.addChild(shadow)

        let scale = CGFloat.random(in: 0.85...1.2)
        body.setScale(scale)

        return body
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

        if let nearest = findNearestGoki(to: location, maxDistance: 55),
           let id = nearest.name {
            onCatch?(id)
            catchAnimation(node: nearest, kindId: id)
        }
    }

    private func findNearestGoki(to location: CGPoint, maxDistance: CGFloat) -> SKNode? {
        var nearest: SKNode?
        var minDistSq = maxDistance * maxDistance
        for child in children {
            guard let name = child.name, !name.hasPrefix("_") else { continue }
            let dx = child.position.x - location.x
            let dy = child.position.y - location.y
            let distSq = dx * dx + dy * dy
            if distSq < minDistSq {
                minDistSq = distSq
                nearest = child
            }
        }
        return nearest
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
        let currentScale = node.xScale
        let pop = SKAction.scale(to: currentScale * 1.6, duration: 0.12)
        let fade = SKAction.fadeOut(withDuration: 0.25)
        node.run(SKAction.sequence([SKAction.group([pop, fade]), .removeFromParent()]))

        spawnBurst(at: position, rarity: rarity)
        spawnCoinPopup(at: position, amount: Spawner.coinReward(for: rarity), rarity: rarity)
    }

    private func spawnCoinPopup(at position: CGPoint, amount: Int, rarity: Rarity) {
        let label = SKLabelNode(text: "+\(amount)")
        label.fontName = "AvenirNext-Bold"
        label.fontSize = rarity == .superRare ? 32 : (rarity == .rare ? 26 : 22)
        label.fontColor = {
            switch rarity {
            case .normal: return SKColor.systemYellow
            case .rare: return SKColor.systemOrange
            case .superRare: return SKColor.systemPink
            }
        }()
        label.position = CGPoint(x: position.x, y: position.y + 20)
        label.zPosition = 11
        label.verticalAlignmentMode = .center
        label.horizontalAlignmentMode = .center
        addChild(label)

        let rise = SKAction.moveBy(x: CGFloat.random(in: -10...10), y: 70, duration: 0.85)
        rise.timingMode = .easeOut
        let fade = SKAction.fadeOut(withDuration: 0.85)
        let scale = SKAction.scale(to: 1.2, duration: 0.2)
        let scaleBack = SKAction.scale(to: 1.0, duration: 0.6)
        label.run(SKAction.sequence([
            SKAction.group([rise, fade, SKAction.sequence([scale, scaleBack])]),
            .removeFromParent()
        ]))
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
