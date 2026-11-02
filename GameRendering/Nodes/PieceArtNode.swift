import SpriteKit
import YumiEngine

/// Small, original SpriteKit vector drawings for the eight Paraense ingredients.
final class PieceArtNode: SKNode {
    init(ingredient: Ingredient, size: CGFloat, special: SpecialKind?) {
        super.init()
        let scale = size / 44
        setScale(scale)
        switch ingredient {
        case .acai: drawAcai()
        case .cupuacu: drawCupuacu()
        case .brazilNut: drawBrazilNut()
        case .jambu: drawJambu()
        case .tucupi: drawTucupi()
        case .tapereba: drawTapereba()
        case .bacuri: drawBacuri()
        case .cassava: drawCassava()
        }
        if special != nil {
            let halo = SKShapeNode(circleOfRadius: 20)
            halo.strokeColor = SKColor(red: 1, green: 0.86, blue: 0.36, alpha: 1)
            halo.lineWidth = 2.5
            halo.fillColor = .clear
            halo.glowWidth = 1.5
            halo.zPosition = 3
            addChild(halo)
            let mark: String
            switch special {
            case .some(.riverCurrent): mark = "↔"
            case .some(.forestBurst): mark = "✹"
            case .some(.uruUru): mark = "◉"
            case .none: mark = ""
            }
            let star = SKLabelNode(text: mark)
            star.fontName = "AvenirNext-Heavy"
            star.fontSize = 12
            star.fontColor = .white
            star.position = CGPoint(x: 13, y: 13)
            star.zPosition = 4
            addChild(star)
            star.run(.repeatForever(.sequence([.fadeAlpha(to: 0.45, duration: 0.4), .fadeAlpha(to: 1, duration: 0.4)])))
        }
        name = "piece-\(ingredient.rawValue)"
    }
    required init?(coder: NSCoder) { fatalError("init(coder:) is unsupported") }

    private func oval(_ width: CGFloat, _ height: CGFloat, _ color: SKColor, stroke: SKColor = .clear, line: CGFloat = 0) -> SKShapeNode {
        let node = SKShapeNode(ellipseOf: CGSize(width: width, height: height))
        node.fillColor = color; node.strokeColor = stroke; node.lineWidth = line
        return node
    }
    private func rounded(_ width: CGFloat, _ height: CGFloat, _ radius: CGFloat, _ color: SKColor) -> SKShapeNode {
        let node = SKShapeNode(rectOf: CGSize(width: width, height: height), cornerRadius: radius)
        node.fillColor = color; node.strokeColor = color
        return node
    }
    private func dot(_ x: CGFloat, _ y: CGFloat, _ radius: CGFloat, _ color: SKColor) {
        let node = SKShapeNode(circleOfRadius: radius)
        node.fillColor = color; node.strokeColor = .clear; node.position = CGPoint(x: x, y: y)
        addChild(node)
    }
    private func drawAcai() {
        let purple = SKColor(red: 0.34, green: 0.16, blue: 0.48, alpha: 1)
        for (x, y) in [(-7, 2), (0, 8), (7, 2), (-3, -6), (5, -7)] {
            let berry = oval(17, 17, purple, stroke: SKColor(red: 0.22, green: 0.10, blue: 0.35, alpha: 1), line: 1)
            berry.position = CGPoint(x: CGFloat(x), y: CGFloat(y)); addChild(berry)
            dot(CGFloat(x) - 2, CGFloat(y) + 3, 1.7, SKColor(red: 0.75, green: 0.57, blue: 0.85, alpha: 1))
        }
        let leaf = leafPath(size: CGSize(width: 12, height: 7), color: SKColor(red: 0.27, green: 0.54, blue: 0.31, alpha: 1))
        leaf.position = CGPoint(x: 7, y: 13); leaf.zRotation = 0.45; addChild(leaf)
    }
    private func drawCupuacu() {
        let fruit = oval(25, 31, SKColor(red: 0.83, green: 0.68, blue: 0.42, alpha: 1), stroke: SKColor(red: 0.48, green: 0.34, blue: 0.19, alpha: 1), line: 1)
        fruit.zRotation = -0.22; addChild(fruit)
        let highlight = oval(5, 17, SKColor(red: 0.97, green: 0.84, blue: 0.58, alpha: 1))
        highlight.position = CGPoint(x: -5, y: 1); highlight.zRotation = -0.22; addChild(highlight)
        let stem = rounded(3, 8, 1, SKColor(red: 0.30, green: 0.30, blue: 0.17, alpha: 1))
        stem.position = CGPoint(x: 2, y: 17); addChild(stem)
        let leaf = leafPath(size: CGSize(width: 12, height: 7), color: SKColor(red: 0.20, green: 0.48, blue: 0.27, alpha: 1))
        leaf.position = CGPoint(x: 8, y: 19); leaf.zRotation = 0.4; addChild(leaf)
    }
    private func drawBrazilNut() {
        let shell = oval(25, 30, SKColor(red: 0.57, green: 0.34, blue: 0.19, alpha: 1), stroke: SKColor(red: 0.34, green: 0.20, blue: 0.12, alpha: 1), line: 1.2)
        shell.zRotation = 0.18; addChild(shell)
        let kernel = oval(16, 21, SKColor(red: 0.82, green: 0.65, blue: 0.42, alpha: 1))
        kernel.zRotation = 0.18; addChild(kernel)
        let crack = SKShapeNode()
        let path = CGMutablePath()
        path.move(to: CGPoint(x: -4, y: 8)); path.addLine(to: CGPoint(x: 2, y: 3)); path.addLine(to: CGPoint(x: -2, y: -1)); path.addLine(to: CGPoint(x: 4, y: -7))
        crack.path = path; crack.strokeColor = SKColor(red: 0.52, green: 0.35, blue: 0.22, alpha: 1); crack.lineWidth = 1.3; addChild(crack)
    }
    private func drawJambu() {
        for index in 0..<3 {
            let leaf = leafPath(size: CGSize(width: 25, height: 17), color: SKColor(red: 0.18, green: 0.48 + CGFloat(index) * 0.04, blue: 0.28, alpha: 1))
            leaf.position = CGPoint(x: CGFloat(index - 1) * 2, y: CGFloat(index - 1) * 3)
            leaf.zRotation = CGFloat(index - 1) * 0.75; addChild(leaf)
        }
        let flower = oval(8, 8, SKColor(red: 0.91, green: 0.73, blue: 0.31, alpha: 1))
        flower.position = CGPoint(x: 4, y: 4); flower.zPosition = 1; addChild(flower)
        dot(4, 4, 2, SKColor(red: 0.75, green: 0.35, blue: 0.20, alpha: 1))
    }
    private func drawTucupi() {
        let jar = rounded(25, 25, 5, SKColor(red: 0.88, green: 0.58, blue: 0.12, alpha: 1))
        jar.position = CGPoint(x: 0, y: -2); addChild(jar)
        let neck = rounded(12, 7, 2, SKColor(red: 0.93, green: 0.68, blue: 0.20, alpha: 1))
        neck.position = CGPoint(x: 0, y: 13); addChild(neck)
        let lid = rounded(16, 4, 1.5, SKColor(red: 0.42, green: 0.27, blue: 0.15, alpha: 1))
        lid.position = CGPoint(x: 0, y: 19); addChild(lid)
        let label = rounded(16, 7, 2, SKColor(red: 0.98, green: 0.86, blue: 0.56, alpha: 1))
        label.position = CGPoint(x: 0, y: -3); addChild(label)
    }
    private func drawTapereba() {
        let fruits: [(CGFloat, CGFloat, CGFloat)] = [(-7, -1, 9), (4, -3, 10), (0, 7, 8)]
        for (x, y, radius) in fruits {
            let fruit = SKShapeNode(circleOfRadius: radius)
            fruit.fillColor = SKColor(red: 0.95, green: 0.65, blue: 0.12, alpha: 1)
            fruit.strokeColor = SKColor(red: 0.78, green: 0.43, blue: 0.10, alpha: 1)
            fruit.lineWidth = 1; fruit.position = CGPoint(x: x, y: y); addChild(fruit)
            dot(x - 2, y + 2, 1.4, SKColor(red: 1, green: 0.84, blue: 0.36, alpha: 1))
        }
        let leaf = leafPath(size: CGSize(width: 13, height: 8), color: SKColor(red: 0.25, green: 0.53, blue: 0.29, alpha: 1))
        leaf.position = CGPoint(x: 8, y: 14); leaf.zRotation = 0.3; addChild(leaf)
    }
    private func drawBacuri() {
        let rind = oval(30, 29, SKColor(red: 0.46, green: 0.58, blue: 0.31, alpha: 1), stroke: SKColor(red: 0.26, green: 0.39, blue: 0.22, alpha: 1), line: 1)
        addChild(rind)
        let flesh = oval(19, 20, SKColor(red: 0.96, green: 0.83, blue: 0.59, alpha: 1))
        flesh.position = CGPoint(x: 1, y: -1); addChild(flesh)
        let seed = oval(6, 9, SKColor(red: 0.57, green: 0.34, blue: 0.18, alpha: 1))
        seed.position = CGPoint(x: 2, y: -1); addChild(seed)
        let leaf = leafPath(size: CGSize(width: 12, height: 7), color: SKColor(red: 0.18, green: 0.45, blue: 0.26, alpha: 1))
        leaf.position = CGPoint(x: 9, y: 15); leaf.zRotation = 0.25; addChild(leaf)
    }
    private func drawCassava() {
        let root = oval(34, 17, SKColor(red: 0.91, green: 0.81, blue: 0.62, alpha: 1), stroke: SKColor(red: 0.62, green: 0.46, blue: 0.29, alpha: 1), line: 1)
        root.zRotation = -0.48; addChild(root)
        for x in [-9, -2, 6, 12] {
            let mark = SKShapeNode()
            let path = CGMutablePath()
            path.move(to: CGPoint(x: CGFloat(x), y: -5)); path.addLine(to: CGPoint(x: CGFloat(x + 2), y: 5))
            mark.path = path; mark.strokeColor = SKColor(red: 0.62, green: 0.46, blue: 0.29, alpha: 0.7); mark.lineWidth = 1
            mark.zRotation = -0.48; addChild(mark)
        }
        let tip = leafPath(size: CGSize(width: 10, height: 6), color: SKColor(red: 0.29, green: 0.48, blue: 0.27, alpha: 1))
        tip.position = CGPoint(x: 17, y: 8); tip.zRotation = 0.5; addChild(tip)
    }
    private func leafPath(size: CGSize, color: SKColor) -> SKShapeNode {
        let path = CGMutablePath()
        path.move(to: CGPoint(x: -size.width / 2, y: 0))
        path.addQuadCurve(to: CGPoint(x: size.width / 2, y: 0), control: CGPoint(x: 0, y: size.height / 2))
        path.addQuadCurve(to: CGPoint(x: -size.width / 2, y: 0), control: CGPoint(x: 0, y: -size.height / 2))
        let node = SKShapeNode(path: path)
        node.fillColor = color; node.strokeColor = color; node.lineWidth = 0.5
        return node
    }
}
