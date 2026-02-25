// View+FairyModifiers.swift
// FileFairy
//
// Reusable SwiftUI ViewModifiers that compose the design system tokens
// into high-level, named effects. Use these to keep feature views clean
// and ensure visual consistency across the app.

import SwiftUI

// MARK: - Fairy Card

/// Applies the standard FileFairy card treatment:
/// cream background, xl continuous corner radius, and a soft violet shadow.
struct FairyCardModifier: ViewModifier {
    var backgroundColor: Color
    var cornerRadius: CGFloat
    var shadowStyle: FairyShadow

    init(
        backgroundColor: Color = .Fairy.cream,
        cornerRadius: CGFloat = CornerRadius.xl,
        shadowStyle: FairyShadow = .soft
    ) {
        self.backgroundColor = backgroundColor
        self.cornerRadius = cornerRadius
        self.shadowStyle = shadowStyle
    }

    func body(content: Content) -> some View {
        content
            .background(backgroundColor)
            .clipShape(RoundedRectangle(cornerRadius: cornerRadius, style: .continuous))
            .fairyShadow(shadowStyle)
    }
}

extension View {
    /// Standard card container: cream bg, xl radius, soft violet shadow.
    func fairyCard(
        background: Color = .Fairy.cream,
        cornerRadius: CGFloat = CornerRadius.xl,
        shadow: FairyShadow = .soft
    ) -> some View {
        modifier(FairyCardModifier(
            backgroundColor: background,
            cornerRadius: cornerRadius,
            shadowStyle: shadow
        ))
    }
}

// MARK: - Shimmer

/// A left-to-right highlight sweep used as a skeleton loading placeholder.
/// Apply to any view — typically a rounded rectangle placeholder shape.
struct ShimmerModifier: ViewModifier {
    @State private var phase: CGFloat = -1

    let animation: Animation

    init(animation: Animation = .linear(duration: 1.4).repeatForever(autoreverses: false)) {
        self.animation = animation
    }

    func body(content: Content) -> some View {
        content
            .overlay {
                GeometryReader { proxy in
                    let width = proxy.size.width
                    LinearGradient(
                        stops: [
                            .init(color: .clear,                            location: 0),
                            .init(color: .white.opacity(0.55),              location: 0.4),
                            .init(color: .white.opacity(0.55),              location: 0.6),
                            .init(color: .clear,                            location: 1)
                        ],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                    .frame(width: width * 2)
                    .offset(x: phase * width * 2)
                }
                .allowsHitTesting(false)
                .clipped()
            }
            .onAppear {
                withAnimation(animation) {
                    phase = 1
                }
            }
    }
}

extension View {
    /// Animates a shimmering highlight across the view as a loading skeleton effect.
    func shimmer() -> some View {
        modifier(ShimmerModifier())
    }
}

// MARK: - Staggered Appear

/// Fades and slides a list item in with a delay proportional to its index.
/// Wrap list items in `.staggeredAppear(index: i)` for a cascading entrance.
struct StaggeredAppearModifier: ViewModifier {
    let index: Int
    @State private var isVisible: Bool = false

    private var delay: Double { Double(index) * 0.06 }

    func body(content: Content) -> some View {
        content
            .opacity(isVisible ? 1 : 0)
            .offset(y: isVisible ? 0 : 16)
            .animation(
                .spring(response: 0.4, dampingFraction: 0.65)
                .delay(delay),
                value: isVisible
            )
            .onAppear {
                isVisible = true
            }
            .onDisappear {
                // Reset so items re-animate when the list is reconstructed.
                isVisible = false
            }
    }
}

extension View {
    /// Staggered slide-up + fade-in entrance. Pass the item's list index.
    func staggeredAppear(index: Int) -> some View {
        modifier(StaggeredAppearModifier(index: index))
    }
}

// MARK: - Fairy Surface

/// Combines fairyCard with standard card padding for a complete card container.
struct FairySurfaceModifier: ViewModifier {
    var background: Color
    var padding: CGFloat

    func body(content: Content) -> some View {
        content
            .padding(padding)
            .fairyCard(background: background)
    }
}

extension View {
    /// Pads content and wraps it in a FairyCard surface.
    func fairySurface(
        background: Color = .Fairy.cream,
        padding: CGFloat = Spacing.md
    ) -> some View {
        modifier(FairySurfaceModifier(background: background, padding: padding))
    }
}

// MARK: - Conditional Modifier

extension View {
    /// Applies a modifier only when `condition` is true.
    /// Keeps call sites readable without if/else branching.
    @ViewBuilder
    func `if`<T: View>(_ condition: Bool, transform: (Self) -> T) -> some View {
        if condition {
            transform(self)
        } else {
            self
        }
    }
}

// MARK: - Premium Gating (no-op — all features are free)

/// All features are free. This modifier is a no-op that simply returns the content unchanged.
struct PremiumGateModifier: ViewModifier {
    let requiresPremium: Bool

    func body(content: Content) -> some View {
        content
    }
}

extension View {
    /// No-op — all features are available to every user.
    func requiresPremium(_ required: Bool = true) -> some View {
        modifier(PremiumGateModifier(requiresPremium: required))
    }
}
