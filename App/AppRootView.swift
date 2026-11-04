import SwiftUI
import YumiApplication

@MainActor
struct AppRootView: View {
    @StateObject private var session = GameSession()
    @State private var screen: AppScreen = .home
    @Environment(\.scenePhase) private var scenePhase
    var body: some View {
        ZStack {
            GameTheme.gradient.ignoresSafeArea()
            AmazonLandscape()
            switch screen {
            case .home:
                HomeScreen(session: session, onPlay: { screen = .levels }, onSettings: { screen = .settings })
            case .levels:
                LevelSelectScreen(session: session, onBack: { screen = .home }, onStart: { number in session.start(level: number); screen = .game })
            case .game:
                GameScreen(session: session, onHome: { screen = .home }, onNext: { session.start(); screen = .game })
            case .settings:
                SettingsScreen(session: session, onBack: { screen = .home })
            }
        }
        .preferredColorScheme(.light)
        .onAppear { GameFeedback.shared.setMusic(session.progress.musicEnabled && scenePhase == .active) }
        .onChange(of: session.progress.musicEnabled) { enabled in GameFeedback.shared.setMusic(enabled && scenePhase == .active) }
        .onChange(of: scenePhase) { phase in GameFeedback.shared.setMusic(session.progress.musicEnabled && phase == .active) }
        .alert("Progresso não salvo", isPresented: Binding(
            get: { session.persistenceError != nil },
            set: { isPresented in if !isPresented { session.dismissPersistenceError() } }
        )) {
            Button("OK") { session.dismissPersistenceError() }
        } message: {
            Text(session.persistenceError ?? "Tente novamente mais tarde.")
        }
    }
}

private enum AppScreen { case home, levels, game, settings }
