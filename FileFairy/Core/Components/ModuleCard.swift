// ModuleCard.swift
// FileFairy
//
// Large tappable home-screen module cards.
//
// PRD dimensions:
//   - Scanner card: 120pt height (primary feature, full width)
//   - MBOX card:    100pt height (secondary feature, full width)
//   - Grid cards:   square (2-column grid, equal width)
//
// Each card uses the module's gradient background, a DuotoneIcon (gradient fill
// variant) on the left, title + subtitle stacked on the right.
// Spring scale on press (.pressScale). Haptic + sound on tap.
//
// ModuleCard is the detailed, opinionated card.
// For generic gradient cards see FairyCard.swift (ModuleFeatureCard / CompactModuleCard).

import SwiftUI

// MARK: - Module Card Layout

enum ModuleCardLayout {
    /// Full-width hero card — Scanner (120pt)
    case hero(height: CGFloat = 120)

    /// Full-width secondary card — MBOX (100pt)
    case secondary(height: CGFloat = 100)

    /// Square card for 2-column grid
    case grid

    var isFullWidth: Bool {
        switch self {
        case .hero, .secondary: return true
        case .grid:             return false
        }
    }
}

// MARK: - ModuleCard

/// Tappable module card for the home screen.
///
/// Usage:
/// ```swift
/// ModuleCard(
///     module: .scanner,
///     icon: "camera.viewfinder",
///     title: "Scanner",
///     subtitle: "Scan documents instantly",
///     layout: .hero(),
///     badge: 0
/// ) {
///     router.navigate(to: .scanner)
/// }
/// ```
struct ModuleCard: View {

    // MARK: Public

    let module: ModuleTheme
    let icon: String
    let title: String
    let subtitle: String
    let layout: ModuleCardLayout
    var badge: Int
    let action: () -> Void

    // MARK: Private

    @State private var isPressed = false

    // MARK: Init

    init(
        module: ModuleTheme,
        icon: String,
        title: String,
        subtitle: String = "",
        layout: ModuleCardLayout = .hero(),
        badge: Int = 0,
        action: @escaping () -> Void
    ) {
        self.module = module
        self.icon = icon
        self.title = title
        self.subtitle = subtitle
        self.layout = layout
        self.badge = badge
        self.action = action
    }

    // MARK: Body

    var body: some View {
        Button(action: handleTap) {
            switch layout {
            case .hero(let height):
                heroCardBody(height: height)
            case .secondary(let height):
                secondaryCardBody(height: height)
            case .grid:
                gridCardBody
            }
        }
        .buttonStyle(.plain)
        .simultaneousGesture(
            DragGesture(minimumDistance: 0)
                .onChanged { _ in isPressed = true }
                .onEnded   { _ in isPressed = false }
        )
        .scaleEffect(isPressed ? 0.96 : 1.0)
        .animation(.fairyBounce, value: isPressed)
    }

    // MARK: - Layout Variants

    private func heroCardBody(height: CGFloat) -> some View {
        ZStack {
            gradientBackground
            glossOverlay

            HStack(spacing: Spacing.md) {
                // Large icon on left
                moduleIconView(size: 64)

                // Text block
                VStack(alignment: .leading, spacing: Spacing.xxs) {
                    Text(title)
                        .font(.Fairy.title)
                        .foregroundStyle(Color.white)
                        .tracking(-0.3)

                    Text(subtitle)
                        .font(.Fairy.subtext)
                        .foregroundStyle(Color.white.opacity(0.85))
                        .lineLimit(2)
                }

                Spacer(minLength: 0)

                disclosureChevron
            }
            .padding(.horizontal, Spacing.md)
            .padding(.vertical, Spacing.sm)

            // Badge overlay
            if badge > 0 {
                badgeView
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topTrailing)
                    .padding(Spacing.sm)
            }
        }
        .frame(height: height)
        .clipShape(RoundedRectangle(cornerRadius: CornerRadius.xl, style: .continuous))
        .fairyShadow(FairyShadow.moduleGlow(module.primary))
    }

    private func secondaryCardBody(height: CGFloat) -> some View {
        ZStack {
            gradientBackground
            glossOverlay

            HStack(spacing: Spacing.sm) {
                // Medium icon
                moduleIconView(size: 52)

                VStack(alignment: .leading, spacing: Spacing.xxxs) {
                    Text(title)
                        .font(.Fairy.headline)
                        .foregroundStyle(Color.white)
                        .tracking(-0.2)

                    Text(subtitle)
                        .font(.Fairy.caption)
                        .foregroundStyle(Color.white.opacity(0.8))
                        .lineLimit(2)
                }

                Spacer(minLength: 0)

                disclosureChevron
            }
            .padding(.horizontal, Spacing.md)

            if badge > 0 {
                badgeView
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topTrailing)
                    .padding(Spacing.xs)
            }
        }
        .frame(height: height)
        .clipShape(RoundedRectangle(cornerRadius: CornerRadius.xl, style: .continuous))
        .fairyShadow(FairyShadow.moduleGlow(module.primary))
    }

    private var gridCardBody: some View {
        GeometryReader { geo in
            ZStack {
                gradientBackground

                // Decorative background circle (bottom-right)
                Circle()
                    .fill(Color.white.opacity(0.08))
                    .frame(width: geo.size.width * 0.75)
                    .offset(x: geo.size.width * 0.3, y: geo.size.height * 0.25)

                glossOverlay

                VStack(spacing: Spacing.xs) {
                    Spacer()

                    // Icon
                    moduleIconView(size: 52)

                    // Title
                    Text(title)
                        .font(.Fairy.caption)
                        .fontWeight(.bold)
                        .foregroundStyle(Color.white)
                        .multilineTextAlignment(.center)
                        .lineLimit(2)
                        .padding(.horizontal, Spacing.xs)

                    Spacer()
                }
                .frame(maxWidth: .infinity)

                if badge > 0 {
                    badgeView
                        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topTrailing)
                        .padding(Spacing.xs)
                }
            }
        }
        .aspectRatio(1, contentMode: .fit)
        .clipShape(RoundedRectangle(cornerRadius: CornerRadius.xl, style: .continuous))
        .fairyShadow(FairyShadow.moduleGlow(module.primary))
    }

    // MARK: - Shared Subviews

    private var gradientBackground: some View {
        module.gradient
            .ignoresSafeArea()
    }

    private var glossOverlay: some View {
        LinearGradient(
            colors: [Color.white.opacity(0.2), Color.white.opacity(0.0)],
            startPoint: .top,
            endPoint: .center
        )
    }

    private func moduleIconView(size: CGFloat) -> some View {
        ZStack {
            Circle()
                .fill(Color.white.opacity(0.22))
                .frame(width: size, height: size)

            Image(systemName: icon)
                .font(.system(size: size * 0.42, weight: .semibold, design: .rounded))
                .foregroundStyle(Color.white)
                .symbolRenderingMode(.hierarchical)
        }
    }

    private var disclosureChevron: some View {
        Image(systemName: "chevron.right")
            .font(.system(size: 13, weight: .semibold, design: .rounded))
            .foregroundStyle(Color.white.opacity(0.65))
    }

    private var badgeView: some View {
        FairyCountBadge(count: badge)
    }

    // MARK: - Action

    private func handleTap() {
        HapticEngine.shared.medium()
        SoundPlayer.shared.play(.tap)
        action()
    }
}

// MARK: - Home Screen Module Grid

/// Convenience layout that renders all five module cards in the standard
/// home screen arrangement (Scanner hero → MBOX secondary → 3 grid cards).
struct HomeModuleGrid: View {

    var onScanner: () -> Void
    var onMbox: () -> Void
    var onConverter: () -> Void
    var onPDF: () -> Void
    var onFileOpener: () -> Void

    var scannerBadge: Int
    var mboxBadge: Int
    var converterBadge: Int

    init(
        scannerBadge: Int = 0,
        mboxBadge: Int = 0,
        converterBadge: Int = 0,
        onScanner: @escaping () -> Void = {},
        onMbox: @escaping () -> Void = {},
        onConverter: @escaping () -> Void = {},
        onPDF: @escaping () -> Void = {},
        onFileOpener: @escaping () -> Void = {}
    ) {
        self.scannerBadge = scannerBadge
        self.mboxBadge = mboxBadge
        self.converterBadge = converterBadge
        self.onScanner = onScanner
        self.onMbox = onMbox
        self.onConverter = onConverter
        self.onPDF = onPDF
        self.onFileOpener = onFileOpener
    }

    var body: some View {
        VStack(spacing: Spacing.sm) {
            // Scanner — Hero (120pt)
            ModuleCard(
                module: .scanner,
                icon: "camera.viewfinder",
                title: "Scanner",
                subtitle: "Scan any document with your camera",
                layout: .hero(height: 120),
                badge: scannerBadge,
                action: onScanner
            )

            // MBOX — Secondary (100pt)
            ModuleCard(
                module: .mbox,
                icon: "tray.2.fill",
                title: "MBOX",
                subtitle: "Browse email archives",
                layout: .secondary(height: 100),
                badge: mboxBadge,
                action: onMbox
            )

            // Grid row: Converter, PDF, File Opener
            HStack(spacing: Spacing.sm) {
                ModuleCard(
                    module: .converter,
                    icon: "arrow.2.circlepath",
                    title: "Converter",
                    layout: .grid,
                    badge: converterBadge,
                    action: onConverter
                )

                ModuleCard(
                    module: .pdf,
                    icon: "doc.richtext",
                    title: "PDF Tools",
                    layout: .grid,
                    action: onPDF
                )

                ModuleCard(
                    module: .fileOpener,
                    icon: "folder.fill",
                    title: "Files",
                    layout: .grid,
                    action: onFileOpener
                )
            }
        }
    }
}

// MARK: - Preview

#Preview("ModuleCard") {
    ScrollView {
        VStack(spacing: Spacing.xl) {

            // Individual variants
            ModuleCard(
                module: .scanner,
                icon: "camera.viewfinder",
                title: "Scanner",
                subtitle: "Scan any document with your camera",
                layout: .hero(height: 120),
                badge: 2,
                action: {}
            )

            ModuleCard(
                module: .mbox,
                icon: "tray.2.fill",
                title: "MBOX",
                subtitle: "Browse and search email archives",
                layout: .secondary(height: 100),
                badge: 14,
                action: {}
            )

            // Grid row
            HStack(spacing: Spacing.sm) {
                ModuleCard(
                    module: .converter,
                    icon: "arrow.2.circlepath",
                    title: "Converter",
                    layout: .grid,
                    badge: 0,
                    action: {}
                )

                ModuleCard(
                    module: .pdf,
                    icon: "doc.richtext",
                    title: "PDF Tools",
                    layout: .grid,
                    action: {}
                )

                ModuleCard(
                    module: .fileOpener,
                    icon: "folder.fill",
                    title: "Files",
                    layout: .grid,
                    action: {}
                )
            }

            // Full home grid
            Text("Full Home Grid").fairyText(.caption)
            HomeModuleGrid(
                scannerBadge: 1,
                mboxBadge: 99,
                converterBadge: 4
            )
        }
        .padding(Spacing.md)
    }
    .background(Color.Fairy.dust)
}
