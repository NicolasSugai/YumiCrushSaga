import SwiftUI

enum GameTheme {
    static let river = Color(red: 0.08, green: 0.40, blue: 0.56)
    static let deepRiver = Color(red: 0.04, green: 0.20, blue: 0.32)
    static let acai = Color(red: 0.34, green: 0.16, blue: 0.47)
    static let forest = Color(red: 0.10, green: 0.38, blue: 0.28)
    static let tucupi = Color(red: 0.94, green: 0.66, blue: 0.18)
    static let cupuacu = Color(red: 0.98, green: 0.91, blue: 0.76)
    static let terracotta = Color(red: 0.72, green: 0.31, blue: 0.20)
    static let canvas = Color(red: 0.96, green: 0.94, blue: 0.86)
    static let gradient = LinearGradient(colors: [river, deepRiver, forest], startPoint: .topLeading, endPoint: .bottomTrailing)
}
