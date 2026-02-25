// FairyCard.swift
// FileFairy
//
// Card surface components: base modifier, generic wrapper, and the
// ModuleFeatureCard used on the home screen to showcase each module.
//
// Design spec:
//   - Cream background (#FEFCE8)
//   - XL corner radius (32pt continuous)
//   - Violet-tinted soft shadow
//   - ModuleFeatureCard: gradient header, icon badge, title + subtitle

import SwiftUI

// MARK: - FairyCard View Wrapper

/// Generic content card that composes the FairyCardModifier with
/// standard internal padding. Use when you want a full cream card container.
///
/// Usage:
/// ```swift
/// FairyCard {
///     VStack { ... }
/// }
/// ```
struct FairyCard<Content: View>: View {

    var padding: EdgeInsets
    var cornerRadius: CGFloat
    var shadow: FairyShadow
    @ViewBuilder var content: () -> Content

    init(
        padding: EdgeInsets = .fairyCard,
        cornerRadius: CGFloat = CornerRadius.xl,
        shadow: FairyShadow = .soft,
        @ViewBuilder content: @escaping () -> Content
    ) {
        self.padding = padding
        self.cornerRadius = cornerRadius
        self.shadow = shadow
        self.content = content
    }

    var body: some View {
        content()
            .padding(padding)
            .fairyCard(background: Color.Fairy.cream, cornerRadius: cornerRadius, shadow: shadow)
    }
}

// MARK: - ModuleFeatureCard

/// Home-screen feature card used to surface each module.
/// Full-bleed gradient background, circular icon badge on the left,
/// title + subtitle stacked on the right, and a subtle gloss overlay.
///
/// Usage:
/// ```swift
/// ModuleFeatureCard(
///     theme: .scanner,
///     icon: "camera.viewfinder",
///     title: "Scanner",
///     subtitle: "Scan any document in seconds",
///     height: 120
/// ) {
///     navigateToScanner()
/// }
/// ```
struct ModuleFeatureCard: View {

    let theme: ModuleTheme
    let icon: String
    let title: String
    let subtitle: String
    var height: CGFloat
    let action: () -> Void

    @State private var isPressed = false

    init(
        theme: ModuleTheme,
        icon: String,
        title: String,
        subtitle: String,
        height: CGFloat = 110,
        action: @escaping () -> Void
    ) {
        self.theme = theme
        self.icon = icon
        self.title = title
        self.subtitle = subtitle
        self.height = height
        self.action = action
    }

    var body: some View {
        Button(action: {
            HapticEngine.shared.medium()
            SoundPlayer.shared.play(.tap)
            action()
        }) {
            ZStack {
                // Gradient background
                theme.gradient

                // Gloss highlight overlay (top half)
                LinearGradient(
                    colors: [
                        Color.white.opacity(0.18),
                        Color.white.opacity(0.0)
                    ],
                    startPoint: .top,
                    endPoint: .center
                )

                HStack(spacing: Spacing.md) {
                    // Icon badge
                    ZStack {
                        Circle()
                            .fill(Color.white.opacity(0.25))
                            .frame(width: 56, height: 56)

                        Image(systemName: icon)
                            .font(.system(size: 24, weight: .semibold, design: .rounded))
                            .foregroundStyle(Color.white)
                    }

                    // Text stack
                    VStack(alignment: .leading, spacing: Spacing.xxxs) {
                        Text(title)
                            .font(.Fairy.headline)
                            .foregroundStyle(Color.white)
                            .tracking(-0.2)

                        Text(subtitle)
                            .font(.Fairy.subtext)
                            .foregroundStyle(Color.white.opacity(0.85))
                            .lineLimit(2)
                    }

                    Spacer(minLength: 0)

                    // Disclosure chevron
                    Image(systemName: "chevron.right")
                        .font(.system(size: 14, weight: .semibold, design: .rounded))
                        .foregroundStyle(Color.white.opacity(0.7))
                        .padding(.trailing, Spacing.xxs)
                }
                .padding(.horizontal, Spacing.md)
                .padding(.vertical, Spacing.sm)
            }
            .frame(height: height)
            .clipShape(RoundedRectangle(cornerRadius: CornerRadius.xl, style: .continuous))
            .fairyShadow(FairyShadow.moduleGlow(theme.primary))
            .scaleEffect(isPressed ? 0.96 : 1.0)
            .animation(.fairyBounce, value: isPressed)
        }
        .buttonStyle(.plain)
        .simultaneousGesture(
            DragGesture(minimumDistance: 0)
                .onChanged { _ in isPressed = true }
                .onEnded   { _ in isPressed = false }
        )
        .accessibilityLabel("\(title). \(subtitle)")
        .accessibilityHint("Opens \(title)")
        .accessibilityAddTraits(.isButton)
    }
}

// MARK: - CompactModuleCard

/// Smaller square card for secondary modules displayed in a 2-column grid.
/// Gradient background matches the module theme.
struct CompactModuleCard: View {

    let theme: ModuleTheme
    let icon: String
    let title: String
    var badgeCount: Int?
    let action: () -> Void

    @State private var isPressed = false

    var body: some View {
        Button(action: {
            HapticEngine.shared.light()
            SoundPlayer.shared.play(.tap)
            action()
        }) {
            ZStack(alignment: .topTrailing) {
                VStack(spacing: Spacing.sm) {
                    ZStack {
                        Circle()
                            .fill(Color.white.opacity(0.25))
                            .frame(width: 52, height: 52)

                        Image(systemName: icon)
                            .font(.system(size: 22, weight: .semibold, design: .rounded))
                            .foregroundStyle(Color.white)
                    }

                    Text(title)
                        .font(.Fairy.caption)
                        .fontWeight(.semibold)
                        .foregroundStyle(Color.white)
                        .multilineTextAlignment(.center)
                        .lineLimit(2)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .padding(Spacing.md)
                .background(theme.gradient)
                .clipShape(RoundedRectangle(cornerRadius: CornerRadius.xl, style: .continuous))
                .fairyShadow(FairyShadow.moduleGlow(theme.primary))

                // Optional badge
                if let count = badgeCount, count > 0 {
                    Text(count > 99 ? "99+" : "\(count)")
                        .font(.Fairy.micro)
                        .foregroundStyle(.white)
                        .padding(.horizontal, Spacing.xxs)
                        .padding(.vertical, 2)
                        .background(Color.Fairy.softRed, in: Capsule())
                        .offset(x: -Spacing.xs, y: Spacing.xs)
                }
            }
            .scaleEffect(isPressed ? 0.96 : 1.0)
            .animation(.fairyBounce, value: isPressed)
        }
        .buttonStyle(.plain)
        .simultaneousGesture(
            DragGesture(minimumDistance: 0)
                .onChanged { _ in isPressed = true }
                .onEnded   { _ in isPressed = false }
        )
        .accessibilityLabel(title)
        .accessibilityHint("Opens \(title)")
        .accessibilityAddTraits(.isButton)
    }
}

// MARK: - Preview

#Preview("Cards") {
    ScrollView {
        VStack(spacing: Spacing.lg) {

            // Generic FairyCard
            FairyCard {
                VStack(alignment: .leading, spacing: Spacing.xs) {
                    Text("My Documents")
                        .fairyText(.headline)
                    Text("12 files · 24 MB")
                        .fairyText(.subtext)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }

            // Module feature cards
            ModuleFeatureCard(
                theme: .scanner,
                icon: "camera.viewfinder",
                title: "Scanner",
                subtitle: "Scan any document in seconds",
                height: 120,
                action: {}
            )

            ModuleFeatureCard(
                theme: .mbox,
                icon: "tray.2.fill",
                title: "MBOX",
                subtitle: "Browse your email archives",
                height: 100,
                action: {}
            )

            // Compact grid cards
            HStack(spacing: Spacing.md) {
                CompactModuleCard(
                    theme: .converter,
                    icon: "arrow.2.circlepath",
                    title: "Converter",
                    badgeCount: 3,
                    action: {}
                )
                CompactModuleCard(
                    theme: .pdf,
                    icon: "doc.richtext",
                    title: "PDF Tools",
                    action: {}
                )
                CompactModuleCard(
                    theme: .fileOpener,
                    icon: "folder.fill",
                    title: "Files",
                    action: {}
                )
            }
        }
        .padding(Spacing.md)
    }
    .background(Color.Fairy.dust)
}
