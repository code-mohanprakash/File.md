// Haptics.swift
// FileFairy
//
// From PRD Section 5: Soft haptics on capture, conversion complete, navigation.
// Never harsh. Every haptic reinforces the cutesy brand.

import UIKit
import CoreHaptics

@MainActor
final class HapticEngine {

    static let shared = HapticEngine()

    private var supportsHaptics: Bool {
        CHHapticEngine.capabilitiesForHardware().supportsHaptics
    }

    private var coreEngine: CHHapticEngine?

    // Pre-prepared generators for instant response
    private let lightGenerator = UIImpactFeedbackGenerator(style: .light)
    private let mediumGenerator = UIImpactFeedbackGenerator(style: .medium)
    private let heavyGenerator = UIImpactFeedbackGenerator(style: .heavy)
    private let softGenerator = UIImpactFeedbackGenerator(style: .soft)
    private let notificationGenerator = UINotificationFeedbackGenerator()
    private let selectionGenerator = UISelectionFeedbackGenerator()

    private init() {
        prepareGenerators()
        prepareCoreHaptics()
    }

    private func prepareGenerators() {
        lightGenerator.prepare()
        mediumGenerator.prepare()
        softGenerator.prepare()
        notificationGenerator.prepare()
        selectionGenerator.prepare()
    }

    private func prepareCoreHaptics() {
        guard supportsHaptics else { return }
        do {
            coreEngine = try CHHapticEngine()
            coreEngine?.resetHandler = { [weak self] in
                try? self?.coreEngine?.start()
            }
            try coreEngine?.start()
        } catch {
            // Haptics unavailable - fail silently
        }
    }

    // MARK: - Simple Feedback

    /// Light tap - button press, tab switch, navigation
    func light() {
        lightGenerator.impactOccurred()
    }

    /// Medium tap - file pickup, card selection
    func medium() {
        mediumGenerator.impactOccurred()
    }

    /// Heavy tap - file drop, delete confirmation
    func heavy() {
        heavyGenerator.impactOccurred()
    }

    /// Ultra-soft - fairy appearance, subtle feedback
    func soft() {
        softGenerator.impactOccurred()
    }

    /// Success notification - scan complete, conversion done
    func success() {
        notificationGenerator.notificationOccurred(.success)
    }

    /// Warning notification - large file alert
    func warning() {
        notificationGenerator.notificationOccurred(.warning)
    }

    /// Error notification - operation failed
    func error() {
        notificationGenerator.notificationOccurred(.error)
    }

    /// Selection change - picker scrolling, list reorder
    func selection() {
        selectionGenerator.selectionChanged()
    }

    // MARK: - Custom Patterns (CoreHaptics)

    /// Fairy magic - three rising soft pulses for mascot appearance
    func fairyMagic() {
        guard supportsHaptics, let engine = coreEngine else {
            soft()
            return
        }

        let events: [CHHapticEvent] = [
            CHHapticEvent(
                eventType: .hapticTransient,
                parameters: [
                    CHHapticEventParameter(parameterID: .hapticIntensity, value: 0.3),
                    CHHapticEventParameter(parameterID: .hapticSharpness, value: 0.1)
                ],
                relativeTime: 0
            ),
            CHHapticEvent(
                eventType: .hapticTransient,
                parameters: [
                    CHHapticEventParameter(parameterID: .hapticIntensity, value: 0.5),
                    CHHapticEventParameter(parameterID: .hapticSharpness, value: 0.15)
                ],
                relativeTime: 0.12
            ),
            CHHapticEvent(
                eventType: .hapticTransient,
                parameters: [
                    CHHapticEventParameter(parameterID: .hapticIntensity, value: 0.8),
                    CHHapticEventParameter(parameterID: .hapticSharpness, value: 0.2)
                ],
                relativeTime: 0.28
            )
        ]

        playPattern(events: events, engine: engine)
    }

    /// Scan capture - satisfying snap + echo
    func scanCapture() {
        guard supportsHaptics, let engine = coreEngine else {
            medium()
            return
        }

        let events: [CHHapticEvent] = [
            CHHapticEvent(
                eventType: .hapticTransient,
                parameters: [
                    CHHapticEventParameter(parameterID: .hapticIntensity, value: 0.9),
                    CHHapticEventParameter(parameterID: .hapticSharpness, value: 0.7)
                ],
                relativeTime: 0
            ),
            CHHapticEvent(
                eventType: .hapticTransient,
                parameters: [
                    CHHapticEventParameter(parameterID: .hapticIntensity, value: 0.3),
                    CHHapticEventParameter(parameterID: .hapticSharpness, value: 0.2)
                ],
                relativeTime: 0.08
            )
        ]

        playPattern(events: events, engine: engine)
    }

    private func playPattern(events: [CHHapticEvent], engine: CHHapticEngine) {
        do {
            let pattern = try CHHapticPattern(events: events, parameters: [])
            let player = try engine.makePlayer(with: pattern)
            try player.start(atTime: 0)
        } catch {
            // Fallback silently
        }
    }
}
