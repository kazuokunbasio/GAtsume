import AudioToolbox
import AVFoundation
import UIKit

enum Sounds {
    private static var enabled: Bool {
        UserDefaults.standard.object(forKey: "soundEnabled") as? Bool ?? true
    }

    private static var players: [String: AVAudioPlayer] = [:]

    private static func play(systemId: SystemSoundID, customFile: String) {
        guard enabled else { return }
        if let url = bundleURL(for: customFile) {
            do {
                let player = try AVAudioPlayer(contentsOf: url)
                player.prepareToPlay()
                player.play()
                players[customFile] = player
                return
            } catch {
                print("❌ Sound \(customFile) failed: \(error)")
            }
        }
        AudioServicesPlaySystemSound(systemId)
    }

    private static func bundleURL(for name: String) -> URL? {
        for ext in ["m4a", "wav", "mp3", "caf"] {
            if let url = Bundle.main.url(forResource: name, withExtension: ext) {
                return url
            }
        }
        return nil
    }

    static func catchNormal() {
        play(systemId: 1104, customFile: "catch")
        UIImpactFeedbackGenerator(style: .light).impactOccurred()
    }

    static func catchRare() {
        play(systemId: 1336, customFile: "catch_rare")
        UIImpactFeedbackGenerator(style: .medium).impactOccurred()
    }

    static func catchSuperRare() {
        play(systemId: 1336, customFile: "catch_super")
        UINotificationFeedbackGenerator().notificationOccurred(.success)
    }

    static func purchase() {
        play(systemId: 1057, customFile: "purchase")
        UIImpactFeedbackGenerator(style: .medium).impactOccurred()
    }
}
