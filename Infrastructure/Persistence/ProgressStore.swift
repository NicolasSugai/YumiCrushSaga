import Foundation

public struct PlayerProgress: Codable, Sendable {
    public var schemaVersion = 1
    public var unlockedLevel = 1
    public var completedLevels: Set<Int> = []
    public var bestScores: [Int: Int] = [:]
    public var soundEnabled = true
    public var musicEnabled = true
    public var hapticsEnabled = true
    public var prefersReducedMotion = false
    public init() {}
}

public protocol ProgressStoring {
    func load() -> PlayerProgress?
    func save(_ progress: PlayerProgress) throws
}

public enum ProgressStoreError: Error, Equatable {
    case invalidProgress
    case corruptExistingSave
    case writeFailed
}

public struct LocalProgressStore: ProgressStoring {
    private let fileURL: URL
    public init(fileURL: URL? = nil) {
        self.fileURL = fileURL ?? FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask)[0]
            .appendingPathComponent("YumiCrushSaga", isDirectory: true)
            .appendingPathComponent("progress.json")
    }
    public func load() -> PlayerProgress? {
        guard let data = try? Data(contentsOf: fileURL),
              let progress = try? JSONDecoder().decode(PlayerProgress.self, from: data),
              isValid(progress) else { return nil }
        return progress
    }
    public func save(_ progress: PlayerProgress) throws {
        guard isValid(progress) else { throw ProgressStoreError.invalidProgress }
        if FileManager.default.fileExists(atPath: fileURL.path) {
            guard let existingData = try? Data(contentsOf: fileURL),
                  let existing = try? JSONDecoder().decode(PlayerProgress.self, from: existingData),
                  isValid(existing) else { throw ProgressStoreError.corruptExistingSave }
        }
        let data = try JSONEncoder().encode(progress)
        try FileManager.default.createDirectory(at: fileURL.deletingLastPathComponent(), withIntermediateDirectories: true)
        try data.write(to: fileURL, options: .atomic)
    }
    private func isValid(_ progress: PlayerProgress) -> Bool {
        progress.schemaVersion == 1 && progress.unlockedLevel >= 1
            && progress.completedLevels.allSatisfy { $0 > 0 }
            && progress.bestScores.allSatisfy { $0.key > 0 && $0.value >= 0 }
    }
}
