// Spacing.swift
// FileFairy
//
// 4pt base grid spacing system.
// Generous spacing is key to the "cutesy" feel - the design breathes.

import SwiftUI

enum Spacing {
    /// 2pt - Hairline gaps, icon-to-badge
    static let xxxs: CGFloat = 2

    /// 4pt - Tight inline spacing
    static let xxs: CGFloat = 4

    /// 8pt - Default inline spacing, icon-to-text
    static let xs: CGFloat = 8

    /// 12pt - Between related elements
    static let sm: CGFloat = 12

    /// 16pt - Standard padding, card internal
    static let md: CGFloat = 16

    /// 20pt - Between cards in a list
    static let base: CGFloat = 20

    /// 24pt - Section separators
    static let lg: CGFloat = 24

    /// 32pt - Between major sections
    static let xl: CGFloat = 32

    /// 48pt - Top/bottom screen margins
    static let xxl: CGFloat = 48

    /// 64pt - Hero spacing, onboarding
    static let xxxl: CGFloat = 64
}

// MARK: - Edge Insets Helpers

extension EdgeInsets {
    static let fairyCard = EdgeInsets(
        top: Spacing.md,
        leading: Spacing.md,
        bottom: Spacing.md,
        trailing: Spacing.md
    )

    static let fairyScreen = EdgeInsets(
        top: Spacing.lg,
        leading: Spacing.md,
        bottom: Spacing.lg,
        trailing: Spacing.md
    )

    static let fairySection = EdgeInsets(
        top: Spacing.xs,
        leading: Spacing.md,
        bottom: Spacing.xs,
        trailing: Spacing.md
    )
}
