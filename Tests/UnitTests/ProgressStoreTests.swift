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
        progress.soundEnabled = false
        progress.musicEnabled = false
        progress.hapticsEnabled = false
        progress.prefersReducedMotion = true
        try store.save(progress)
        XCTAssertEqual(store.load()?.unlockedLevel, 7)
        XCTAssertEqual(store.load()?.completedLevels, [1, 2, 6])
        XCTAssertEqual(store.load()?.bestScores[6], 3200)
        XCTAssertEqual(store.load()?.soundEnabled, false)
        XCTAssertEqual(store.load()?.musicEnabled, false)
        XCTAssertEqual(store.load()?.hapticsEnabled, false)
        XCTAssertEqual(store.load()?.prefersReducedMotion, true)
    }

    func testInvalidProgressCannotOverwritePreviouslyValidProgress() throws {
        let folder = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString, isDirectory: true)
        defer { try? FileManager.default.removeItem(at: folder) }
        let url = folder.appendingPathComponent("progress.json")
        let store = LocalProgressStore(fileURL: url)
        var valid = PlayerProgress()
        valid.unlockedLevel = 9
        try store.save(valid)

        var invalid = PlayerProgress()
        invalid.unlockedLevel = 0
        XCTAssertThrowsError(try store.save(invalid))
        XCTAssertEqual(store.load()?.unlockedLevel, 9)
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
