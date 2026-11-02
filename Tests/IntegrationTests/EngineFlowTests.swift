import XCTest
@testable import YumiEngine

final class EngineFlowTests: XCTestCase {
    func testLegalMoveResolvesIntoFullBoardAndCountsCascade() {
        var engine = Match3Engine(seed: 815)
        var board = engine.makeBoard()
        var resolution: MoveResolution?
        for row in 0..<8 {
            for column in 0..<8 where resolution == nil {
                let p = Position(row: row, column: column)
                for q in [Position(row: row, column: column + 1), Position(row: row + 1, column: column)] where board.contains(q) && resolution == nil {
                    resolution = engine.resolveSwap(p, q, on: board)
                }
            }
        }
        XCTAssertNotNil(resolution)
        board = resolution!.board
        XCTAssertEqual(board.pieces.count, 8)
        XCTAssertTrue(board.pieces.allSatisfy { $0.count == 8 && $0.allSatisfy { $0 != nil } })
        XCTAssertGreaterThan(resolution!.scoreEarned, 0)
        XCTAssertTrue(engine.matches(in: board).isEmpty)
        XCTAssertTrue(engine.hasLegalMove(board))
    }
}
