import Foundation

public enum LevelGoal: Codable, Hashable, Sendable {
    case score(Int)
    case collect(Ingredient, Int)
    case specials(Int)
}

public struct LevelConfiguration: Codable, Hashable, Sendable {
    public let number: Int
    public let moves: Int
    public let goal: LevelGoal
    public let ingredientCount: Int
    public let region: String
    public init(number: Int, moves: Int, goal: LevelGoal, ingredientCount: Int, region: String) {
        self.number = number; self.moves = moves; self.goal = goal
        self.ingredientCount = ingredientCount; self.region = region
    }
    public static func generated(number: Int) -> LevelConfiguration {
        let level = max(1, number)
        let ingredients = Ingredient.allCases
        let targetIndex = (level - 1) % ingredients.count
        let targetIngredient = ingredients[targetIndex]
        let moves = max(12, 25 - (level - 1) / 3)
        let regions = ["Ver-o-Peso", "Rio Guamá", "Ilha do Combu", "Floresta de Utinga"]
        let region = regions[((level - 1) / 2) % regions.count]
        let ingredientCount = max(min(6, 5 + level / 8), targetIndex + 1)
        if level.isMultiple(of: 5) {
            return .init(number: level, moves: moves, goal: .specials(1 + min(level / 15, 1)), ingredientCount: ingredientCount, region: region)
        }
        if level.isMultiple(of: 2) {
            let difficultyTarget = 10 + min((level - 1) / 4, 5)
            let boardCapacityTarget = max(8, moves * 4 / ingredientCount)
            let collectionTarget = min(difficultyTarget, boardCapacityTarget)
            return .init(number: level, moves: moves, goal: .collect(targetIngredient, collectionTarget), ingredientCount: ingredientCount, region: region)
        }
        return .init(number: level, moves: moves, goal: .score(900 + min(level - 1, 6) * 150), ingredientCount: ingredientCount, region: region)
    }
}
