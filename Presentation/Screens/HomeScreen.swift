import SwiftUI
import YumiApplication

@MainActor
struct HomeScreen: View {
    @ObservedObject var session: GameSession
    let onPlay: () -> Void
    let onSettings: () -> Void
    var body: some View {
        VStack(spacing: 10) {
            HStack {
                Text("YUMI").font(.system(size: 31, weight: .black, design: .rounded))
                Text("CRUSH").font(.system(size: 31, weight: .black, design: .rounded)).foregroundStyle(GameTheme.tucupi)
                Text("SAGA").font(.system(size: 16, weight: .heavy, design: .rounded)).padding(.top, 10)
                Spacer()
                Button(action: onSettings) { Image(systemName: "gearshape.fill").font(.title2).foregroundStyle(.white) }
                    .accessibilityLabel("Configurações")
            }.foregroundStyle(.white).padding(.horizontal, 25).padding(.top, 20)
            Spacer(minLength: 4)
            Text("Uma aventura pelo Pará").font(.system(size: 20, weight: .semibold, design: .rounded)).foregroundStyle(GameTheme.cupuacu)
            YumiMascot(mood: .happy, scale: 1.12)
            VStack(spacing: 7) {
                Text("Sabores, rios e descobertas").font(.system(size: 25, weight: .bold, design: .rounded)).foregroundStyle(.white)
                Text("Explore o Pará, uma combinação de cada vez.").font(.system(size: 15, weight: .medium, design: .rounded)).foregroundStyle(.white.opacity(0.78)).multilineTextAlignment(.center)
            }.padding(.horizontal, 24)
            Spacer(minLength: 8)
            PrimaryButton(title: "Jogar · Fase \(session.progress.unlockedLevel)", icon: "play.fill", action: onPlay)
            Text("AÇAÍ  ·  CUPUAÇU  ·  RIO  ·  FLORESTA")
                .font(.system(size: 10, weight: .bold, design: .rounded)).tracking(1.4).foregroundStyle(.white.opacity(0.7)).padding(.top, 7)
            Spacer(minLength: 22)
        }.padding(.bottom, 12)
    }
}
