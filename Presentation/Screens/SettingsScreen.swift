import SwiftUI
import YumiApplication

@MainActor
struct SettingsScreen: View {
    @ObservedObject var session: GameSession
    let onBack: () -> Void
    var body: some View {
        VStack(spacing: 18) {
            ScreenHeader(title: "Configurações", onBack: onBack)
            VStack(spacing: 0) {
                settingRow("Efeitos sonoros", subtitle: "Sons originais do jogo", isOn: session.progress.soundEnabled, toggle: session.toggleSound)
                Divider().padding(.leading, 18)
                settingRow("Música", subtitle: "Trilha ambiente", isOn: session.progress.musicEnabled, toggle: session.toggleMusic)
                Divider().padding(.leading, 18)
                settingRow("Vibração", subtitle: "Feedback ao combinar", isOn: session.progress.hapticsEnabled, toggle: session.toggleHaptics)
                Divider().padding(.leading, 18)
                settingRow("Reduzir movimento", subtitle: "Animações mais discretas", isOn: session.progress.prefersReducedMotion, toggle: session.toggleReducedMotion)
            }
            .background(GameTheme.cupuacu, in: RoundedRectangle(cornerRadius: 22))
            .padding(.horizontal, 20)
            Text("YumiCrushSaga é uma aventura local, sem anúncios ou conexão com a internet.")
                .font(.footnote).foregroundStyle(.white.opacity(0.75)).multilineTextAlignment(.center).padding(.horizontal, 36)
            Spacer()
        }.padding(.top, 18)
    }
    private func settingRow(_ title: String, subtitle: String, isOn: Bool, toggle: @escaping () -> Void) -> some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(title).font(.system(size: 16, weight: .bold, design: .rounded)).foregroundStyle(GameTheme.deepRiver)
                Text(subtitle).font(.caption).foregroundStyle(GameTheme.river)
            }
            Spacer()
            Toggle(title, isOn: Binding(get: { isOn }, set: { _ in toggle() })).labelsHidden().tint(GameTheme.forest)
        }.padding(18)
    }
}
