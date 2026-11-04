#if canImport(Combine)
import Foundation
import XCTest
import YumiEngine
import YumiApplication

final class ApplicationFlowTests: XCTestCase {
    func testPlayVictoryPersistsAndRestoresProgress() async {
        await MainActor.run {
            let store = MemoryProgressStore()
            let session = GameSession(store: store)
            let level = LevelConfiguration(number: 1, moves: 25, goal: .score(1), ingredientCount: 5, region: "Ver-o-Peso")
            session.start(configuration: level, seed: 42)

            XCTAssertEqual(session.moves, 25)
            XCTAssertTrue(Match3Engine(seed: 1).matches(in: session.board).isEmpty)
            guard let move = Self.firstLegalMove(in: session.board) else {
                XCTFail("Generated board should allow a move")
                return
            }
            session.play(move.0, move.1)

            XCTAssertEqual(session.result, .victory)
            XCTAssertEqual(session.progress.unlockedLevel, 2)
            XCTAssertTrue(store.saved?.completedLevels.contains(1) == true)
            let finishedBoard = session.board
            let finishedScore = session.score
            let finishedMoves = session.moves
            session.play(move.0, move.1)
            XCTAssertEqual(session.board, finishedBoard)
            XCTAssertEqual(session.score, finishedScore)
            XCTAssertEqual(session.moves, finishedMoves)

            let restored = GameSession(store: store)
            XCTAssertEqual(restored.progress.unlockedLevel, 2)
            XCTAssertEqual(restored.level.number, 2)
        }
    }

    func testExhaustedLevelCanBeRetried() async {
        await MainActor.run {
            let store = MemoryProgressStore()
            let session = GameSession(store: store)
            let level = LevelConfiguration(number: 1, moves: 1, goal: .score(999_999), ingredientCount: 5, region: "Rio Guamá")
            session.start(configuration: level, seed: 77)
            guard let move = Self.firstLegalMove(in: session.board) else {
                XCTFail("Generated board should allow a move")
                return
            }
            session.play(move.0, move.1)

            XCTAssertEqual(session.moves, 0)
            XCTAssertEqual(session.result, .defeat)
            XCTAssertNotNil(store.saved?.bestScores[1])
            let finishedBoard = session.board
            let finishedScore = session.score
            session.play(move.0, move.1)
            XCTAssertEqual(session.board, finishedBoard)
            XCTAssertEqual(session.score, finishedScore)
            XCTAssertEqual(session.moves, 0)

            session.start(configuration: level, seed: 77)
            XCTAssertNil(session.result)
            XCTAssertEqual(session.score, 0)
            XCTAssertEqual(session.moves, 1)
        }
    }

    func testInvalidMoveDoesNotConsumeMoveOrChangeGameState() async {
        await MainActor.run {
            let session = GameSession(store: MemoryProgressStore())
            let level = LevelConfiguration(number: 1, moves: 4, goal: .score(999_999), ingredientCount: 5, region: "Ver-o-Peso")
            session.start(configuration: level, seed: 108)
            guard let move = Self.firstInvalidMove(in: session.board) else {
                XCTFail("The generated board should have at least one non-matching adjacent swap")
                return
            }
            let originalBoard = session.board
            let originalScore = session.score

            session.play(move.0, move.1)

            XCTAssertEqual(session.board, originalBoard)
            XCTAssertEqual(session.score, originalScore)
            XCTAssertEqual(session.moves, level.moves)
            XCTAssertNil(session.result)
        }
    }

    func testProgressSaveFailureIsExposedToTheUser() async {
        await MainActor.run {
            let session = GameSession(store: FailingProgressStore())

            session.toggleSound()

            XCTAssertNotNil(session.persistenceError)
            session.dismissPersistenceError()
            XCTAssertNil(session.persistenceError)
        }
    }

    private static func firstLegalMove(in board: GameBoard) -> (Position, Position)? {
        for row in 0..<board.rows {
            for column in 0..<board.columns {
                let first = Position(row: row, column: column)
                for second in [Position(row: row, column: column + 1), Position(row: row + 1, column: column)] where board.contains(second) {
                    var engine = Match3Engine(seed: 5)
                    if engine.resolveSwap(first, second, on: board) != nil { return (first, second) }
                }
            }
        }
        return nil
    }

    private static func firstInvalidMove(in board: GameBoard) -> (Position, Position)? {
        for row in 0..<board.rows {
            for column in 0..<board.columns {
                let first = Position(row: row, column: column)
                for second in [Position(row: row, column: column + 1), Position(row: row + 1, column: column)] where board.contains(second) {
                    var engine = Match3Engine(seed: 5)
                    if engine.resolveSwap(first, second, on: board) == nil { return (first, second) }
                }
            }
        }
        return nil
    }
}

private final class MemoryProgressStore: ProgressStoring, @unchecked Sendable {
    var saved: PlayerProgress?
    func load() -> PlayerProgress? { saved }
    func save(_ progress: PlayerProgress) throws { saved = progress }
}

private struct FailingProgressStore: ProgressStoring {
    func load() -> PlayerProgress? { nil }
    func save(_ progress: PlayerProgress) throws { throw ProgressStoreError.writeFailed }
}
#endif
