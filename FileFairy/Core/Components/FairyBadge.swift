// FairyBadge.swift
// FileFairy
//
// Pill-shaped badge component for labels and counts.
//
// Variants:
//   - FairyBadge: text label in a colored pill (e.g., "PDF", "NEW", "Pro")
//   - FairyCountBadge: compact numeric count (e.g., unread count on tab bar)
//   - FairyStatusBadge: dot + label for status indicators (e.g., "Processing")
//
// Design spec:
//   - Pill shape (CornerRadius.pill)
//   - SF Rounded caption font
//   - Background from color token, foreground auto-selected for contrast
//   - Count badges: round when single digit, pill when 2+ digits, "99+" cap

import SwiftUI

// MARK: - Badge Size

enum FairyBadgeSize {
    case compact
    case regular
    case large

    var fontSize: CGFloat {
        switch self {
        case .compact: return 10
        case .regular: return 12
        case .large:   return 13
        }
    }

    var horizontalPadding: CGFloat {
        switch self {
        case .compact: return 5
        case .regular: return 8
        case .large:   return 10
        }
    }

    var verticalPadding: CGFloat {
        switch self {
        case .compact: return 2
        case .regular: return 3
        case .large:   return 4
        }
    }
}

// MARK: - FairyBadge (Text Label)

/// Pill badge for labeling file types, categories, status, etc.
///
/// Usage:
/// ```swift
/// FairyBadge("PDF")
/// FairyBadge("NEW", color: .Fairy.mint, size: .large)
/// FairyBadge("Pro", color: .Fairy.violet)
/// ```
struct FairyBadge: View {

    let text: String
    let color: Color
    let size: FairyBadgeSize
    var outlined: Bool

    init(
        _ text: String,
        color: Color = .Fairy.violet,
        size: FairyBadgeSize = .regular,
        outlined: Bool = false
    ) {
        self.text = text
        self.color = color
        self.size = size
        self.outlined = outlined
    }

    var body: some View {
        Text(text.uppercased())
            .font(.system(size: size.fontSize, weight: .bold, design: .rounded))
            .foregroundStyle(outlined ? color : Color.white)
            .tracking(0.3)
            .padding(.horizontal, size.horizontalPadding)
            .padding(.vertical, size.verticalPadding)
            .background(
                Capsule()
                    .fill(outlined ? color.opacity(0.0) : color)
                    .overlay(
                        outlined
                            ? AnyView(Capsule().strokeBorder(color, lineWidth: 1.2))
                            : AnyView(EmptyView())
                    )
            )
    }
}

// MARK: - FairyCountBadge (Numeric)

/// Compact count badge for unread counts, file counts, notification bubbles.
/// Automatically uses a circle when the count is a single digit.
///
/// Usage:
/// ```swift
/// FairyCountBadge(count: 3)
/// FairyCountBadge(count: 142, color: .Fairy.softRed)
/// ```
struct FairyCountBadge: View {

    let count: Int
    let color: Color
    var maxCount: Int

    init(count: Int, color: Color = .Fairy.softRed, maxCount: Int = 99) {
        self.count = count
        self.color = color
        self.maxCount = maxCount
    }

    private var displayText: String {
        count > maxCount ? "\(maxCount)+" : "\(count)"
    }

    private var isCircle: Bool {
        count < 10
    }

    var body: some View {
        if count <= 0 {
            EmptyView()
        } else {
            Text(displayText)
                .font(.system(size: 11, weight: .bold, design: .rounded))
                .foregroundStyle(Color.white)
                .monospacedDigit()
                .padding(.horizontal, isCircle ? 0 : 5)
                .frame(minWidth: 18, minHeight: 18)
                .background(color, in: Capsule())
        }
    }
}

// MARK: - FairyStatusBadge (Dot + Label)

/// Status indicator with a colored dot and a text label.
///
/// Usage:
/// ```swift
/// FairyStatusBadge("Converting", color: .Fairy.amber)
/// FairyStatusBadge("Ready", color: .Fairy.mint)
/// FairyStatusBadge("Failed", color: .Fairy.softRed)
/// ```
struct FairyStatusBadge: View {

    let text: String
    let color: Color
    var animated: Bool    // pulses the dot when true (e.g., actively processing)

    @State private var pulsing = false

    init(_ text: String, color: Color = .Fairy.violet, animated: Bool = false) {
        self.text = text
        self.color = color
        self.animated = animated
    }

    var body: some View {
        HStack(spacing: Spacing.xxs + 1) {
            // Status dot
            Circle()
                .fill(color)
                .frame(width: 6, height: 6)
                .scaleEffect(pulsing ? 1.4 : 1.0)
                .opacity(pulsing ? 0.7 : 1.0)
                .animation(
                    animated
                        ? .easeInOut(duration: 0.9).repeatForever(autoreverses: true)
                        : .default,
                    value: pulsing
                )

            Text(text)
                .font(.system(size: 12, weight: .medium, design: .rounded))
                .foregroundStyle(color)
        }
        .padding(.horizontal, Spacing.xs)
        .padding(.vertical, Spacing.xxxs + 1)
        .background(color.opacity(0.10), in: Capsule())
        .onAppear {
            if animated { pulsing = true }
        }
    }
}

// MARK: - FairyModuleTag

/// Small colored tag used to identify module context (Scanner, MBOX, etc.)
struct FairyModuleTag: View {

    let theme: ModuleTheme
    let label: String

    var body: some View {
        Text(label)
            .font(.system(size: 10, weight: .bold, design: .rounded))
            .foregroundStyle(theme.primary)
            .tracking(0.2)
            .padding(.horizontal, 7)
            .padding(.vertical, 3)
            .background(theme.primary.opacity(0.12), in: Capsule())
    }
}

// MARK: - View Extension

extension View {
    /// Overlays a count badge in the top-trailing corner.
    func fairyCountBadge(_ count: Int, color: Color = .Fairy.softRed) -> some View {
        overlay(alignment: .topTrailing) {
            if count > 0 {
                FairyCountBadge(count: count, color: color)
                    .offset(x: 6, y: -6)
                    .transition(.fairyScale)
            }
        }
        .animation(.fairyBounce, value: count)
    }
}

// MARK: - Preview

#Preview("FairyBadge") {
    ScrollView {
        VStack(alignment: .leading, spacing: Spacing.lg) {

            // Text badges
            VStack(alignment: .leading, spacing: Spacing.sm) {
                Text("Label Badges").fairyText(.caption)

                HStack(spacing: Spacing.xs) {
                    FairyBadge("PDF")
                    FairyBadge("DOCX", color: .Fairy.teal)
                    FairyBadge("NEW", color: .Fairy.mint)
                    FairyBadge("PRO", color: .Fairy.amber)
                    FairyBadge("BETA", color: .Fairy.rose, outlined: true)
                }

                HStack(spacing: Spacing.xs) {
                    FairyBadge("Small", size: .compact)
                    FairyBadge("Regular")
                    FairyBadge("Large", size: .large)
                }
            }

            // Count badges
            VStack(alignment: .leading, spacing: Spacing.sm) {
                Text("Count Badges").fairyText(.caption)

                HStack(spacing: Spacing.md) {
                    FairyCountBadge(count: 1)
                    FairyCountBadge(count: 9)
                    FairyCountBadge(count: 12)
                    FairyCountBadge(count: 99)
                    FairyCountBadge(count: 142)
                    FairyCountBadge(count: 3, color: .Fairy.violet)
                    FairyCountBadge(count: 0)
                }
            }

            // Status badges
            VStack(alignment: .leading, spacing: Spacing.sm) {
                Text("Status Badges").fairyText(.caption)

                HStack(spacing: Spacing.xs) {
                    FairyStatusBadge("Ready", color: .Fairy.mint)
                    FairyStatusBadge("Converting", color: .Fairy.amber, animated: true)
                    FairyStatusBadge("Failed", color: .Fairy.softRed)
                    FairyStatusBadge("Queued", color: .Fairy.mist)
                }
            }

            // Module tags
            VStack(alignment: .leading, spacing: Spacing.sm) {
                Text("Module Tags").fairyText(.caption)

                HStack(spacing: Spacing.xs) {
                    FairyModuleTag(theme: .scanner, label: "Scanner")
                    FairyModuleTag(theme: .mbox, label: "MBOX")
                    FairyModuleTag(theme: .converter, label: "Converter")
                    FairyModuleTag(theme: .pdf, label: "PDF")
                }
            }

            // Badge overlay example
            VStack(alignment: .leading, spacing: Spacing.sm) {
                Text("Badge Overlay").fairyText(.caption)

                HStack(spacing: Spacing.xl) {
                    Image(systemName: "tray.2.fill")
                        .font(.system(size: 32))
                        .foregroundStyle(Color.Fairy.teal)
                        .fairyCountBadge(5)

                    Image(systemName: "folder.fill")
                        .font(.system(size: 32))
                        .foregroundStyle(Color.Fairy.violet)
                        .fairyCountBadge(142)
                }
                .padding()
            }
        }
        .padding(Spacing.md)
    }
    .background(Color.Fairy.dust)
}
