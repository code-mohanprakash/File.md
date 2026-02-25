// Typography.swift
// FileFairy
//
// SF Rounded type scale from PRD Section 2.3
// Primary font: SF Rounded. The rounded terminals are essential to the cutesy vibe.
// Numbers use tabular figures for alignment in file sizes and counts.

import SwiftUI

// MARK: - Type Scale

extension Font {

    /// FileFairy typography scale using SF Rounded
    enum Fairy {

        /// Hero screens: "All done!", feature titles, onboarding
        /// Black (900), 34pt, -0.4pt tracking
        static let display: Font = .system(size: 34, weight: .black, design: .rounded)

        /// Screen headers: "My Scans", "Inbox", module names
        /// Bold (700), 24pt, -0.3pt tracking
        static let title: Font = .system(size: 24, weight: .bold, design: .rounded)

        /// Section headers, card titles, file names
        /// Semibold (600), 20pt, -0.2pt tracking
        static let headline: Font = .system(size: 20, weight: .semibold, design: .rounded)

        /// Descriptions, settings text, email body preview
        /// Medium (500), 17pt
        static let body: Font = .system(size: 17, weight: .medium, design: .rounded)

        /// Metadata, file sizes, dates, sender names
        /// Regular (400), 15pt
        static let subtext: Font = .system(size: 15, weight: .regular, design: .rounded)

        /// Timestamps, badge labels, tiny indicators
        /// Regular (400), 13pt, +0.2pt tracking
        static let caption: Font = .system(size: 13, weight: .regular, design: .rounded)

        /// File sizes, page counts, email counts, progress %
        /// Bold (700), 20pt, tabular
        static let number: Font = .system(size: 20, weight: .bold, design: .rounded)

        /// Button labels
        /// Semibold (600), 17pt
        static let button: Font = .system(size: 17, weight: .semibold, design: .rounded)

        /// Small button labels, tab bar labels
        /// Medium (500), 11pt
        static let micro: Font = .system(size: 11, weight: .medium, design: .rounded)
    }
}

// MARK: - Dynamic Type Safe Variants

extension Font.Fairy {

    /// Dynamic Type safe versions that scale with user accessibility settings
    enum Scaled {
        static let display: Font   = .system(.largeTitle, design: .rounded, weight: .black)
        static let title: Font     = .system(.title, design: .rounded, weight: .bold)
        static let headline: Font  = .system(.title3, design: .rounded, weight: .semibold)
        static let body: Font      = .system(.body, design: .rounded, weight: .medium)
        static let subtext: Font   = .system(.subheadline, design: .rounded, weight: .regular)
        static let caption: Font   = .system(.caption, design: .rounded, weight: .regular)
        static let button: Font    = .system(.body, design: .rounded, weight: .semibold)
    }
}

// MARK: - Text Style Modifier

struct FairyTextStyle: ViewModifier {
    enum Style {
        case display, title, headline, body, subtext, caption, number, button

        var font: Font {
            switch self {
            case .display:  return .Fairy.display
            case .title:    return .Fairy.title
            case .headline: return .Fairy.headline
            case .body:     return .Fairy.body
            case .subtext:  return .Fairy.subtext
            case .caption:  return .Fairy.caption
            case .number:   return .Fairy.number
            case .button:   return .Fairy.button
            }
        }

        var tracking: CGFloat {
            switch self {
            case .display:  return -0.4
            case .title:    return -0.3
            case .headline: return -0.2
            case .caption:  return 0.2
            default:        return 0
            }
        }

        var color: Color {
            switch self {
            case .display, .title, .headline, .number:
                return .Fairy.ink
            case .body, .button:
                return .Fairy.slate
            case .subtext:
                return .Fairy.slate
            case .caption:
                return .Fairy.mist
            }
        }
    }

    let style: Style

    func body(content: Content) -> some View {
        content
            .font(style.font)
            .tracking(style.tracking)
            .foregroundStyle(style.color)
    }
}

extension View {
    func fairyText(_ style: FairyTextStyle.Style) -> some View {
        modifier(FairyTextStyle(style: style))
    }
}
