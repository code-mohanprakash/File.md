// FairyButton.swift
// FileFairy
//
// Reusable button components using FileFairy design tokens.
// All button styles apply .pressScale, brand haptics, and sound on tap.
// Style variants: primary (violet gradient), secondary (cream+border),
// ghost (transparent, violet text), destructive (softRed fill).

import SwiftUI

// MARK: - Button Style Enum

enum FairyButtonStyle {
    case primary
    case secondary
    case ghost
    case destructive
}

// MARK: - Primary Button Style

/// Violet gradient fill, white text, spring scale + haptic on press.
/// Use for the single most important CTA on a screen.
struct PrimaryFairyButtonStyle: ButtonStyle {

    var isLoading: Bool = false
    var customColor: Color? = nil

    private var gradientColors: [Color] {
        if let c = customColor {
            return [c, c.opacity(0.85)]
        }
        return [
            Color(.sRGB, red: 0.545, green: 0.361, blue: 0.965),
            Color(.sRGB, red: 0.659, green: 0.502, blue: 0.992)
        ]
    }

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .fairyText(.button)
            .foregroundStyle(Color.white)
            .frame(maxWidth: .infinity)
            .frame(height: 52)
            .background(
                LinearGradient(
                    colors: gradientColors,
                    startPoint: .leading,
                    endPoint: .trailing
                ),
                in: RoundedRectangle.fairySmall
            )
            .fairyShadow(.glow)
            .scaleEffect(configuration.isPressed ? 0.96 : 1.0)
            .animation(.fairyBounce, value: configuration.isPressed)
            .opacity(isLoading ? 0.75 : 1.0)
            .onChange(of: configuration.isPressed) { _, pressed in
                if pressed {
                    HapticEngine.shared.light()
                    SoundPlayer.shared.play(.tap)
                }
            }
    }
}

// MARK: - Secondary Button Style

/// Cream fill, violet border, violet text.
/// Use for secondary actions alongside a primary CTA.
struct SecondaryFairyButtonStyle: ButtonStyle {

    var isLoading: Bool = false
    var customColor: Color? = nil

    private var accentColor: Color { customColor ?? .Fairy.violet }

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .fairyText(.button)
            .foregroundStyle(accentColor)
            .frame(maxWidth: .infinity)
            .frame(height: 52)
            .background(Color.Fairy.cream, in: RoundedRectangle.fairySmall)
            .overlay(
                RoundedRectangle.fairySmall
                    .strokeBorder(Color.Fairy.violet, lineWidth: 1.5)
            )
            .fairyShadow(.soft)
            .scaleEffect(configuration.isPressed ? 0.96 : 1.0)
            .animation(.fairyBounce, value: configuration.isPressed)
            .opacity(isLoading ? 0.75 : 1.0)
            .onChange(of: configuration.isPressed) { _, pressed in
                if pressed {
                    HapticEngine.shared.light()
                    SoundPlayer.shared.play(.tap)
                }
            }
    }
}

// MARK: - Ghost Button Style

/// Transparent background, violet text, no border.
/// Use for low-emphasis actions (e.g., "Skip", "Maybe Later").
struct GhostFairyButtonStyle: ButtonStyle {

    var isLoading: Bool = false

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .fairyText(.button)
            .foregroundStyle(Color.Fairy.violet)
            .frame(maxWidth: .infinity)
            .frame(height: 52)
            .background(Color.clear)
            .scaleEffect(configuration.isPressed ? 0.96 : 1.0)
            .animation(.fairyBounce, value: configuration.isPressed)
            .opacity(isLoading ? 0.75 : 1.0)
            .onChange(of: configuration.isPressed) { _, pressed in
                if pressed {
                    HapticEngine.shared.soft()
                    SoundPlayer.shared.play(.tap)
                }
            }
    }
}

// MARK: - Destructive Button Style

/// Soft red fill, white text.
/// Use for irreversible actions: delete, remove, clear.
struct DestructiveFairyButtonStyle: ButtonStyle {

    var isLoading: Bool = false

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .fairyText(.button)
            .foregroundStyle(Color.white)
            .frame(maxWidth: .infinity)
            .frame(height: 52)
            .background(Color.Fairy.softRed, in: RoundedRectangle.fairySmall)
            .fairyShadow(FairyShadow.moduleGlow(.Fairy.softRed))
            .scaleEffect(configuration.isPressed ? 0.96 : 1.0)
            .animation(.fairyBounce, value: configuration.isPressed)
            .opacity(isLoading ? 0.75 : 1.0)
            .onChange(of: configuration.isPressed) { _, pressed in
                if pressed {
                    HapticEngine.shared.medium()
                    SoundPlayer.shared.play(.tap)
                }
            }
    }
}

// MARK: - FairyButton Convenience View

/// Drop-in button with title, optional SF Symbol icon, style, and loading state.
///
/// Usage:
/// ```swift
/// FairyButton("Convert File", icon: "arrow.2.circlepath", style: .primary) {
///     viewModel.startConversion()
/// }
/// ```
struct FairyButton: View {

    let title: String
    let icon: String?
    let style: FairyButtonStyle
    let color: Color?
    let isLoading: Bool
    let action: () -> Void

    init(
        _ title: String,
        icon: String? = nil,
        style: FairyButtonStyle = .primary,
        color: Color? = nil,
        isLoading: Bool = false,
        action: @escaping () -> Void
    ) {
        self.title = title
        self.icon = icon
        self.style = style
        self.color = color
        self.isLoading = isLoading
        self.action = action
    }

    var body: some View {
        Button(action: action) {
            buttonLabel
        }
        .buttonStyle(resolvedButtonStyle)
        .disabled(isLoading)
        .accessibilityLabel(isLoading ? "\(title), loading" : title)
        .accessibilityAddTraits(isLoading ? .isStaticText : [])
    }

    // MARK: - Private

    @ViewBuilder
    private var buttonLabel: some View {
        HStack(spacing: Spacing.xs) {
            if isLoading {
                ProgressView()
                    .progressViewStyle(.circular)
                    .tint(labelColor)
                    .scaleEffect(0.85)
            } else {
                if let icon {
                    Image(systemName: icon)
                        .font(.system(size: 16, weight: .semibold, design: .rounded))
                }
                Text(title)
            }
        }
    }

    private var labelColor: Color {
        switch style {
        case .primary, .destructive: return .white
        case .secondary, .ghost:     return .Fairy.violet
        }
    }

    private var resolvedButtonStyle: AnyButtonStyle {
        switch style {
        case .primary:
            return AnyButtonStyle(PrimaryFairyButtonStyle(isLoading: isLoading, customColor: color))
        case .secondary:
            return AnyButtonStyle(SecondaryFairyButtonStyle(isLoading: isLoading, customColor: color))
        case .ghost:
            return AnyButtonStyle(GhostFairyButtonStyle(isLoading: isLoading))
        case .destructive:
            return AnyButtonStyle(DestructiveFairyButtonStyle(isLoading: isLoading))
        }
    }
}

// MARK: - AnyButtonStyle Type Eraser

/// Allows runtime-selected ButtonStyle without opaque type restrictions.
private struct AnyButtonStyle: ButtonStyle {
    private let _makeBody: (Configuration) -> AnyView

    init<S: ButtonStyle>(_ style: S) {
        _makeBody = { configuration in
            AnyView(style.makeBody(configuration: configuration))
        }
    }

    func makeBody(configuration: Configuration) -> some View {
        _makeBody(configuration)
    }
}

// MARK: - Small Icon-Only Variant

/// Compact circular icon button for inline use (e.g., toolbar actions).
struct FairyIconButton: View {

    let systemName: String
    let color: Color
    let size: CGFloat
    let label: String?
    let action: () -> Void

    init(
        systemName: String,
        color: Color = .Fairy.violet,
        size: CGFloat = 44,
        label: String? = nil,
        action: @escaping () -> Void
    ) {
        self.systemName = systemName
        self.color = color
        self.size = size
        self.label = label
        self.action = action
    }

    var body: some View {
        Button(action: {
            HapticEngine.shared.light()
            SoundPlayer.shared.play(.tap)
            action()
        }) {
            Image(systemName: systemName)
                .font(.system(size: size * 0.4, weight: .semibold, design: .rounded))
                .foregroundStyle(color)
                .frame(width: size, height: size)
                .background(color.opacity(0.12), in: Circle())
                .accessibilityHidden(true)
        }
        .pressScale(0.94)
        .buttonStyle(.plain)
        .accessibilityLabel(label ?? systemName.replacingOccurrences(of: ".", with: " "))
    }
}

// MARK: - Preview

#Preview("FairyButton Styles") {
    ScrollView {
        VStack(spacing: Spacing.md) {
            FairyButton("Scan Document", icon: "camera.viewfinder", style: .primary) {}
            FairyButton("Export PDF", icon: "square.and.arrow.up", style: .secondary) {}
            FairyButton("Maybe Later", style: .ghost) {}
            FairyButton("Delete File", icon: "trash", style: .destructive) {}
            FairyButton("Converting...", icon: "arrow.2.circlepath", style: .primary, isLoading: true) {}

            HStack(spacing: Spacing.md) {
                FairyIconButton(systemName: "plus", color: .Fairy.violet) {}
                FairyIconButton(systemName: "star.fill", color: .Fairy.amber) {}
                FairyIconButton(systemName: "trash", color: .Fairy.softRed) {}
            }
        }
        .padding(Spacing.md)
    }
    .background(Color.Fairy.dust)
}
