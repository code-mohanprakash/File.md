// Animation+Fairy.swift
// FileFairy
//
// From PRD Section 5: Every animation serves the cutesy brand.
// Movements are bouncy (spring animations), never linear.
// Nothing snaps - everything eases. The app should feel alive and happy to help.

import SwiftUI

// MARK: - Named Animation Presets

extension Animation {

    /// Card scales to 0.96 on press, springs to 1.0 on release
    /// Press: 100ms, Release: 300ms
    static let fairyBounce = Animation.spring(response: 0.3, dampingFraction: 0.6)

    /// Tab switch, button confirm - snappy with slight overshoot
    static let fairySnappy = Animation.spring(response: 0.3, dampingFraction: 0.75)

    /// Screen transitions - slide up with gentle bounce
    /// 500ms
    static let fairyGentle = Animation.spring(response: 0.5, dampingFraction: 0.8)

    /// File import - drop with soft landing bounce + sparkles
    /// 600ms
    static let fairyMagic = Animation.spring(response: 0.5, dampingFraction: 0.7)

    /// Conversion complete - checkmark draws on, card bounces
    /// 800ms total
    static let fairyCelebrate = Animation.spring(response: 0.6, dampingFraction: 0.55)

    /// Delete - card shrinks and fades, gap closes
    /// 400ms
    static let fairyDismiss = Animation.spring(response: 0.3, dampingFraction: 0.8)

    /// Error shake - horizontal shake with decay
    /// 400ms
    static let fairyShake = Animation.spring(response: 0.5, dampingFraction: 0.3)

    /// Empty state appear - Fae fades in from sparkle
    /// 1200ms total
    static let fairyAppear = Animation.spring(response: 0.8, dampingFraction: 0.7)

    /// Pull-to-refresh wand spin
    static let fairySpin = Animation.linear(duration: 1.0).repeatForever(autoreverses: false)

    /// Staggered list item entrance
    static func fairyStagger(index: Int) -> Animation {
        .spring(response: 0.4, dampingFraction: 0.65)
        .delay(Double(index) * 0.06)
    }
}

// MARK: - Custom Transitions

extension AnyTransition {

    /// Module screen slides up from bottom with bounce
    static var fairySlideUp: AnyTransition {
        .asymmetric(
            insertion: .move(edge: .bottom).combined(with: .opacity),
            removal: .move(edge: .bottom).combined(with: .opacity)
        )
    }

    /// Forward page navigation
    static var fairyPageForward: AnyTransition {
        .asymmetric(
            insertion: .move(edge: .trailing).combined(with: .opacity),
            removal: .move(edge: .leading).combined(with: .opacity)
        )
    }

    /// Scale + fade for cards
    static var fairyScale: AnyTransition {
        .asymmetric(
            insertion: .scale(scale: 0.8).combined(with: .opacity),
            removal: .scale(scale: 0.8).combined(with: .opacity)
        )
    }

    /// Share sheet opens - slide up with backdrop blur
    static var fairySheet: AnyTransition {
        .move(edge: .bottom)
        .combined(with: .opacity)
    }
}

// MARK: - Shake Effect

struct ShakeEffect: GeometryEffect {
    var amount: CGFloat = 8
    var shakesPerUnit: Int = 3
    var animatableData: CGFloat

    func effectValue(size: CGSize) -> ProjectionTransform {
        let translation = amount * sin(animatableData * .pi * CGFloat(shakesPerUnit))
        return ProjectionTransform(CGAffineTransform(translationX: translation, y: 0))
    }
}

// MARK: - Press Scale Modifier

struct PressScaleModifier: ViewModifier {
    @State private var isPressed = false

    let scale: CGFloat
    let animation: Animation

    init(scale: CGFloat = 0.96, animation: Animation = .fairyBounce) {
        self.scale = scale
        self.animation = animation
    }

    func body(content: Content) -> some View {
        content
            .scaleEffect(isPressed ? scale : 1.0)
            .animation(animation, value: isPressed)
            .simultaneousGesture(
                DragGesture(minimumDistance: 0)
                    .onChanged { _ in isPressed = true }
                    .onEnded { _ in isPressed = false }
            )
    }
}

extension View {
    func pressScale(_ scale: CGFloat = 0.96) -> some View {
        modifier(PressScaleModifier(scale: scale))
    }
}
