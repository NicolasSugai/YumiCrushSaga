#if canImport(Combine)
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

            session.start(configuration: level, seed: 77)
            XCTAssertNil(session.result)
            XCTAssertEqual(session.score, 0)
            XCTAssertEqual(session.moves, 1)
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
}

private final class MemoryProgressStore: ProgressStoring, @unchecked Sendable {
    var saved: PlayerProgress?
    func load() -> PlayerProgress? { saved }
    func save(_ progress: PlayerProgress) throws { saved = progress }
}
#endif
