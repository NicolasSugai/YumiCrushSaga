import Foundation

public struct Position: Hashable, Codable, Sendable {
    public let row: Int
    public let column: Int
    public init(row: Int, column: Int) { self.row = row; self.column = column }
    public func isAdjacent(to other: Position) -> Bool {
        abs(row - other.row) + abs(column - other.column) == 1
    }
}
