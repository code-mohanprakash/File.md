// FairyLoadingOverlay.swift
// FileFairy
//
// Full-screen .ultraThinMaterial loading overlay with a custom animated spinner.
// The spinner is a central sparkle icon with three orbiting dots that rotate
// around it at different speeds and phases.
//
// Exposed as a ViewModifier: .fairyLoading(isLoading:label:)
//
// Design spec:
//   - Background: .ultraThinMaterial (frosted glass)
//   - Spinner: wand.and.stars.inverse center + 3 orbiting dot circles
//   - Label: optional, .caption style, mist color
//   - Enter: fade + scale in (.fairyMagic)
//   - Exit: fade out (.fairyDismiss)

import SwiftUI

// MARK: - Fairy Spinner

private struct FairySpinner: View {

    let color: Color

    @State private var rotation: Double = 0
    @State private var orbitA: Double = 0
    @State private var orbitB: Double = 120
    @State private var orbitC: Double = 240
    @State private var pulse: Bool = false

    private let orbitRadius: CGFloat = 26
    private let dotSize: CGFloat = 7

    var body: some View {
        ZStack {
            // Orbit path guide (subtle)
            Circle()
                .stroke(color.opacity(0.08), lineWidth: 1)
                .frame(width: orbitRadius * 2, height: orbitRadius * 2)

            // Orbiting dots
            orbitDot(angle: orbitA, opacity: 1.0)
            orbitDot(angle: orbitB, opacity: 0.65)
            orbitDot(angle: orbitC, opacity: 0.35)

            // Central sparkle icon
            Image(systemName: "wand.and.stars.inverse")
                .font(.system(size: 22, weight: .medium, design: .rounded))
                .foregroundStyle(
                    LinearGradient(
                        colors: [color, color.opacity(0.7)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .symbolRenderingMode(.hierarchical)
                .rotationEffect(.degrees(rotation))
                .scaleEffect(pulse ? 1.08 : 1.0)
        }
        .frame(width: orbitRadius * 2 + dotSize, height: orbitRadius * 2 + dotSize)
        .onAppear {
            startAnimations()
        }
    }

    private func orbitDot(angle: Double, opacity: Double) -> some View {
        let radians = angle * .pi / 180
        let x = orbitRadius * cos(radians)
        let y = orbitRadius * sin(radians)

        return Circle()
            .fill(color.opacity(opacity))
            .frame(width: dotSize, height: dotSize)
            .offset(x: x, y: y)
    }

    private func startAnimations() {
        // Rotate the central wand
        withAnimation(.linear(duration: 3.0).repeatForever(autoreverses: false)) {
            rotation = 360
        }

        // Orbit dots — drive via a continuous timer using TimelineView would be
        // cleaner, but using individual angle animations keeps it self-contained.
        let orbitDuration: Double = 1.8
        withAnimation(.linear(duration: orbitDuration).repeatForever(autoreverses: false)) {
            orbitA = 360
        }

        // Pulse the center icon on each orbit completion
        withAnimation(
            .easeInOut(duration: orbitDuration / 2)
            .repeatForever(autoreverses: true)
        ) {
            pulse = true
        }
    }
}

// MARK: - FairyLoadingOverlay View

struct FairyLoadingOverlay: View {

    let label: String?
    let color: Color

    init(label: String? = nil, color: Color = .Fairy.violet) {
        self.label = label
        self.color = color
    }

    var body: some View {
        ZStack {
            // Frosted glass backdrop
            Rectangle()
                .fill(.ultraThinMaterial)
                .ignoresSafeArea()

            // Spinner card
            VStack(spacing: Spacing.md) {
                FairySpinner(color: color)

                if let label {
                    Text(label)
                        .fairyText(.caption)
                        .foregroundStyle(Color.Fairy.mist)
                        .transition(.fairyScale)
                }
            }
            .padding(Spacing.xl)
            .background(
                RoundedRectangle(cornerRadius: CornerRadius.xl, style: .continuous)
                    .fill(Color.Fairy.cloud.opacity(0.9))
                    .fairyShadow(.float)
            )
        }
    }
}

// MARK: - Inline Loading Indicator

/// Compact spinner for embedding inside views (e.g., inside a button or cell).
struct FairyInlineLoader: View {

    let color: Color
    let size: CGFloat

    @State private var rotation: Double = 0

    init(color: Color = .Fairy.violet, size: CGFloat = 20) {
        self.color = color
        self.size = size
    }

    var body: some View {
        Image(systemName: "sparkle")
            .font(.system(size: size * 0.7, weight: .medium, design: .rounded))
            .foregroundStyle(color)
            .rotationEffect(.degrees(rotation))
            .onAppear {
                withAnimation(.linear(duration: 1.0).repeatForever(autoreverses: false)) {
                    rotation = 360
                }
            }
    }
}

// MARK: - ViewModifier

/// Overlays the fairy loading screen when `isLoading` is true.
///
/// Usage:
/// ```swift
/// ContentView()
///     .fairyLoading(isLoading: viewModel.isLoading, label: "Converting...")
/// ```
struct FairyLoadingModifier: ViewModifier {

    let isLoading: Bool
    let label: String?
    let color: Color

    init(isLoading: Bool, label: String? = nil, color: Color = .Fairy.violet) {
        self.isLoading = isLoading
        self.label = label
        self.color = color
    }

    func body(content: Content) -> some View {
        ZStack {
            content
                .allowsHitTesting(!isLoading)

            if isLoading {
                FairyLoadingOverlay(label: label, color: color)
                    .transition(
                        .asymmetric(
                            insertion: .opacity.combined(with: .scale(scale: 0.95)),
                            removal: .opacity
                        )
                    )
                    .zIndex(999)
            }
        }
        .animation(.fairyMagic, value: isLoading)
    }
}

extension View {
    /// Overlays a full-screen fairy loading indicator when `isLoading` is true.
    func fairyLoading(
        _ isLoading: Bool,
        label: String? = nil,
        color: Color = .Fairy.violet
    ) -> some View {
        modifier(FairyLoadingModifier(isLoading: isLoading, label: label, color: color))
    }
}

// MARK: - Preview

#Preview("FairyLoadingOverlay") {
    @Previewable @State var isLoading = true

    ZStack {
        ScrollView {
            VStack(spacing: Spacing.md) {
                ForEach(0..<10) { i in
                    RoundedRectangle.fairyMedium
                        .fill(Color.Fairy.lavenderMist.opacity(0.3))
                        .frame(height: 60)
                }
            }
            .padding()
        }
        .background(Color.Fairy.dust)

        VStack {
            Spacer()
            Button("Toggle Loading") {
                isLoading.toggle()
            }
            .padding()
        }
    }
    .fairyLoading(isLoading, label: "Converting your file...")

    // Standalone spinner preview
    VStack(spacing: Spacing.xl) {
        FairySpinner(color: .Fairy.violet)
        FairySpinner(color: .Fairy.rose)
        FairySpinner(color: .Fairy.teal)

        HStack(spacing: Spacing.xl) {
            FairyInlineLoader(color: .Fairy.violet)
            FairyInlineLoader(color: .Fairy.amber, size: 28)
            FairyInlineLoader(color: .Fairy.mint, size: 16)
        }
    }
    .padding()
    .background(Color.Fairy.dust)
}
