import Foundation

public struct GamePiece: Hashable, Codable, Sendable {
    public var ingredient: Ingredient
    public var special: SpecialKind?
    public init(ingredient: Ingredient, special: SpecialKind? = nil) {
        self.ingredient = ingredient; self.special = special
    }
}
