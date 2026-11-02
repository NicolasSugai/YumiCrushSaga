import SpriteKit
import YumiEngine

@MainActor
final class MatchBoardScene: SKScene {
    var board = GameBoard()
    var selected: Position?
    var prefersReducedMotion = false
    var onSelect: ((Position) -> Void)?
    private var cellSize: CGFloat = 40
    private var boardOrigin = CGPoint.zero
    private var touchStart: CGPoint?
    private var tileNodes: [Position: SKShapeNode] = [:]

    override init(size: CGSize) {
        super.init(size: size)
        scaleMode = .resizeFill
        backgroundColor = .clear
    }
    required init?(coder: NSCoder) { fatalError("init(coder:) is unsupported") }
    func update(board: GameBoard, selected: Position?) {
        let animatePieces = self.board != board && !prefersReducedMotion
        self.board = board; self.selected = selected
        if animatePieces { drawBoard(animatePieces: true) }
        else { updateSelection() }
    }
    override func didChangeSize(_ oldSize: CGSize) { drawBoard(animatePieces: false) }
    private func drawBoard(animatePieces: Bool) {
        removeAllChildren()
        tileNodes.removeAll(keepingCapacity: true)
        guard board.rows > 0, board.columns > 0, size.width > 0 else { return }
        let gap: CGFloat = 4
        cellSize = min((size.width - 20 - CGFloat(board.columns - 1) * gap) / CGFloat(board.columns),
                       (size.height - 20 - CGFloat(board.rows - 1) * gap) / CGFloat(board.rows))
        let boardWidth = CGFloat(board.columns) * cellSize + CGFloat(board.columns - 1) * gap
        let boardHeight = CGFloat(board.rows) * cellSize + CGFloat(board.rows - 1) * gap
        boardOrigin = CGPoint(x: (size.width - boardWidth) / 2, y: (size.height - boardHeight) / 2)
        for row in 0..<board.rows { for column in 0..<board.columns {
            let position = Position(row: row, column: column)
            let x = boardOrigin.x + CGFloat(column) * (cellSize + gap) + cellSize / 2
            let y = size.height - boardOrigin.y - CGFloat(row) * (cellSize + gap) - cellSize / 2
            let tile = SKShapeNode(rectOf: CGSize(width: cellSize, height: cellSize), cornerRadius: cellSize * 0.27)
            tile.position = CGPoint(x: x, y: y)
            style(tile, at: position)
            tile.name = "cell-\(row)-\(column)"
            if animatePieces {
                tile.setScale(0.88)
                tile.run(SKAction.sequence([.scale(to: 1.04, duration: 0.07), .scale(to: 1, duration: 0.1)]))
            }
            addChild(tile)
            tileNodes[position] = tile
            if let piece = board[position] {
                let art = PieceArtNode(ingredient: piece.ingredient, size: cellSize * 0.68, special: piece.special)
                art.position = CGPoint(x: x, y: y + 1)
                art.name = tile.name
                if animatePieces {
                    art.setScale(0.72 * cellSize * 0.68 / 44)
                    art.run(SKAction.scale(to: cellSize * 0.68 / 44, duration: 0.16))
                }
                addChild(art)
            }
        } }
    }
    private func updateSelection() {
        for (position, tile) in tileNodes { style(tile, at: position) }
    }
    private func style(_ tile: SKShapeNode, at position: Position) {
        let isSelected = selected.map { $0 == position } == true
        tile.fillColor = isSelected ? SKColor(red: 0.96, green: 0.73, blue: 0.24, alpha: 1) : SKColor.white.withAlphaComponent(0.23)
        tile.strokeColor = SKColor.white.withAlphaComponent(isSelected ? 0.95 : 0.1)
        tile.lineWidth = isSelected ? 3 : 1
    }
    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let point = touches.first?.location(in: self) else { return }
        if let start = touchStart, hypot(point.x - start.x, point.y - start.y) > 18,
           let origin = cell(at: start) {
            let dx = point.x - start.x
            let dy = point.y - start.y
            let neighbor = abs(dx) > abs(dy)
                ? Position(row: origin.row, column: origin.column + (dx > 0 ? 1 : -1))
                : Position(row: origin.row + (dy > 0 ? -1 : 1), column: origin.column)
            if board.contains(neighbor) { onSelect?(origin); onSelect?(neighbor); touchStart = nil; return }
        }
        if let position = cell(at: point) { onSelect?(position) }
        touchStart = nil
    }
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        touchStart = touches.first?.location(in: self)
    }
    private func cell(at point: CGPoint) -> Position? {
        let x = point.x - boardOrigin.x
        let y = size.height - point.y - boardOrigin.y
        let column = Int(x / (cellSize + 4))
        let row = Int(y / (cellSize + 4))
        let withinX = x.truncatingRemainder(dividingBy: cellSize + 4) <= cellSize
        let withinY = y.truncatingRemainder(dividingBy: cellSize + 4) <= cellSize
        let position = Position(row: row, column: column)
        return x >= 0 && y >= 0 && withinX && withinY && board.contains(position) ? position : nil
    }
}
