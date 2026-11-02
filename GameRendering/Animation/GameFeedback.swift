import AVFoundation
import UIKit

@MainActor
final class GameFeedback {
    static let shared = GameFeedback()
    private var effectPlayer: AVAudioPlayer?
    private var musicPlayer: AVAudioPlayer?
    private init() {}

    func play(_ name: String, enabled: Bool) {
        guard enabled, let url = Bundle.main.url(forResource: name, withExtension: "wav", subdirectory: "Audio"),
              let player = try? AVAudioPlayer(contentsOf: url) else { return }
        effectPlayer = player
        player.play()
    }
    func setMusic(_ enabled: Bool) {
        guard let url = Bundle.main.url(forResource: "ambience", withExtension: "wav", subdirectory: "Audio") else { return }
        if enabled {
            if musicPlayer == nil { musicPlayer = try? AVAudioPlayer(contentsOf: url); musicPlayer?.numberOfLoops = -1; musicPlayer?.volume = 0.12 }
            musicPlayer?.play()
        } else { musicPlayer?.pause() }
    }
    func haptic(enabled: Bool) {
        guard enabled else { return }
        UIImpactFeedbackGenerator(style: .light).impactOccurred()
    }
}
