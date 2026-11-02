import SwiftUI

struct PrimaryButton: View {
    let title: String
    var icon: String = "arrow.right"
    let action: () -> Void
    var body: some View {
        Button(action: action) {
            Label(title, systemImage: icon)
                .font(.system(size: 18, weight: .bold, design: .rounded))
                .foregroundStyle(GameTheme.deepRiver)
                .padding(.horizontal, 30).padding(.vertical, 16)
                .background(GameTheme.tucupi, in: Capsule())
                .shadow(color: .black.opacity(0.16), radius: 8, y: 5)
        }
        .buttonStyle(.plain)
        .accessibilityHint(title)
    }
}
