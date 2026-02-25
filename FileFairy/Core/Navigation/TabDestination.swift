// TabDestination.swift
// FileFairy
//
// All navigation destinations: tabs, sheets, full-screen covers.
// Adding a new navigation target means adding a case here first.

import SwiftUI

// MARK: - Tab Destinations

/// The five primary sections of the app, mapping 1:1 to tab bar items.
enum TabDestination: Int, CaseIterable, Identifiable {
    case home
    case scanner
    case mbox
    case converter
    case fileOpener

    var id: Int { rawValue }

    // MARK: Display

    var title: String {
        switch self {
        case .home:        return "Home"
        case .scanner:     return "Scanner"
        case .mbox:        return "MBOX"
        case .converter:   return "Convert"
        case .fileOpener:  return "Files"
        }
    }

    /// SF Symbol name used in the tab bar.
    var systemImageName: String {
        switch self {
        case .home:        return "house.fill"
        case .scanner:     return "camera.fill"
        case .mbox:        return "envelope.fill"
        case .converter:   return "arrow.triangle.2.circlepath"
        case .fileOpener:  return "folder.fill"
        }
    }

    /// The accent color for the active (selected) state.
    /// Each module owns its unique brand color from the design system.
    var activeColor: Color {
        switch self {
        case .home:        return .Fairy.violet
        case .scanner:     return .Fairy.rose
        case .mbox:        return .Fairy.teal
        case .converter:   return .Fairy.amber
        case .fileOpener:  return .Fairy.green
        }
    }

    /// Light background tint used behind active icon.
    var tintColor: Color {
        switch self {
        case .home:        return .Fairy.dust
        case .scanner:     return .Fairy.blush
        case .mbox:        return .Fairy.iceBlue
        case .converter:   return .Fairy.sunrise
        case .fileOpener:  return Color(.sRGB, red: 0.820, green: 0.980, blue: 0.898)
        }
    }
}

// MARK: - Sheet Destinations

/// Destinations that present as a bottom sheet (.sheet modifier).
enum SheetDestination: Identifiable, Hashable {
    /// Premium upgrade paywall
    case paywall
    /// App-wide settings
    case settings
    /// Export options after scanning
    case scanExport(sessionID: UUID)
    /// Email filter/search configuration
    case emailFilter
    /// File renaming prompt
    case renameFile(currentName: String)
    /// Share sheet (uses UIActivityViewController internally)
    case shareFiles(urls: [URL])
    /// Sort and filter options for a list
    case sortFilter(context: SortFilterContext)
    /// OCR text view for a scanned page
    case ocrText(text: String)
    /// Conversion format picker
    case formatPicker(inputExtension: String)

    var id: String {
        switch self {
        case .paywall:                      return "paywall"
        case .settings:                     return "settings"
        case .scanExport(let id):           return "scanExport-\(id)"
        case .emailFilter:                  return "emailFilter"
        case .renameFile(let name):         return "renameFile-\(name)"
        case .shareFiles(let urls):         return "shareFiles-\(urls.count)"
        case .sortFilter(let ctx):          return "sortFilter-\(ctx.rawValue)"
        case .ocrText:                      return "ocrText"
        case .formatPicker(let ext):        return "formatPicker-\(ext)"
        }
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }

    static func == (lhs: SheetDestination, rhs: SheetDestination) -> Bool {
        lhs.id == rhs.id
    }
}

/// Context for the sort/filter sheet so it knows which list to configure.
enum SortFilterContext: String {
    case scans
    case emails
    case conversions
    case recentFiles
}

// MARK: - Full-Screen Cover Destinations

/// Destinations that present as a full-screen cover (.fullScreenCover modifier).
/// Reserved for immersive experiences where the surrounding UI should be hidden.
enum FullScreenDestination: Identifiable, Hashable {
    /// Live camera scanning session
    case cameraScanner
    /// Onboarding flow for new users
    case onboarding
    /// Full-screen document preview
    case documentPreview(url: URL)
    /// Image viewer with zoom/pan
    case imageViewer(pageID: UUID)

    var id: String {
        switch self {
        case .cameraScanner:                return "cameraScanner"
        case .onboarding:                   return "onboarding"
        case .documentPreview(let url):     return "documentPreview-\(url.lastPathComponent)"
        case .imageViewer(let id):          return "imageViewer-\(id)"
        }
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }

    static func == (lhs: FullScreenDestination, rhs: FullScreenDestination) -> Bool {
        lhs.id == rhs.id
    }
}
