import Foundation

public struct MoveResolution: Sendable {
    public let board: GameBoard
    public let scoreEarned: Int
    public let collected: [Ingredient: Int]
    public let cascades: Int
    public let reshuffled: Bool
    public let specialsTriggered: Bool
    public let specialsCreated: [SpecialKind]
}

public struct Match3Engine {
    public static let maximumCascades = 32
    public private(set) var random: SeededRandom
    private var ingredientCount = 5
    public init(seed: UInt64) { random = SeededRandom(seed: seed) }

    public mutating func makeBoard(size: Int = 8, ingredientCount: Int = 5) -> GameBoard {
        let count = min(Ingredient.allCases.count, max(3, ingredientCount))
        self.ingredientCount = count
        var board = GameBoard(rows: size, columns: size)
        for row in 0..<size {
            for column in 0..<size {
                var options = Array(Ingredient.allCases.prefix(count))
                if column >= 2,
                   let left = board[Position(row: row, column: column - 1)]?.ingredient,
                   let left2 = board[Position(row: row, column: column - 2)]?.ingredient {
                    options.removeAll { $0 == left && $0 == left2 }
                }
                if row >= 2,
                   let above = board[Position(row: row - 1, column: column)]?.ingredient,
                   let above2 = board[Position(row: row - 2, column: column)]?.ingredient {
                    options.removeAll { $0 == above && $0 == above2 }
                }
                board[Position(row: row, column: column)] = GamePiece(ingredient: options[nextInt(options.count)])
            }
        }
        _ = reshuffleIfNeeded(&board, ingredientCount: count)
        return board
    }

    public mutating func resolveSwap(_ first: Position, _ second: Position, on source: GameBoard) -> MoveResolution? {
        guard source.contains(first), source.contains(second), first.isAdjacent(to: second),
              source[first] != nil, source[second] != nil, matches(in: source).isEmpty else { return nil }
        var board = source
        let firstPiece = board[first]
        board[first] = board[second]
        board[second] = firstPiece
        var matched = matches(in: board)
        let specialSwap = source[first]?.special != nil || source[second]?.special != nil
        guard !matched.isEmpty || specialSwap else { return nil }

        var collected: [Ingredient: Int] = [:]
        var score = 0
        var cascades = 0
        var specialsTriggered = false
        var createdSpecials: [SpecialKind] = []
        while (!matched.isEmpty || (specialSwap && cascades == 0)) && cascades < Self.maximumCascades {
            cascades += 1
            var removal = matched
            if specialSwap && cascades == 1 {
                removal = expandSpecials(at: removal.union([first, second]), board: board)
            } else {
                removal = expandSpecials(at: removal, board: board)
            }
            let preferredPositions = cascades == 1 ? [second, first] : []
            if let (position, kind) = specialCreation(in: board, matches: matched, preferred: preferredPositions) {
                removal.remove(position)
                board[position]?.special = kind
                createdSpecials.append(kind)
            }

            var waveScore = 0
            for position in removal {
                guard let piece = board[position] else { continue }
                if piece.special != nil { specialsTriggered = true }
                collected[piece.ingredient, default: 0] += 1
                waveScore += 60 + (piece.special == nil ? 0 : 120)
                board[position] = nil
            }
            score += waveScore * cascades
            applyGravity(to: &board)
            refill(&board, ingredientCount: ingredientCount)
            matched = matches(in: board)
        }
        let didReshuffle = reshuffleIfNeeded(&board, ingredientCount: ingredientCount)
        return MoveResolution(board: board, scoreEarned: score, collected: collected, cascades: cascades, reshuffled: didReshuffle, specialsTriggered: specialsTriggered, specialsCreated: createdSpecials)
    }

    @discardableResult
    public mutating func reshuffleIfNeeded(_ board: inout GameBoard, ingredientCount: Int? = nil) -> Bool {
        guard !hasLegalMove(board) || !matches(in: board).isEmpty else { return false }
        reshuffle(&board, ingredientCount: ingredientCount ?? self.ingredientCount)
        return true
    }

    public func matches(in board: GameBoard) -> Set<Position> {
        var result = Set<Position>()
        for row in 0..<board.rows {
            var start = 0
            while start < board.columns {
                guard let ingredient = board[Position(row: row, column: start)]?.ingredient else { start += 1; continue }
                var end = start + 1
                while end < board.columns && board[Position(row: row, column: end)]?.ingredient == ingredient { end += 1 }
                if end - start >= 3 { for column in start..<end { result.insert(Position(row: row, column: column)) } }
                start = end
            }
        }
        for column in 0..<board.columns {
            var start = 0
            while start < board.rows {
                guard let ingredient = board[Position(row: start, column: column)]?.ingredient else { start += 1; continue }
                var end = start + 1
                while end < board.rows && board[Position(row: end, column: column)]?.ingredient == ingredient { end += 1 }
                if end - start >= 3 { for row in start..<end { result.insert(Position(row: row, column: column)) } }
                start = end
            }
        }
        return result
    }

    public func hasLegalMove(_ board: GameBoard) -> Bool {
        guard matches(in: board).isEmpty else { return false }
        for row in 0..<board.rows { for column in 0..<board.columns {
            let p = Position(row: row, column: column)
            for q in [Position(row: row, column: column + 1), Position(row: row + 1, column: column)] where board.contains(q) {
                guard board[p] != nil, board[q] != nil else { continue }
                if board[p]?.special != nil || board[q]?.special != nil { return true }
                var copy = board
                let firstPiece = copy[p]
                copy[p] = copy[q]
                copy[q] = firstPiece
                if !matches(in: copy).isEmpty { return true }
            }
        } }
        return false
    }

    private func matchGroups(in board: GameBoard) -> [[Position]] {
        var groups: [[Position]] = []
        for row in 0..<board.rows {
            var start = 0
            while start < board.columns {
                guard let ingredient = board[Position(row: row, column: start)]?.ingredient else { start += 1; continue }
                var end = start + 1
                while end < board.columns && board[Position(row: row, column: end)]?.ingredient == ingredient { end += 1 }
                if end - start >= 3 { groups.append((start..<end).map { Position(row: row, column: $0) }) }
                start = end
            }
        }
        for column in 0..<board.columns {
            var start = 0
            while start < board.rows {
                guard let ingredient = board[Position(row: start, column: column)]?.ingredient else { start += 1; continue }
                var end = start + 1
                while end < board.rows && board[Position(row: end, column: column)]?.ingredient == ingredient { end += 1 }
                if end - start >= 3 { groups.append((start..<end).map { Position(row: $0, column: column) }) }
                start = end
            }
        }
        return groups
    }

    private func specialCreation(in board: GameBoard, matches: Set<Position>, preferred: [Position]) -> (Position, SpecialKind)? {
        guard !matches.isEmpty,
              let group = matchGroups(in: board).max(by: { $0.count < $1.count }),
              group.count >= 4 else { return nil }
        let junction = junctionPosition(in: board)
        let kind: SpecialKind = junction == nil ? (group.count >= 5 ? .uruUru : .riverCurrent) : .forestBurst
        let available = matches.filter { board[$0]?.special == nil }
        guard !available.isEmpty else { return nil }
        if let junction, available.contains(junction) { return (junction, kind) }
        for position in preferred where available.contains(position) { return (position, kind) }
        let eligibleGroup = group.filter { available.contains($0) }
        let ordered = (eligibleGroup.isEmpty ? Array(available) : eligibleGroup).sorted {
            $0.row == $1.row ? $0.column < $1.column : $0.row < $1.row
        }
        return (ordered[ordered.count / 2], kind)
    }

    private func junctionPosition(in board: GameBoard) -> Position? {
        for position in matches(in: board).sorted(by: {
            $0.row == $1.row ? $0.column < $1.column : $0.row < $1.row
        }) {
            guard let ingredient = board[position]?.ingredient else { continue }
            var left = position.column
            while left > 0 && board[Position(row: position.row, column: left - 1)]?.ingredient == ingredient { left -= 1 }
            var right = position.column
            while right + 1 < board.columns && board[Position(row: position.row, column: right + 1)]?.ingredient == ingredient { right += 1 }
            var top = position.row
            while top > 0 && board[Position(row: top - 1, column: position.column)]?.ingredient == ingredient { top -= 1 }
            var bottom = position.row
            while bottom + 1 < board.rows && board[Position(row: bottom + 1, column: position.column)]?.ingredient == ingredient { bottom += 1 }
            if right - left + 1 >= 3 && bottom - top + 1 >= 3 { return position }
        }
        return nil
    }

    private func expandSpecials(at initial: Set<Position>, board: GameBoard) -> Set<Position> {
        var result = initial
        var queue = Array(initial)
        while let position = queue.popLast() {
            guard let kind = board[position]?.special else { continue }
            var affected = Set<Position>()
            switch kind {
            case .riverCurrent: affected = Set((0..<board.columns).map { Position(row: position.row, column: $0) })
            case .forestBurst:
                for row in max(0, position.row - 1)...min(board.rows - 1, position.row + 1) {
                    for column in max(0, position.column - 1)...min(board.columns - 1, position.column + 1) { affected.insert(Position(row: row, column: column)) }
                }
            case .uruUru:
                if let ingredient = board[position]?.ingredient {
                    for row in 0..<board.rows { for column in 0..<board.columns where board[Position(row: row, column: column)]?.ingredient == ingredient { affected.insert(Position(row: row, column: column)) } }
                }
            }
            for item in affected where result.insert(item).inserted { if board[item]?.special != nil { queue.append(item) } }
        }
        return result
    }

    private mutating func applyGravity(to board: inout GameBoard) {
        for column in 0..<board.columns {
            let survivors = (0..<board.rows).reversed().compactMap { board[Position(row: $0, column: column)] }
            for row in 0..<board.rows { board[Position(row: row, column: column)] = nil }
            for (offset, piece) in survivors.enumerated() { board[Position(row: board.rows - 1 - offset, column: column)] = piece }
        }
    }
    private mutating func refill(_ board: inout GameBoard, ingredientCount: Int) {
        for row in 0..<board.rows { for column in 0..<board.columns where board[Position(row: row, column: column)] == nil {
            board[Position(row: row, column: column)] = GamePiece(ingredient: Ingredient.allCases[nextInt(ingredientCount)])
        } }
    }
    private mutating func reshuffle(_ board: inout GameBoard, ingredientCount: Int) {
        let pieces = board.pieces.flatMap { $0.compactMap { $0 } }
        if pieces.count == board.rows * board.columns && !pieces.isEmpty {
            for _ in 0..<100 {
                var shuffled = pieces
                for index in stride(from: shuffled.count - 1, through: 1, by: -1) {
                    shuffled.swapAt(index, nextInt(index + 1))
                }
                var candidate = GameBoard(rows: board.rows, columns: board.columns)
                for (index, piece) in shuffled.enumerated() {
                    candidate[Position(row: index / board.columns, column: index % board.columns)] = piece
                }
                if matches(in: candidate).isEmpty && hasLegalMove(candidate) {
                    board = candidate
                    return
                }
            }
        }
        for _ in 0..<100 {
            let candidate = makeBoardWithoutReshuffle(rows: board.rows, columns: board.columns, ingredientCount: ingredientCount)
            if hasLegalMove(candidate) && matches(in: candidate).isEmpty { board = candidate; return }
        }
        board = guaranteedPlayableBoard(rows: board.rows, columns: board.columns, ingredientCount: max(3, ingredientCount))
    }
    private func guaranteedPlayableBoard(rows: Int, columns: Int, ingredientCount: Int) -> GameBoard {
        let choices = Array(Ingredient.allCases.prefix(max(3, min(Ingredient.allCases.count, ingredientCount))))
        var result = GameBoard(rows: rows, columns: columns)
        for row in 0..<rows { for column in 0..<columns {
            result[Position(row: row, column: column)] = GamePiece(ingredient: choices[(row + column) % choices.count])
        } }
        guard rows > 1, columns > 2 else { return result }
        result[Position(row: 0, column: 0)] = GamePiece(ingredient: choices[0])
        result[Position(row: 0, column: 1)] = GamePiece(ingredient: choices[0])
        result[Position(row: 0, column: 2)] = GamePiece(ingredient: choices[1])
        result[Position(row: 1, column: 2)] = GamePiece(ingredient: choices[0])
        return result
    }
    private mutating func makeBoardWithoutReshuffle(rows: Int, columns: Int, ingredientCount: Int) -> GameBoard {
        var result = GameBoard(rows: rows, columns: columns)
        let choices = Array(Ingredient.allCases.prefix(max(3, min(Ingredient.allCases.count, ingredientCount))))
        for row in 0..<rows { for column in 0..<columns {
            var allowed = choices
            if column >= 2, result[Position(row: row, column: column - 1)]?.ingredient == result[Position(row: row, column: column - 2)]?.ingredient {
                allowed.removeAll { $0 == result[Position(row: row, column: column - 1)]?.ingredient }
            }
            if row >= 2, result[Position(row: row - 1, column: column)]?.ingredient == result[Position(row: row - 2, column: column)]?.ingredient {
                allowed.removeAll { $0 == result[Position(row: row - 1, column: column)]?.ingredient }
            }
            result[Position(row: row, column: column)] = GamePiece(ingredient: allowed[nextInt(allowed.count)])
        } }
        return result
    }
    private mutating func nextInt(_ upperBound: Int) -> Int { random.nextInt(upperBound: upperBound) }
}
