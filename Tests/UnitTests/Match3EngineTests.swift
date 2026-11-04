import XCTest
@testable import YumiEngine

final class Match3EngineTests: XCTestCase {
    func testSeedProducesSameInitialIngredients() {
        var first = Match3Engine(seed: 42)
        var second = Match3Engine(seed: 42)
        let a = first.makeBoard()
        let b = second.makeBoard()
        XCTAssertEqual(a, b)
    }

    func testGeneratedBoardHasNoStartingMatchesAndHasLegalMove() {
        var engine = Match3Engine(seed: 93)
        let board = engine.makeBoard()
        XCTAssertTrue(engine.matches(in: board).isEmpty)
        XCTAssertTrue(engine.hasLegalMove(board))
    }

    func testManySeedsProducePlayableMatchFreeBoards() {
        for seed in 0..<100 {
            var engine = Match3Engine(seed: UInt64(seed))
            let board = engine.makeBoard()
            XCTAssertEqual(board.pieces.count, 8)
            XCTAssertTrue(board.pieces.allSatisfy { $0.count == 8 && $0.allSatisfy { $0 != nil } }, "Seed \(seed) left a hole")
            XCTAssertTrue(engine.matches(in: board).isEmpty, "Seed \(seed) generated an automatic match")
            XCTAssertTrue(engine.hasLegalMove(board), "Seed \(seed) generated a deadlock")
        }
    }

    func testFindsHorizontalAndVerticalGroups() {
        var board = emptyBoard()
        for column in 1...3 { board[Position(row: 2, column: column)] = piece(.acai) }
        for row in 4...6 { board[Position(row: row, column: 6)] = piece(.jambu) }
        let engine = Match3Engine(seed: 1)
        XCTAssertEqual(engine.matches(in: board).count, 6)
    }

    func testTAndLIntersectionIsIncludedOnce() {
        var board = emptyBoard()
        for column in 1...3 { board[Position(row: 3, column: column)] = piece(.cupuacu) }
        for row in 2...4 { board[Position(row: row, column: 2)] = piece(.cupuacu) }
        XCTAssertEqual(Match3Engine(seed: 1).matches(in: board).count, 5)
    }

    func testRejectsNonAdjacentOrNonMatchingMove() {
        var board = emptyBoard()
        let ingredients: [Ingredient] = [.acai, .jambu, .tucupi, .cupuacu, .brazilNut, .tapereba, .bacuri, .cassava]
        for row in 0..<8 { for column in 0..<8 { board[Position(row: row, column: column)] = piece(ingredients[(row * 3 + column * 5) % ingredients.count]) } }
        var engine = Match3Engine(seed: 1)
        let result = engine.resolveSwap(Position(row: 0, column: 0), Position(row: 0, column: 7), on: board)
        XCTAssertNil(result)
    }

    func testInvalidAdjacentSwapLeavesInputBoardUnchanged() {
        var board = emptyBoard()
        fillPattern(&board)
        let original = board
        var engine = Match3Engine(seed: 3)
        let result = engine.resolveSwap(Position(row: 0, column: 0), Position(row: 0, column: 1), on: board)
        XCTAssertNil(result)
        XCTAssertEqual(board, original)
    }

    func testSpecialPieceCanBeCreatedByFourMatch() {
        var board = emptyBoard()
        fillPattern(&board)
        board[Position(row: 1, column: 0)] = piece(.acai)
        board[Position(row: 1, column: 1)] = piece(.acai)
        board[Position(row: 1, column: 2)] = piece(.jambu)
        board[Position(row: 1, column: 3)] = piece(.acai)
        board[Position(row: 0, column: 2)] = piece(.acai)
        var engine = Match3Engine(seed: 28)
        let result = engine.resolveSwap(Position(row: 0, column: 2), Position(row: 1, column: 2), on: board)
        XCTAssertEqual(result?.specialsCreated.first, .riverCurrent)
    }

    func testFiveMatchCreatesIngredientClearer() {
        var board = emptyBoard()
        fillPattern(&board)
        for column in [0, 1, 3, 4] { board[Position(row: 1, column: column)] = piece(.acai) }
        board[Position(row: 1, column: 2)] = piece(.jambu)
        board[Position(row: 0, column: 2)] = piece(.acai)
        var engine = Match3Engine(seed: 31)
        let result = engine.resolveSwap(Position(row: 0, column: 2), Position(row: 1, column: 2), on: board)
        XCTAssertEqual(result?.specialsCreated.first, .uruUru)
    }

    func testTIntersectionCreatesAreaSpecial() {
        var board = emptyBoard()
        fillPattern(&board)
        board[Position(row: 2, column: 2)] = piece(.acai)
        board[Position(row: 2, column: 3)] = piece(.acai)
        board[Position(row: 2, column: 4)] = piece(.jambu)
        board[Position(row: 1, column: 4)] = piece(.acai)
        board[Position(row: 3, column: 4)] = piece(.acai)
        board[Position(row: 2, column: 5)] = piece(.acai)
        var engine = Match3Engine(seed: 10)
        let result = engine.resolveSwap(Position(row: 2, column: 4), Position(row: 2, column: 5), on: board)
        XCTAssertEqual(result?.specialsCreated.first, .forestBurst)
    }

    func testDetectsDeadlockAndAutomaticallyReshuffles() {
        var board = emptyBoard()
        fillPattern(&board)
        var engine = Match3Engine(seed: 112)
        XCTAssertTrue(engine.matches(in: board).isEmpty)
        XCTAssertFalse(engine.hasLegalMove(board))
        let originalIngredients = ingredientCounts(in: board)
        XCTAssertTrue(engine.reshuffleIfNeeded(&board))
        XCTAssertTrue(engine.matches(in: board).isEmpty)
        XCTAssertTrue(engine.hasLegalMove(board))
        XCTAssertEqual(ingredientCounts(in: board), originalIngredients)
    }

    func testSpecialPieceInteractionTriggersBothPieces() {
        var board = emptyBoard()
        fillPattern(&board)
        board[Position(row: 0, column: 0)]?.special = .riverCurrent
        board[Position(row: 0, column: 1)]?.special = .forestBurst
        var engine = Match3Engine(seed: 25)
        let result = engine.resolveSwap(Position(row: 0, column: 0), Position(row: 0, column: 1), on: board)
        XCTAssertTrue(result?.specialsTriggered == true)
        XCTAssertGreaterThanOrEqual(result?.collected.values.reduce(0, +) ?? 0, 8)
    }

    func testRiverCurrentClearsItsEntireRowWhenSwapped() {
        var board = emptyBoard()
        fillPattern(&board)
        board[Position(row: 3, column: 2)]?.special = .riverCurrent
        var engine = Match3Engine(seed: 250)

        let result = engine.resolveSwap(Position(row: 3, column: 2), Position(row: 3, column: 3), on: board)

        XCTAssertTrue(result?.specialsTriggered == true)
        XCTAssertGreaterThanOrEqual(result?.collected.values.reduce(0, +) ?? 0, 8)
    }

    func testForestBurstClearsItsThreeByThreeAreaWhenSwapped() {
        var board = emptyBoard()
        fillPattern(&board)
        board[Position(row: 3, column: 3)]?.special = .forestBurst
        var engine = Match3Engine(seed: 251)

        let result = engine.resolveSwap(Position(row: 3, column: 3), Position(row: 3, column: 4), on: board)

        XCTAssertTrue(result?.specialsTriggered == true)
        XCTAssertGreaterThanOrEqual(result?.collected.values.reduce(0, +) ?? 0, 9)
    }

    func testUruUruClearsEveryPieceOfItsIngredientWhenSwapped() {
        var board = emptyBoard()
        fillPattern(&board)
        board[Position(row: 0, column: 0)]?.special = .uruUru
        let acaiCount = board.pieces.flatMap { $0.compactMap { $0 } }.filter { $0.ingredient == .acai }.count
        var engine = Match3Engine(seed: 252)

        let result = engine.resolveSwap(Position(row: 0, column: 0), Position(row: 0, column: 1), on: board)

        XCTAssertTrue(result?.specialsTriggered == true)
        XCTAssertGreaterThanOrEqual(result?.collected[.acai, default: 0] ?? 0, acaiCount)
    }

    func testLevelDifficultyAndGoalAreGenerated() {
        let early = LevelConfiguration.generated(number: 1)
        let later = LevelConfiguration.generated(number: 30)
        XCTAssertEqual(early.moves, 25)
        XCTAssertLessThan(later.moves, early.moves)
        XCTAssertGreaterThan(later.ingredientCount, early.ingredientCount)
        guard case .specials(let target) = LevelConfiguration.generated(number: 5).goal else {
            return XCTFail("Every fifth level should teach special pieces")
        }
        XCTAssertEqual(target, 1)
    }

    func testEveryGeneratedCollectionGoalIncludesItsIngredient() {
        for number in stride(from: 2, through: 40, by: 2) where !number.isMultiple(of: 5) {
            let level = LevelConfiguration.generated(number: number)
            guard case .collect(let ingredient, _) = level.goal else { continue }
            let ingredientIndex = Ingredient.allCases.firstIndex(of: ingredient)!
            XCTAssertGreaterThanOrEqual(level.ingredientCount, ingredientIndex + 1, "Level \(number) must contain its collection ingredient")
        }
    }

    func testGeneratedGoalsStayWithinPlayableBounds() {
        for number in 1...200 {
            let level = LevelConfiguration.generated(number: number)
            XCTAssertTrue((12...25).contains(level.moves), "Level \(number) has an invalid move count")
            XCTAssertTrue((3...8).contains(level.ingredientCount), "Level \(number) has an invalid palette size")
            switch level.goal {
            case .score(let target):
                XCTAssertTrue((900...1_800).contains(target), "Level \(number) has an unbounded score goal")
            case .collect(_, let target):
                XCTAssertTrue((8...15).contains(target), "Level \(number) has an invalid collection goal")
            case .specials(let target):
                XCTAssertTrue((1...2).contains(target), "Level \(number) has an excessive special-piece goal")
            }
        }
    }

    func testCollectionGoalsRespectMoveAndIngredientAvailability() {
        for number in stride(from: 2, through: 200, by: 2) where !number.isMultiple(of: 5) {
            let level = LevelConfiguration.generated(number: number)
            guard case .collect(_, let target) = level.goal else { continue }
            let capacityTarget = max(8, level.moves * 4 / level.ingredientCount)
            XCTAssertLessThanOrEqual(target, capacityTarget, "Level \(number) has a collection goal too high for its move and palette budget")
        }
    }

    func testResolvedBoardsAreFullMatchFreeAndPlayableAcrossManySeeds() {
        for seed in 0..<100 {
            var engine = Match3Engine(seed: UInt64(seed))
            var board = engine.makeBoard()
            guard let move = firstLegalMove(in: board, engine: engine) else {
                return XCTFail("Seed \(seed) should have a legal move")
            }
            guard let result = engine.resolveSwap(move.0, move.1, on: board) else {
                return XCTFail("Seed \(seed) should resolve its legal move")
            }
            board = result.board

            XCTAssertLessThanOrEqual(result.cascades, Match3Engine.maximumCascades)
            XCTAssertTrue(board.pieces.allSatisfy { $0.count == board.columns && $0.allSatisfy { $0 != nil } }, "Seed \(seed) left a hole")
            XCTAssertTrue(engine.matches(in: board).isEmpty, "Seed \(seed) left a match")
            XCTAssertTrue(engine.hasLegalMove(board), "Seed \(seed) ended in a deadlock")
        }
    }

    private func emptyBoard() -> GameBoard { GameBoard(rows: 8, columns: 8) }
    private func piece(_ ingredient: Ingredient) -> GamePiece { GamePiece(ingredient: ingredient) }
    private func fillPattern(_ board: inout GameBoard) {
        for row in 0..<8 { for column in 0..<8 {
            board[Position(row: row, column: column)] = piece(Ingredient.allCases[(row + column) % Ingredient.allCases.count])
        } }
    }
    private func ingredientCounts(in board: GameBoard) -> [Ingredient: Int] {
        board.pieces.flatMap { $0.compactMap { $0?.ingredient } }.reduce(into: [:]) { $0[$1, default: 0] += 1 }
    }
    private func firstLegalMove(in board: GameBoard, engine: Match3Engine) -> (Position, Position)? {
        for row in 0..<board.rows {
            for column in 0..<board.columns {
                let first = Position(row: row, column: column)
                for second in [Position(row: row, column: column + 1), Position(row: row + 1, column: column)] where board.contains(second) {
                    var candidateEngine = engine
                    if candidateEngine.resolveSwap(first, second, on: board) != nil { return (first, second) }
                }
            }
        }
        return nil
    }
}
