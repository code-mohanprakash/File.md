// Shadows.swift
// FileFairy
//
// From PRD Section 2.4: Tinted shadows, not black.
// Violet-tinted shadows reinforce the brand while creating depth.

import SwiftUI

struct FairyShadow {
    let color: Color
    let radius: CGFloat
    let x: CGFloat
    let y: CGFloat

    /// Cards, floating elements - violet-tinted, soft
    static let soft = FairyShadow(
        color: Color(.sRGB, red: 0.545, green: 0.361, blue: 0.965, opacity: 0.08),
        radius: 8,
        x: 0,
        y: 4
    )

    /// Active/selected states, CTA buttons - colored glow
    static let glow = FairyShadow(
        color: Color(.sRGB, red: 0.545, green: 0.361, blue: 0.965, opacity: 0.15),
        radius: 10,
        x: 0,
        y: 0
    )

    /// Bottom sheets, overlays - larger, softer spread
    static let float = FairyShadow(
        color: Color.black.opacity(0.08),
        radius: 16,
        x: 0,
        y: 8
    )

    /// Module-specific colored glow
    static func moduleGlow(_ color: Color) -> FairyShadow {
        FairyShadow(
            color: color.opacity(0.2),
            radius: 12,
            x: 0,
            y: 4
        )
    }
}

// MARK: - View Modifier

struct FairyShadowModifier: ViewModifier {
    let shadow: FairyShadow

    func body(content: Content) -> some View {
        content
            .shadow(
                color: shadow.color,
                radius: shadow.radius,
                x: shadow.x,
                y: shadow.y
            )
    }
}

extension View {
    func fairyShadow(_ shadow: FairyShadow = .soft) -> some View {
        modifier(FairyShadowModifier(shadow: shadow))
    }
}
