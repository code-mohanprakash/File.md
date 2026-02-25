// FairyEmptyState.swift
// FileFairy
//
// Branded empty-state component: illustration area, title, subtitle,
// and an optional CTA button. Springs in on appear with staggered timing
// so each element enters sequentially (illustration → title → subtitle → CTA).
//
// Design spec:
//   - Centered VStack
//   - Illustration: tinted SF Symbol in a gradient circle (placeholder for real art)
//   - Title: .headline style, ink color
//   - Subtitle: .subtext style, mist color, multi-line
//   - CTA: optional FairyButton (primary style by default)
//   - Entrance: scale 0.7 → 1.0, opacity 0 → 1, .fairyAppear

import SwiftUI

// MARK: - Empty State Configuration

struct EmptyStateConfig {
    let systemImage: String
    let imageColor: Color
    let title: String
    let subtitle: String
    var ctaTitle: String?
    var ctaIcon: String?
    var ctaStyle: FairyButtonStyle

    init(
        systemImage: String,
        imageColor: Color = .Fairy.violet,
        title: String,
        subtitle: String,
        ctaTitle: String? = nil,
        ctaIcon: String? = nil,
        ctaStyle: FairyButtonStyle = .primary
    ) {
        self.systemImage = systemImage
        self.imageColor = imageColor
        self.title = title
        self.subtitle = subtitle
        self.ctaTitle = ctaTitle
        self.ctaIcon = ctaIcon
        self.ctaStyle = ctaStyle
    }
}

// MARK: - FairyEmptyState

/// Animated empty state view.
///
/// Usage:
/// ```swift
/// FairyEmptyState(
///     config: .init(
///         systemImage: "tray",
///         title: "No Files Yet",
///         subtitle: "Import a file to get started.",
///         ctaTitle: "Import File",
///         ctaIcon: "plus"
///     )
/// ) {
///     viewModel.showImporter()
/// }
/// ```
struct FairyEmptyState: View {

    let config: EmptyStateConfig
    var action: (() -> Void)?

    // Staggered appear state
    @State private var showIllustration = false
    @State private var showTitle = false
    @State private var showSubtitle = false
    @State private var showCTA = false

    // Gentle float offset for the illustration
    @State private var floatOffset: CGFloat = 0

    var body: some View {
        VStack(spacing: 0) {
            Spacer(minLength: Spacing.xl)

            // Illustration
            illustrationView
                .opacity(showIllustration ? 1 : 0)
                .scaleEffect(showIllustration ? 1 : 0.7)
                .offset(y: floatOffset)

            Spacer().frame(height: Spacing.xl)

            // Title
            Text(config.title)
                .fairyText(.headline)
                .foregroundStyle(Color.Fairy.ink)
                .multilineTextAlignment(.center)
                .opacity(showTitle ? 1 : 0)
                .offset(y: showTitle ? 0 : 12)

            Spacer().frame(height: Spacing.xs)

            // Subtitle
            Text(config.subtitle)
                .fairyText(.subtext)
                .foregroundStyle(Color.Fairy.mist)
                .multilineTextAlignment(.center)
                .padding(.horizontal, Spacing.xl)
                .opacity(showSubtitle ? 1 : 0)
                .offset(y: showSubtitle ? 0 : 8)

            Spacer().frame(height: Spacing.xl)

            // CTA
            if let ctaTitle = config.ctaTitle, let action {
                FairyButton(
                    ctaTitle,
                    icon: config.ctaIcon,
                    style: config.ctaStyle,
                    action: action
                )
                .frame(maxWidth: 280)
                .opacity(showCTA ? 1 : 0)
                .scaleEffect(showCTA ? 1 : 0.9)
            }

            Spacer(minLength: Spacing.xl)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .onAppear {
            startEntrance()
            startFloat()
        }
    }

    // MARK: - Subviews

    private var illustrationView: some View {
        ZStack {
            // Outer glow ring
            Circle()
                .fill(config.imageColor.opacity(0.06))
                .frame(width: 140, height: 140)

            // Main circle
            Circle()
                .fill(
                    LinearGradient(
                        colors: [
                            config.imageColor.opacity(0.15),
                            config.imageColor.opacity(0.08)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .frame(width: 112, height: 112)

            // SF Symbol placeholder illustration
            Image(systemName: config.systemImage)
                .font(.system(size: 44, weight: .light, design: .rounded))
                .foregroundStyle(
                    LinearGradient(
                        colors: [config.imageColor, config.imageColor.opacity(0.7)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .symbolRenderingMode(.hierarchical)
        }
    }

    // MARK: - Animations

    private func startEntrance() {
        withAnimation(.fairyAppear) {
            showIllustration = true
        }
        withAnimation(.fairyAppear.delay(0.15)) {
            showTitle = true
        }
        withAnimation(.fairyAppear.delay(0.25)) {
            showSubtitle = true
        }
        withAnimation(.fairyAppear.delay(0.40)) {
            showCTA = true
        }
    }

    private func startFloat() {
        withAnimation(
            .easeInOut(duration: 2.8)
            .repeatForever(autoreverses: true)
        ) {
            floatOffset = -8
        }
    }
}

// MARK: - Preset Configurations

extension EmptyStateConfig {

    static let noFiles = EmptyStateConfig(
        systemImage: "folder.badge.plus",
        imageColor: .Fairy.violet,
        title: "No Files Yet",
        subtitle: "Import a document to get started. FileFairy supports PDF, DOCX, images, and more.",
        ctaTitle: "Import File",
        ctaIcon: "plus"
    )

    static let noScans = EmptyStateConfig(
        systemImage: "camera.viewfinder",
        imageColor: .Fairy.rose,
        title: "No Scans Yet",
        subtitle: "Point your camera at any document to create a high-quality scan.",
        ctaTitle: "Start Scanning",
        ctaIcon: "camera"
    )

    static let noEmails = EmptyStateConfig(
        systemImage: "tray.2",
        imageColor: .Fairy.teal,
        title: "No Emails",
        subtitle: "Import an .mbox file to browse your email archive.",
        ctaTitle: "Import MBOX",
        ctaIcon: "square.and.arrow.down"
    )

    static let searchEmpty = EmptyStateConfig(
        systemImage: "magnifyingglass",
        imageColor: .Fairy.mist,
        title: "Nothing Found",
        subtitle: "Try a different search term or check your spelling.",
        ctaTitle: nil
    )

    static let conversionComplete = EmptyStateConfig(
        systemImage: "checkmark.seal.fill",
        imageColor: .Fairy.mint,
        title: "All Done!",
        subtitle: "Your files have been converted and saved to Files.",
        ctaTitle: "Open Files",
        ctaIcon: "folder"
    )
}

// MARK: - Preview

#Preview("FairyEmptyState") {
    TabView {
        FairyEmptyState(config: .noFiles) {
            print("import")
        }
        .tabItem { Label("Files", systemImage: "folder") }

        FairyEmptyState(config: .searchEmpty)
        .tabItem { Label("Search", systemImage: "magnifyingglass") }

        FairyEmptyState(config: .conversionComplete) {
            print("open files")
        }
        .tabItem { Label("Done", systemImage: "checkmark") }
    }
    .background(Color.Fairy.dust)
}
