// SoundEffect.swift
// FileFairy
//
// From PRD Section 8: Subtle, satisfying sounds that reinforce the cutesy brand.
// No sounds are loud or jarring. All sounds are soft, warm, and slightly whimsical.
// Audio equivalent of rounded corners.

import AVFoundation

enum SoundEffect: String, CaseIterable {
    /// App launch - soft chime ascending 3 notes (C-E-G), tiny sparkle (600ms)
    case launch = "sound_launch"

    /// Scan capture - camera shutter + soft "pop" (200ms)
    case capture = "sound_capture"

    /// File imported - gentle "whoosh" in + soft landing (400ms)
    case fileImport = "sound_import"

    /// Conversion start - soft whir/hum beginning (200ms)
    case conversionStart = "sound_convert_start"

    /// Conversion done - rising chime + sparkle burst (500ms)
    case conversionDone = "sound_convert_done"

    /// Button tap - soft rounded "tap" (80ms)
    case tap = "sound_tap"

    /// Delete - soft "poof" with descending note (300ms)
    case delete = "sound_delete"

    /// Error - gentle "bonk" (200ms)
    case error = "sound_error"

    /// Share - soft swoosh outward (250ms)
    case share = "sound_share"

    /// Tab switch - tiny click with pitch shift (50ms)
    case tabSwitch = "sound_tab"
}

@MainActor
final class SoundPlayer {

    static let shared = SoundPlayer()

    private var players: [SoundEffect: AVAudioPlayer] = [:]
    private var isEnabled: Bool

    private init() {
        isEnabled = UserDefaults.standard.object(forKey: "filefairy.sounds") as? Bool ?? true
        configureAudioSession()
        preloadSounds()
    }

    /// Toggle sound on/off
    var soundEnabled: Bool {
        get { isEnabled }
        set {
            isEnabled = newValue
            UserDefaults.standard.set(newValue, forKey: "filefairy.sounds")
        }
    }

    private func configureAudioSession() {
        // Ambient category: mixes with other audio, respects silent switch
        try? AVAudioSession.sharedInstance().setCategory(
            .ambient,
            options: [.mixWithOthers]
        )
    }

    private func preloadSounds() {
        for effect in SoundEffect.allCases {
            // Try .caf first, then .m4a, then .wav
            let extensions = ["caf", "m4a", "wav"]
            for ext in extensions {
                if let url = Bundle.main.url(forResource: effect.rawValue, withExtension: ext) {
                    if let player = try? AVAudioPlayer(contentsOf: url) {
                        player.prepareToPlay()
                        player.volume = 0.6
                        players[effect] = player
                        break
                    }
                }
            }
        }
    }

    /// Play a sound effect
    func play(_ effect: SoundEffect, volume: Float = 0.6) {
        guard isEnabled else { return }

        if let player = players[effect] {
            player.volume = volume
            player.currentTime = 0
            player.play()
        }
    }
}
