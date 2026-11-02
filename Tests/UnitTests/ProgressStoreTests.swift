import Foundation
import XCTest
@testable import YumiEngine

final class ProgressStoreTests: XCTestCase {
    func testProgressRoundTripsUsingIsolatedFile() throws {
        let folder = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString, isDirectory: true)
        defer { try? FileManager.default.removeItem(at: folder) }
        let store = LocalProgressStore(fileURL: folder.appendingPathComponent("progress.json"))
        var progress = PlayerProgress()
        progress.unlockedLevel = 7
        progress.completedLevels = [1, 2, 6]
        progress.bestScores[6] = 3200
        try store.save(progress)
        XCTAssertEqual(store.load()?.unlockedLevel, 7)
        XCTAssertEqual(store.load()?.completedLevels, [1, 2, 6])
        XCTAssertEqual(store.load()?.bestScores[6], 3200)
    }

    func testCorruptSaveIsIgnoredAndPreserved() throws {
        let folder = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString, isDirectory: true)
        defer { try? FileManager.default.removeItem(at: folder) }
        try FileManager.default.createDirectory(at: folder, withIntermediateDirectories: true)
        let url = folder.appendingPathComponent("progress.json")
        let invalid = Data("invalid".utf8)
        try invalid.write(to: url)
        let store = LocalProgressStore(fileURL: url)
        XCTAssertNil(store.load())
        XCTAssertThrowsError(try store.save(PlayerProgress()))
        XCTAssertEqual(try Data(contentsOf: url), invalid)
    }
}
