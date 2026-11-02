import Foundation
import Combine
import YumiEngine

@MainActor
public final class GameSession: ObservableObject {
    @Published public private(set) var board: GameBoard
    @Published public private(set) var level: LevelConfiguration
    @Published public private(set) var score = 0
    @Published public private(set) var moves: Int
    @Published public private(set) var collected: [Ingredient: Int] = [:]
    @Published public private(set) var specialsCreated = 0
    @Published public private(set) var isResolving = false
    @Published public private(set) var lastTriggeredSpecial = false
    @Published public private(set) var result: GameResult?
    @Published public var selected: Position?
    @Published public private(set) var progress: PlayerProgress
    private var engine: Match3Engine
    private let store: ProgressStoring

    public init(store: ProgressStoring = LocalProgressStore()) {
        let saved = store.load() ?? PlayerProgress()
        let configuration = LevelConfiguration.generated(number: saved.unlockedLevel)
        var newEngine = Match3Engine(seed: UInt64.random(in: 1...UInt64.max))
        let newBoard = newEngine.makeBoard(ingredientCount: configuration.ingredientCount)
        self.store = store
        progress = saved
        level = configuration
        moves = configuration.moves
        engine = newEngine
        board = newBoard
    }
    public func start(level number: Int? = nil) {
        let target = number ?? progress.unlockedLevel
        start(configuration: .generated(number: target))
    }
    public func start(configuration: LevelConfiguration, seed: UInt64? = nil) {
        level = configuration
        moves = configuration.moves; score = 0; collected = [:]; specialsCreated = 0; result = nil; selected = nil; isResolving = false
        lastTriggeredSpecial = false
        engine = Match3Engine(seed: seed ?? UInt64.random(in: 1...UInt64.max))
        board = engine.makeBoard(ingredientCount: level.ingredientCount)
    }
    public func choose(_ position: Position) {
        guard !isResolving, result == nil, board.contains(position), board[position] != nil else { return }
        guard let current = selected else { selected = position; return }
        if current == position { selected = nil; return }
        if current.isAdjacent(to: position) { play(current, position) }
        else { selected = position }
    }
    public func play(_ first: Position, _ second: Position) {
        guard !isResolving, result == nil else { return }
        selected = nil
        guard let resolution = engine.resolveSwap(first, second, on: board) else { return }
        isResolving = true
        moves -= 1
        lastTriggeredSpecial = resolution.specialsTriggered
        board = resolution.board
        score += resolution.scoreEarned
        for (ingredient, count) in resolution.collected { collected[ingredient, default: 0] += count }
        if resolution.specialCreated != nil { specialsCreated += 1 }
        isResolving = false
        checkResult()
    }
    public var goalText: String {
        switch level.goal {
        case .score(let target): return "Alcance \(target) pontos"
        case .collect(let ingredient, let target): return "Colete \(target) · \(ingredient.name)"
        case .specials(let target): return "Crie \(target) especiais"
        }
    }
    public var goalProgress: String {
        switch level.goal {
        case .score(let target): return "\(min(score, target)) / \(target)"
        case .collect(let ingredient, let target): return "\(min(collected[ingredient, default: 0], target)) / \(target)"
        case .specials(let target): return "\(min(specialsCreated, target)) / \(target)"
        }
    }
    public func toggleSound() { progress.soundEnabled.toggle(); persist() }
    public func toggleMusic() { progress.musicEnabled.toggle(); persist() }
    public func toggleHaptics() { progress.hapticsEnabled.toggle(); persist() }
    public func toggleReducedMotion() { progress.prefersReducedMotion.toggle(); persist() }
    private func checkResult() {
        let achieved: Bool
        switch level.goal {
        case .score(let target): achieved = score >= target
        case .collect(let ingredient, let target): achieved = collected[ingredient, default: 0] >= target
        case .specials(let target): achieved = specialsCreated >= target
        }
        if achieved {
            result = .victory
            progress.completedLevels.insert(level.number)
            progress.bestScores[level.number] = max(progress.bestScores[level.number, default: 0], score)
            progress.unlockedLevel = max(progress.unlockedLevel, level.number + 1)
            persist()
        } else if moves <= 0 {
            result = .defeat
            progress.bestScores[level.number] = max(progress.bestScores[level.number, default: 0], score)
            persist()
        }
    }
    private func persist() { try? store.save(progress) }
}

public enum GameResult: Equatable { case victory, defeat }
