// AppRouter.swift
// FileFairy
//
// Single source of truth for all navigation state.
// @Observable enables SwiftUI views to react to routing changes without
// wrapping in ObservableObject boilerplate.

import SwiftUI
import Observation

// MARK: - AppRouter

/// Manages all navigation state for the app.
/// Inject via @Environment(\.appEnvironment) and access router property.
@Observable
final class AppRouter {

    // MARK: - Tab Selection

    var selectedTab: TabDestination = .home

    // MARK: - Per-Tab Navigation Paths

    /// Independent NavigationPath per tab keeps each tab's stack intact
    /// when the user switches away and back.
    var homePath: NavigationPath = NavigationPath()
    var scannerPath: NavigationPath = NavigationPath()
    var mboxPath: NavigationPath = NavigationPath()
    var converterPath: NavigationPath = NavigationPath()
    var fileOpenerPath: NavigationPath = NavigationPath()

    // MARK: - Modal Presentation

    var presentedSheet: SheetDestination? = nil
    var presentedFullScreen: FullScreenDestination? = nil

    // MARK: - Tab Navigation

    /// Switch to a tab. If already on that tab, pops the stack to root
    /// (matches iOS convention of double-tapping a tab bar item).
    func switchTab(_ destination: TabDestination) {
        if selectedTab == destination {
            popToRoot(tab: destination)
        } else {
            selectedTab = destination
        }
    }

    // MARK: - Sheet Presentation

    func presentSheet(_ destination: SheetDestination) {
        presentedSheet = destination
    }

    func dismissSheet() {
        presentedSheet = nil
    }

    func presentFullScreen(_ destination: FullScreenDestination) {
        presentedFullScreen = destination
    }

    func dismissFullScreen() {
        presentedFullScreen = nil
    }

    // MARK: - Stack Management

    /// Pops the navigation stack for a given tab back to its root.
    func popToRoot(tab: TabDestination) {
        switch tab {
        case .home:        homePath = NavigationPath()
        case .scanner:     scannerPath = NavigationPath()
        case .mbox:        mboxPath = NavigationPath()
        case .converter:   converterPath = NavigationPath()
        case .fileOpener:  fileOpenerPath = NavigationPath()
        }
    }

    /// Pops all tabs to root. Useful on logout or full state reset.
    func popAllToRoot() {
        TabDestination.allCases.forEach { popToRoot(tab: $0) }
    }

    // MARK: - Convenience Push Helpers

    /// Push a destination onto the currently active tab's stack.
    func push<D: Hashable>(_ destination: D) {
        switch selectedTab {
        case .home:        homePath.append(destination)
        case .scanner:     scannerPath.append(destination)
        case .mbox:        mboxPath.append(destination)
        case .converter:   converterPath.append(destination)
        case .fileOpener:  fileOpenerPath.append(destination)
        }
    }

    /// Push a destination onto a specific tab's stack.
    func push<D: Hashable>(_ destination: D, tab: TabDestination) {
        switch tab {
        case .home:        homePath.append(destination)
        case .scanner:     scannerPath.append(destination)
        case .mbox:        mboxPath.append(destination)
        case .converter:   converterPath.append(destination)
        case .fileOpener:  fileOpenerPath.append(destination)
        }
    }
}
