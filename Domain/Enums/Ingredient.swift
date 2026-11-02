import Foundation

public enum Ingredient: String, CaseIterable, Codable, Hashable, Identifiable, Sendable {
    case acai, cupuacu, brazilNut, jambu, tucupi, tapereba, bacuri, cassava

    public var id: String { rawValue }
    public var name: String {
        switch self {
        case .acai: "Açaí"
        case .cupuacu: "Cupuaçu"
        case .brazilNut: "Castanha"
        case .jambu: "Jambu"
        case .tucupi: "Tucupi"
        case .tapereba: "Taperebá"
        case .bacuri: "Bacuri"
        case .cassava: "Mandioca"
        }
    }
    public var symbol: String {
        switch self {
        case .acai: "🫐"
        case .cupuacu: "🥭"
        case .brazilNut: "🌰"
        case .jambu: "🌿"
        case .tucupi: "🫙"
        case .tapereba: "🍋"
        case .bacuri: "🍈"
        case .cassava: "🌱"
        }
    }
}
