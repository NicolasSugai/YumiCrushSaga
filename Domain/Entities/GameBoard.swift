import Foundation

public struct GameBoard: Codable, Equatable, Sendable {
    public let rows: Int
    public let columns: Int
    public var pieces: [[GamePiece?]]

    public init(rows: Int = 8, columns: Int = 8, pieces: [[GamePiece?]]? = nil) {
        self.rows = rows
        self.columns = columns
        self.pieces = pieces ?? Array(repeating: Array(repeating: nil, count: columns), count: rows)
    }
    public func contains(_ position: Position) -> Bool {
        (0..<rows).contains(position.row) && (0..<columns).contains(position.column)
    }
    public subscript(_ position: Position) -> GamePiece? {
        get { contains(position) ? pieces[position.row][position.column] : nil }
        set { if contains(position) { pieces[position.row][position.column] = newValue } }
    }
}
