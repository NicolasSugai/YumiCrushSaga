import SwiftUI
import YumiApplication

@MainActor
struct LevelSelectScreen: View {
    @ObservedObject var session: GameSession
    let onBack: () -> Void
    let onStart: (Int) -> Void
    private let columns = Array(repeating: GridItem(.flexible(), spacing: 12), count: 4)
    var body: some View {
        VStack(spacing: 18) {
            ScreenHeader(title: "Sua jornada", onBack: onBack)
            Text("A cada parada, um novo sabor do Pará.").font(.subheadline).foregroundStyle(.white.opacity(0.78))
            LazyVGrid(columns: columns, spacing: 12) {
                ForEach(1...24, id: \.self) { number in
                    let unlocked = number <= session.progress.unlockedLevel
                    Button { if unlocked { onStart(number) } } label: {
                        VStack(spacing: 4) {
                            Image(systemName: unlocked ? (session.progress.completedLevels.contains(number) ? "star.fill" : "leaf.fill") : "lock.fill")
                                .font(.system(size: 17, weight: .bold))
                                .foregroundStyle(session.progress.completedLevels.contains(number) ? GameTheme.tucupi : GameTheme.forest)
                            Text("\(number)").font(.system(size: 16, weight: .heavy, design: .rounded)).foregroundStyle(GameTheme.deepRiver)
                            Text(session.progress.completedLevels.contains(number) ? "FEITA" : "FASE")
                                .font(.system(size: 8, weight: .bold)).foregroundStyle(GameTheme.river)
                        }
                        .frame(maxWidth: .infinity).frame(height: 72)
                        .background(unlocked ? GameTheme.cupuacu : Color.white.opacity(0.48), in: RoundedRectangle(cornerRadius: 18))
                    }.disabled(!unlocked)
                }
            }.padding(.horizontal, 22)
            Spacer()
        }.padding(.top, 18)
    }
}

struct ScreenHeader: View {
    let title: String
    let onBack: () -> Void
    var body: some View {
        HStack {
            Button(action: onBack) { Image(systemName: "chevron.left").font(.headline).foregroundStyle(.white).frame(width: 42, height: 42).background(.white.opacity(0.14), in: Circle()) }
                .accessibilityLabel("Voltar")
            Text(title).font(.system(size: 24, weight: .bold, design: .rounded)).foregroundStyle(.white)
            Spacer()
        }.padding(.horizontal, 20)
    }
}
