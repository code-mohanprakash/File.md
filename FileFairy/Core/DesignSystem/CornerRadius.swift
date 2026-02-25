// CornerRadius.swift
// FileFairy
//
// From PRD Section 2.4: Rounded corners are the single biggest contributor
// to the "cutesy" feel. Larger radii = softer = more friendly.
// FileFairy uses deliberately generous radii compared to system defaults.

import SwiftUI

enum CornerRadius {
    /// 10pt - Buttons, tags, small badges (system uses 8pt)
    static let sm: CGFloat = 10

    /// 16pt - Cards, list items, input fields (system uses 10pt)
    static let md: CGFloat = 16

    /// 24pt - Large cards, modals, bottom sheets (system uses 14pt)
    static let lg: CGFloat = 24

    /// 32pt - Feature panels, floating action buttons (no system equivalent)
    static let xl: CGFloat = 32

    /// 9999pt - Circular buttons, avatars, module icons
    static let pill: CGFloat = 9999
}

// MARK: - RoundedRectangle Helpers

extension RoundedRectangle {
    static let fairySmall = RoundedRectangle(cornerRadius: CornerRadius.sm, style: .continuous)
    static let fairyMedium = RoundedRectangle(cornerRadius: CornerRadius.md, style: .continuous)
    static let fairyLarge = RoundedRectangle(cornerRadius: CornerRadius.lg, style: .continuous)
    static let fairyXL = RoundedRectangle(cornerRadius: CornerRadius.xl, style: .continuous)
    static let fairyPill = RoundedRectangle(cornerRadius: CornerRadius.pill, style: .continuous)
}
