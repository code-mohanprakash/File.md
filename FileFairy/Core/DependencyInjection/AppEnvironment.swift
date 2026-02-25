// AppEnvironment.swift
// FileFairy
//
// Root dependency container. One instance lives in FileFairyApp and is
// propagated down the view hierarchy via SwiftUI's environment.
// Feature views read it with @Environment(\.appEnvironment).

import SwiftUI
import Observation

// MARK: - AppEnvironment

/// The single, app-wide object that owns shared service singletons and
/// state that crosses feature boundaries.
///
/// Prefer injecting specific sub-services (router, haptics, etc.) into
/// feature view models where possible. Pass AppEnvironment directly only
/// to top-level container views.
@Observable
final class AppEnvironment {

    // MARK: - Navigation

    /// The single navigation router for the entire app.
    let router = AppRouter()

    // MARK: - Shared Services

    /// Main haptic feedback engine. @MainActor-isolated.
    let haptics = HapticEngine.shared

    /// Sound effect player. @MainActor-isolated.
    let sounds = SoundPlayer.shared

    /// StoreKit 2 subscription service.
    let storeKit = StoreKitService()

    // MARK: - Subscription State

    /// Always true — all features are free.
    var isPremium: Bool { true }

    // MARK: - App Lifecycle Flags

    /// Set to true after the user has completed onboarding.
    var hasCompletedOnboarding: Bool {
        get { UserDefaults.standard.bool(forKey: Keys.hasCompletedOnboarding) }
        set { UserDefaults.standard.set(newValue, forKey: Keys.hasCompletedOnboarding) }
    }

    // MARK: - Initializer

    init() {
        // Nothing async at init time; StoreKit listener is set up in FileFairyApp.
    }

    // MARK: - Private Keys

    private enum Keys {
        static let hasCompletedOnboarding = "filefairy.onboardingComplete"
    }
}
