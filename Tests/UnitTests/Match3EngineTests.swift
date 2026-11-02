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
        let result = Match3Engine(seed: 1).resolveSwap(Position(row: 0, column: 0), Position(row: 0, column: 7), on: board)
        XCTAssertNil(result)
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
        XCTAssertEqual(result?.specialCreated, .riverCurrent)
    }

    func testFiveMatchCreatesIngredientClearer() {
        var board = emptyBoard()
        fillPattern(&board)
        for column in [0, 1, 3, 4] { board[Position(row: 1, column: column)] = piece(.acai) }
        board[Position(row: 1, column: 2)] = piece(.jambu)
        board[Position(row: 0, column: 2)] = piece(.acai)
        var engine = Match3Engine(seed: 31)
        let result = engine.resolveSwap(Position(row: 0, column: 2), Position(row: 1, column: 2), on: board)
        XCTAssertEqual(result?.specialCreated, .uruUru)
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
        XCTAssertEqual(result?.specialCreated, .forestBurst)
    }

    func testDetectsDeadlockAndAutomaticallyReshuffles() {
        var board = emptyBoard()
        fillPattern(&board)
        var engine = Match3Engine(seed: 112)
        XCTAssertTrue(engine.matches(in: board).isEmpty)
        XCTAssertFalse(engine.hasLegalMove(board))
        XCTAssertTrue(engine.reshuffleIfNeeded(&board))
        XCTAssertTrue(engine.matches(in: board).isEmpty)
        XCTAssertTrue(engine.hasLegalMove(board))
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

    func testLevelDifficultyAndGoalAreGenerated() {
        let early = LevelConfiguration.generated(number: 1)
        let later = LevelConfiguration.generated(number: 30)
        XCTAssertEqual(early.moves, 25)
        XCTAssertLessThan(later.moves, early.moves)
        XCTAssertGreaterThan(later.ingredientCount, early.ingredientCount)
        guard case .specials(let target) = LevelConfiguration.generated(number: 5).goal else {
            return XCTFail("Every fifth level should teach special pieces")
        }
        XCTAssertEqual(target, 2)
    }

    func testEveryGeneratedCollectionGoalIncludesItsIngredient() {
        for number in stride(from: 2, through: 40, by: 2) where !number.isMultiple(of: 5) {
            let level = LevelConfiguration.generated(number: number)
            guard case .collect(let ingredient, _) = level.goal else { continue }
            let ingredientIndex = Ingredient.allCases.firstIndex(of: ingredient)!
            XCTAssertGreaterThanOrEqual(level.ingredientCount, ingredientIndex + 1, "Level \(number) must contain its collection ingredient")
        }
    }

    private func emptyBoard() -> GameBoard { GameBoard(rows: 8, columns: 8) }
    private func piece(_ ingredient: Ingredient) -> GamePiece { GamePiece(ingredient: ingredient) }
    private func fillPattern(_ board: inout GameBoard) {
        for row in 0..<8 { for column in 0..<8 {
            board[Position(row: row, column: column)] = piece(Ingredient.allCases[(row + column) % Ingredient.allCases.count])
        } }
    }
}
