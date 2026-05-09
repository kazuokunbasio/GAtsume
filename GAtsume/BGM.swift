import AVFoundation
import Foundation

enum BGM {
    private static var player: AVAudioPlayer?

    static var enabled: Bool {
        UserDefaults.standard.object(forKey: "bgmEnabled") as? Bool ?? false
    }

    static var volume: Float {
        UserDefaults.standard.object(forKey: "bgmVolume") as? Float ?? 0.4
    }

    static func setEnabled(_ on: Bool) {
        UserDefaults.standard.set(on, forKey: "bgmEnabled")
        if on {
            startIfEnabled()
        } else {
            stop()
        }
    }

    static func setVolume(_ v: Float) {
        UserDefaults.standard.set(v, forKey: "bgmVolume")
        player?.volume = v
    }

    static func startIfEnabled() {
        guard enabled else { return }
        if let p = player {
            p.volume = volume
            if !p.isPlaying { p.play() }
            return
        }
        for ext in ["m4a", "mp3", "wav", "caf"] {
            if let url = Bundle.main.url(forResource: "bgm", withExtension: ext) {
                do {
                    try AVAudioSession.sharedInstance().setCategory(
                        .ambient, mode: .default, options: [.mixWithOthers]
                    )
                    try AVAudioSession.sharedInstance().setActive(true)
                    let p = try AVAudioPlayer(contentsOf: url)
                    p.numberOfLoops = -1
                    p.volume = volume
                    p.prepareToPlay()
                    p.play()
                    player = p
                    return
                } catch {
                    print("❌ BGM init failed: \(error)")
                }
            }
        }
    }

    static func stop() {
        player?.stop()
        player = nil
    }
}
