// FairyProgressView.swift
// FileFairy
//
// Two branded progress variants:
//   - Circular: animated gradient stroke ring with percentage label in center
//   - Linear: capsule fill bar with optional label
//
// Both accept progress: Double (0.0 – 1.0), a tint color, and an optional label.
// The ring uses a conic gradient trimmed to the progress value.

import SwiftUI

// MARK: - Progress Variant Enum

enum FairyProgressVariant {
    case circular
    case linear
}

// MARK: - FairyProgressView (Unified Entry Point)

/// A themed progress indicator.
///
/// Usage:
/// ```swift
/// // Circular, 80 % complete, violet
/// FairyProgressView(progress: 0.8, variant: .circular, color: .Fairy.violet, label: "Converting")
///
/// // Linear, 45 % complete, teal
/// FairyProgressView(progress: 0.45, variant: .linear, color: .Fairy.teal, label: "Uploading")
/// ```
struct FairyProgressView: View {

    let progress: Double      // 0.0 – 1.0
    let variant: FairyProgressVariant
    let color: Color
    let label: String?
    var size: CGFloat         // Used by circular variant; ignored by linear

    init(
        progress: Double,
        variant: FairyProgressVariant = .circular,
        color: Color = .Fairy.violet,
        label: String? = nil,
        size: CGFloat = 88
    ) {
        self.progress = min(max(progress, 0), 1)
        self.variant = variant
        self.color = color
        self.label = label
        self.size = size
    }

    var body: some View {
        switch variant {
        case .circular:
            FairyCircularProgress(progress: progress, color: color, label: label, size: size)
        case .linear:
            FairyLinearProgress(progress: progress, color: color, label: label)
        }
    }
}

// MARK: - Circular Progress

struct FairyCircularProgress: View {

    let progress: Double
    let color: Color
    let label: String?
    let size: CGFloat

    init(progress: Double, color: Color = .Fairy.violet, label: String? = nil, size: CGFloat = 88) {
        self.progress = min(max(progress, 0), 1)
        self.color = color
        self.label = label
        self.size = size
    }

    @State private var animatedProgress: Double = 0
    @State private var rotationAngle: Double = 0

    private let lineWidth: CGFloat = 7
    private var percentageText: String {
        "\(Int(animatedProgress * 100))%"
    }

    var body: some View {
        VStack(spacing: Spacing.xs) {
            ZStack {
                // Track ring
                Circle()
                    .stroke(color.opacity(0.12), lineWidth: lineWidth)
                    .frame(width: size, height: size)

                // Progress ring — trimmed arc with gradient stroke
                Circle()
                    .trim(from: 0, to: animatedProgress)
                    .stroke(
                        AngularGradient(
                            gradient: Gradient(colors: [color.opacity(0.5), color]),
                            center: .center,
                            startAngle: .degrees(-90),
                            endAngle: .degrees(270)
                        ),
                        style: StrokeStyle(
                            lineWidth: lineWidth,
                            lineCap: .round
                        )
                    )
                    .frame(width: size, height: size)
                    .rotationEffect(.degrees(-90))

                // Sparkle dot at the tip of the arc
                Circle()
                    .fill(color)
                    .frame(width: lineWidth, height: lineWidth)
                    .offset(y: -(size / 2))
                    .rotationEffect(.degrees((animatedProgress * 360) - 90))

                // Center content
                VStack(spacing: 1) {
                    Text(percentageText)
                        .font(.system(size: size * 0.22, weight: .bold, design: .rounded))
                        .foregroundStyle(color)
                        .monospacedDigit()
                        .contentTransition(.numericText(countsDown: false))
                        .animation(.fairyGentle, value: animatedProgress)

                    if let label {
                        Text(label)
                            .font(.system(size: size * 0.12, weight: .medium, design: .rounded))
                            .foregroundStyle(Color.Fairy.mist)
                            .lineLimit(1)
                            .minimumScaleFactor(0.7)
                    }
                }
            }
        }
        .onAppear {
            withAnimation(.fairyGentle) {
                animatedProgress = progress
            }
        }
        .onChange(of: progress) { _, newValue in
            withAnimation(.fairyGentle) {
                animatedProgress = newValue
            }
        }
    }
}

// MARK: - Linear Progress

struct FairyLinearProgress: View {

    let progress: Double
    let color: Color
    let label: String?

    @State private var animatedProgress: Double = 0

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.xxs) {
            // Label + percentage row
            if let label {
                HStack {
                    Text(label)
                        .fairyText(.caption)
                        .foregroundStyle(Color.Fairy.slate)

                    Spacer()

                    Text("\(Int(animatedProgress * 100))%")
                        .font(.system(size: 13, weight: .semibold, design: .rounded))
                        .foregroundStyle(color)
                        .monospacedDigit()
                        .contentTransition(.numericText())
                        .animation(.fairyGentle, value: animatedProgress)
                }
            }

            // Track
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    // Background track
                    Capsule()
                        .fill(color.opacity(0.12))
                        .frame(height: 8)

                    // Fill bar
                    Capsule()
                        .fill(
                            LinearGradient(
                                colors: [color.opacity(0.7), color],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .frame(
                            width: max(8, geo.size.width * animatedProgress),
                            height: 8
                        )
                        .shadow(color: color.opacity(0.3), radius: 4, x: 0, y: 2)
                }
            }
            .frame(height: 8)
        }
        .onAppear {
            withAnimation(.fairyGentle) {
                animatedProgress = progress
            }
        }
        .onChange(of: progress) { _, newValue in
            withAnimation(.fairyGentle) {
                animatedProgress = newValue
            }
        }
    }
}

// MARK: - Indeterminate Spinner

/// Used when progress value is unknown (network wait, etc.)
struct FairyIndeterminateProgress: View {

    let color: Color
    let size: CGFloat

    @State private var rotation: Double = 0

    init(color: Color = .Fairy.violet, size: CGFloat = 44) {
        self.color = color
        self.size = size
    }

    var body: some View {
        ZStack {
            Circle()
                .stroke(color.opacity(0.12), lineWidth: 4)
                .frame(width: size, height: size)

            Circle()
                .trim(from: 0, to: 0.75)
                .stroke(
                    AngularGradient(
                        colors: [color.opacity(0.1), color],
                        center: .center
                    ),
                    style: StrokeStyle(lineWidth: 4, lineCap: .round)
                )
                .frame(width: size, height: size)
                .rotationEffect(.degrees(rotation))
        }
        .onAppear {
            withAnimation(.linear(duration: 1.0).repeatForever(autoreverses: false)) {
                rotation = 360
            }
        }
    }
}

// MARK: - Conversion Progress Card

/// A branded card that displays conversion progress inline.
struct FairyConversionProgressCard: View {

    let fileName: String
    let progress: Double
    let theme: ModuleTheme
    var onCancel: (() -> Void)?

    var body: some View {
        FairyCard {
            HStack(spacing: Spacing.md) {
                FairyCircularProgress(
                    progress: progress,
                    color: theme.primary,
                    size: 56
                )

                VStack(alignment: .leading, spacing: Spacing.xxs) {
                    Text(fileName)
                        .fairyText(.headline)
                        .lineLimit(1)

                    FairyLinearProgress(
                        progress: progress,
                        color: theme.primary,
                        label: nil
                    )

                    Text(progress < 1 ? "Converting..." : "Done!")
                        .fairyText(.caption)
                        .foregroundStyle(progress < 1 ? Color.Fairy.mist : theme.primary)
                }

                if progress < 1.0, let cancel = onCancel {
                    FairyIconButton(
                        systemName: "xmark",
                        color: .Fairy.mist,
                        size: 32,
                        action: cancel
                    )
                }
            }
        }
    }
}

// MARK: - Preview

#Preview("FairyProgressView") {
    @Previewable @State var progress = 0.65

    ScrollView {
        VStack(spacing: Spacing.xl) {

            // Circular variants
            HStack(spacing: Spacing.xl) {
                FairyCircularProgress(progress: progress, color: .Fairy.violet, label: "Converting", size: 88)
                FairyCircularProgress(progress: 0.33, color: .Fairy.rose, label: "Scanning", size: 72)
                FairyCircularProgress(progress: 1.0, color: .Fairy.mint, size: 56)
            }

            // Linear variants
            VStack(spacing: Spacing.md) {
                FairyLinearProgress(progress: progress, color: .Fairy.violet, label: "Converting")
                FairyLinearProgress(progress: 0.2, color: .Fairy.teal, label: "Uploading")
                FairyLinearProgress(progress: 1.0, color: .Fairy.mint, label: "Complete")
            }

            // Indeterminate
            HStack(spacing: Spacing.xl) {
                FairyIndeterminateProgress(color: .Fairy.violet)
                FairyIndeterminateProgress(color: .Fairy.rose, size: 32)
                FairyIndeterminateProgress(color: .Fairy.teal, size: 24)
            }

            // Conversion card
            FairyConversionProgressCard(
                fileName: "Annual Report 2024.pdf",
                progress: progress,
                theme: .converter
            ) {
                print("cancel")
            }

            // Slider to test live progress
            VStack {
                Text("Adjust Progress: \(Int(progress * 100))%")
                    .fairyText(.caption)
                Slider(value: $progress)
                    .tint(Color.Fairy.violet)
            }
            .padding()
        }
        .padding(Spacing.md)
    }
    .background(Color.Fairy.dust)
}
