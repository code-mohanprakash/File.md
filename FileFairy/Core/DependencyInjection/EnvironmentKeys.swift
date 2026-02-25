// EnvironmentKeys.swift
// FileFairy
//
// SwiftUI EnvironmentKey declarations for FileFairy's custom environment values.
// Usage:
//   Inject:  .environment(appEnvironment)  (type-safe, no key required)
//   Read:    @Environment(AppEnvironment.self) private var env
//
// The @Observable macro on AppEnvironment makes it directly injectable via
// .environment(_:) without needing a custom EnvironmentKey. The key below
// is provided for scenarios where a default value is needed (e.g., previews
// that don't inject an instance explicitly).

import SwiftUI

// MARK: - EnvironmentKey

private struct AppEnvironmentKey: EnvironmentKey {
    /// A shared preview-safe default. Not used at runtime — the real instance
    /// is always injected from FileFairyApp.
    static let defaultValue = AppEnvironment()
}

// MARK: - EnvironmentValues Extension

extension EnvironmentValues {
    /// Access the app-wide environment container.
    ///
    /// Prefer `@Environment(AppEnvironment.self)` in SwiftUI views because
    /// @Observable types are injectable without a key. This property accessor
    /// is kept as a convenience for UIKit integration points and testing utilities
    /// that work with EnvironmentValues directly.
    var appEnvironment: AppEnvironment {
        get { self[AppEnvironmentKey.self] }
        set { self[AppEnvironmentKey.self] = newValue }
    }
}

// MARK: - View Extension

extension View {
    /// Convenience modifier that injects AppEnvironment into the environment
    /// using both the keyed accessor and the @Observable injection path.
    ///
    /// Usage:
    /// ```swift
    /// SomeView()
    ///     .withAppEnvironment(env)
    /// ```
    func withAppEnvironment(_ environment: AppEnvironment) -> some View {
        self
            .environment(environment)
            .environment(\.appEnvironment, environment)
    }
}
