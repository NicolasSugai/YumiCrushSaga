import SwiftUI
import SpriteKit
import YumiApplication

@MainActor
struct GameScreen: View {
    @ObservedObject var session: GameSession
    let onHome: () -> Void
    let onNext: () -> Void
    @State private var scene = MatchBoardScene(size: CGSize(width: 360, height: 360))
    @State private var paused = false
    var body: some View {
        VStack(spacing: 10) {
            HStack {
                Button(action: onHome) { Image(systemName: "house.fill").font(.headline).foregroundStyle(.white).frame(width: 42, height: 42).background(.white.opacity(0.15), in: Circle()) }.accessibilityLabel("Início")
                VStack(alignment: .leading, spacing: 2) {
                    Text("FASE \(session.level.number)").font(.system(size: 12, weight: .heavy, design: .rounded)).foregroundStyle(GameTheme.tucupi)
                    Text(session.level.region).font(.system(size: 17, weight: .bold, design: .rounded)).foregroundStyle(.white)
                }
                Spacer()
                Button { paused.toggle() } label: { Image(systemName: paused ? "play.fill" : "pause.fill").foregroundStyle(.white).frame(width: 42, height: 42).background(.white.opacity(0.15), in: Circle()) }.accessibilityLabel(paused ? "Continuar" : "Pausar")
            }.padding(.horizontal, 18)
            HStack(spacing: 12) {
                StatCard(title: "OBJETIVO", value: session.goalProgress, detail: session.goalText, tint: GameTheme.tucupi)
                StatCard(title: "PONTOS", value: "\(session.score)", detail: "Recorde \(session.progress.bestScores[session.level.number, default: 0])", tint: GameTheme.cupuacu)
                StatCard(title: "JOGADAS", value: "\(session.moves)", detail: "Restantes", tint: .white)
            }.padding(.horizontal, 14)
            ZStack {
                RoundedRectangle(cornerRadius: 24).fill(Color.white.opacity(0.12))
                SpriteView(scene: scene, options: [.ignoresSiblingOrder]).padding(7)
                    .accessibilityLabel("Tabuleiro Match-3 de oito por oito")
            }
            .aspectRatio(1, contentMode: .fit).padding(.horizontal, 13)
            HStack(spacing: 12) {
                YumiMascot(mood: session.moves < 5 ? .encouraging : .happy, scale: 0.45).frame(width: 86, height: 86).clipped()
                VStack(alignment: .leading, spacing: 4) {
                    Text(session.moves < 5 ? "Você consegue!" : "Vamos nessa!").font(.system(size: 16, weight: .bold, design: .rounded)).foregroundStyle(.white)
                    Text(paused ? "Toque em continuar para voltar à partida." : "Toque em duas peças ou deslize para trocar.").font(.system(size: 12, weight: .medium, design: .rounded)).foregroundStyle(.white.opacity(0.75))
                }
                Spacer(minLength: 0)
            }.padding(.horizontal, 18)
            Spacer(minLength: 2)
        }
        .padding(.top, 13).padding(.bottom, 6)
        .onAppear { connectScene() }
        .onChange(of: session.board) { board in scene.update(board: board, selected: session.selected) }
        .onChange(of: session.selected) { selected in scene.update(board: session.board, selected: selected) }
        .onChange(of: session.progress.prefersReducedMotion) { enabled in
            scene.prefersReducedMotion = enabled
            scene.update(board: session.board, selected: session.selected)
        }
        .onChange(of: session.score) { score in
            if score > 0 {
                GameFeedback.shared.play(session.lastTriggeredSpecial ? "special" : "match", enabled: session.progress.soundEnabled)
                GameFeedback.shared.haptic(enabled: session.progress.hapticsEnabled)
            }
        }
        .onChange(of: session.result) { result in
            guard let result else { return }
            GameFeedback.shared.play(result == .victory ? "victory" : "encourage", enabled: session.progress.soundEnabled)
        }
        .overlay {
            if paused { PauseOverlay(onResume: { paused = false }, onHome: onHome) }
            if let result = session.result { ResultOverlay(result: result, score: session.score, onPrimary: result == .victory ? onNext : { session.start(level: session.level.number) }, onHome: onHome) }
        }
    }
    private func connectScene() {
        scene.backgroundColor = .clear
        scene.onSelect = { [weak session] position in
            guard !paused else { return }
            session?.choose(position)
        }
        scene.update(board: session.board, selected: session.selected)
    }
}

private struct StatCard: View {
    let title: String
    let value: String
    let detail: String
    let tint: Color
    var body: some View {
        VStack(alignment: .leading, spacing: 3) {
            Text(title).font(.system(size: 9, weight: .heavy, design: .rounded)).foregroundStyle(tint.opacity(0.82))
            Text(value).font(.system(size: 17, weight: .black, design: .rounded)).foregroundStyle(.white).lineLimit(1).minimumScaleFactor(0.7)
            Text(detail).font(.system(size: 8, weight: .medium, design: .rounded)).foregroundStyle(.white.opacity(0.66)).lineLimit(1)
        }.frame(maxWidth: .infinity, alignment: .leading).padding(10).background(.white.opacity(0.11), in: RoundedRectangle(cornerRadius: 14))
    }
}

private struct PauseOverlay: View {
    let onResume: () -> Void
    let onHome: () -> Void
    var body: some View {
        VStack(spacing: 18) {
            Text("Pausa").font(.system(size: 30, weight: .black, design: .rounded)).foregroundStyle(.white)
            PrimaryButton(title: "Continuar", icon: "play.fill", action: onResume)
            Button("Voltar ao início", action: onHome).foregroundStyle(.white)
        }.frame(maxWidth: .infinity, maxHeight: .infinity).background(GameTheme.deepRiver.opacity(0.9))
    }
}

private struct ResultOverlay: View {
    let result: GameResult
    let score: Int
    let onPrimary: () -> Void
    let onHome: () -> Void
    private var won: Bool { result == .victory }
    var body: some View {
        VStack(spacing: 12) {
            YumiMascot(mood: won ? .celebration : .encouraging, scale: 0.83).frame(height: 168).clipped()
            Text(won ? "Parabéns!" : "Quase lá!").font(.system(size: 31, weight: .black, design: .rounded)).foregroundStyle(.white)
            Text(won ? "Uma nova parada espera por você." : "Toda aventura fica melhor na próxima tentativa.").font(.subheadline).foregroundStyle(.white.opacity(0.8)).multilineTextAlignment(.center).padding(.horizontal, 24)
            Text("\(score) pontos").font(.system(size: 20, weight: .bold, design: .rounded)).foregroundStyle(GameTheme.tucupi)
            PrimaryButton(title: won ? "Próxima fase" : "Tentar de novo", icon: won ? "arrow.right" : "arrow.clockwise", action: onPrimary)
            Button("Início", action: onHome).foregroundStyle(.white.opacity(0.82))
        }.frame(maxWidth: .infinity, maxHeight: .infinity).background(GameTheme.deepRiver.opacity(0.95))
    }
}
