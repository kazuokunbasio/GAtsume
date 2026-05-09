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
        UIImpactFeedbackGenerator(style: .light).impactOccurred(intensity: 0.7)
    }

    static func catchRare() {
        play(systemId: 1336, customFile: "catch_rare")
        let gen = UIImpactFeedbackGenerator(style: .medium)
        gen.prepare()
        gen.impactOccurred()
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.08) {
            gen.impactOccurred(intensity: 0.7)
        }
    }

    static func catchSuperRare() {
        play(systemId: 1336, customFile: "catch_super")
        UINotificationFeedbackGenerator().notificationOccurred(.success)
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.18) {
            UIImpactFeedbackGenerator(style: .heavy).impactOccurred()
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.32) {
            UIImpactFeedbackGenerator(style: .medium).impactOccurred()
        }
    }

    static func purchase() {
        play(systemId: 1057, customFile: "purchase")
        UIImpactFeedbackGenerator(style: .medium).impactOccurred()
    }
}
