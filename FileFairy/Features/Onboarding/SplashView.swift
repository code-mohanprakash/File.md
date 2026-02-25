// SplashView.swift
// FileFairy
//
// Launch splash shown before main app content.
// Displays app logo with time-based glow, app name, tagline,
// and a staggered feature icon row. Calls onComplete after 2.5 seconds.

import SwiftUI

// MARK: - SplashView

struct SplashView: View {

    let onComplete: () -> Void

    @State private var animationPhase: Double = 0
    @State private var pulsing: Bool = false

    // Staggered appearance states
    @State private var showLogo = false
    @State private var showTitle = false
    @State private var showTagline = false
    @State private var showIcons = false
    @State private var iconOffsets: [CGFloat] = Array(repeating: 30, count: 5)

    private let period: SplashTimePeriod = .current

    // MARK: - Feature Icons

    private struct FeatureIcon {
        let assetName: String
        let fallbackSymbol: String
        let label: String
        let color: Color
    }

    private let features: [FeatureIcon] = [
        FeatureIcon(assetName: "FeatureScanner",   fallbackSymbol: "camera.fill",                   label: "Scan",    color: .Fairy.rose),
        FeatureIcon(assetName: "FeatureMbox",      fallbackSymbol: "envelope.fill",                 label: "Email",   color: .Fairy.teal),
        FeatureIcon(assetName: "FeatureConverter", fallbackSymbol: "arrow.triangle.2.circlepath",   label: "Convert", color: .Fairy.amber),
        FeatureIcon(assetName: "FeatureFiles",     fallbackSymbol: "folder.fill",                   label: "Open",    color: .Fairy.indigo),
        FeatureIcon(assetName: "FeaturePDF",       fallbackSymbol: "doc.fill",                      label: "PDF",     color: .Fairy.green)
    ]

    // MARK: - Body

    var body: some View {
        ZStack {
            Color.Fairy.dust.ignoresSafeArea()

            VStack(spacing: Spacing.xl) {
                Spacer()

                // Logo with ambient animation
                logoSection
                    .opacity(showLogo ? 1 : 0)
                    .scaleEffect(showLogo ? 1 : 0.8)

                // App name
                Text("FileFairy")
                    .font(.system(size: 36, weight: .black, design: .rounded))
                    .foregroundStyle(Color.Fairy.ink)
                    .opacity(showTitle ? 1 : 0)
                    .offset(y: showTitle ? 0 : 12)

                // Tagline
                Text("Your files, like magic.")
                    .font(.Fairy.subtext)
                    .foregroundStyle(Color.Fairy.mist)
                    .opacity(showTagline ? 1 : 0)
                    .offset(y: showTagline ? 0 : 8)

                Spacer()

                // Feature icons row
                featureIconsRow
                    .opacity(showIcons ? 1 : 0)
                    .padding(.bottom, Spacing.xxl)
            }
        }
        .onAppear {
            startAnimations()
        }
    }

    // MARK: - Logo Section

    private var logoSection: some View {
        ZStack {
            // Ambient effect layer
            period.ambientView(phase: animationPhase, pulsing: pulsing)

            // Logo image
            Group {
                if UIImage(named: "AppLogo") != nil {
                    Image("AppLogo")
                        .resizable()
                        .scaledToFit()
                } else {
                    Image(systemName: "wand.and.stars")
                        .resizable()
                        .scaledToFit()
                        .padding(20)
                        .foregroundStyle(Color.Fairy.violet)
                }
            }
            .frame(width: 96, height: 96)
            .clipShape(RoundedRectangle(cornerRadius: 22, style: .continuous))
            .shadow(color: period.accentColor.opacity(0.3), radius: 20, x: 0, y: 8)
        }
        .frame(width: 120, height: 120)
    }

    // MARK: - Feature Icons Row

    private var featureIconsRow: some View {
        HStack(spacing: Spacing.xl) {
            ForEach(Array(features.enumerated()), id: \.offset) { index, feature in
                VStack(spacing: Spacing.xxs) {
                    Group {
                        if UIImage(named: feature.assetName) != nil {
                            Image(feature.assetName)
                                .resizable()
                                .scaledToFit()
                        } else {
                            Image(systemName: feature.fallbackSymbol)
                                .resizable()
                                .scaledToFit()
                                .padding(8)
                                .foregroundStyle(feature.color)
                        }
                    }
                    .frame(width: 40, height: 40)
                    .background(feature.color.opacity(0.12), in: RoundedRectangle(cornerRadius: 10, style: .continuous))

                    Text(feature.label)
                        .font(.system(size: 10, weight: .medium, design: .rounded))
                        .foregroundStyle(Color.Fairy.mist)
                }
                .offset(y: iconOffsets[index])
            }
        }
    }

    // MARK: - Animation Orchestration

    private func startAnimations() {
        // Start ambient loop
        withAnimation(.linear(duration: 3).repeatForever(autoreverses: false)) {
            animationPhase = 1.0
        }
        withAnimation(.easeInOut(duration: 2.0).repeatForever(autoreverses: true)) {
            pulsing = true
        }

        // Staggered entrance
        withAnimation(.spring(response: 0.6, dampingFraction: 0.75)) {
            showLogo = true
        }
        withAnimation(.spring(response: 0.5, dampingFraction: 0.8).delay(0.25)) {
            showTitle = true
        }
        withAnimation(.easeOut(duration: 0.4).delay(0.45)) {
            showTagline = true
        }
        withAnimation(.easeOut(duration: 0.3).delay(0.6)) {
            showIcons = true
        }

        // Staggered icon slide-up
        for index in 0..<5 {
            withAnimation(.spring(response: 0.5, dampingFraction: 0.75).delay(0.65 + Double(index) * 0.08)) {
                iconOffsets[index] = 0
            }
        }

        // Dismiss after 2.5 seconds
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.5) {
            onComplete()
        }
    }
}

// MARK: - SplashTimePeriod

/// Mirrors the time period logic from GreetingHeader, self-contained for SplashView.
private enum SplashTimePeriod {
    case morning, afternoon, evening, night

    static var current: SplashTimePeriod {
        let hour = Calendar.current.component(.hour, from: Date())
        switch hour {
        case 6..<12:  return .morning
        case 12..<18: return .afternoon
        case 18..<22: return .evening
        default:       return .night
        }
    }

    var accentColor: Color {
        switch self {
        case .morning:   return .Fairy.amber
        case .afternoon: return .Fairy.violet
        case .evening:   return .Fairy.rose
        case .night:     return Color(hex: "#1E3A5F")
        }
    }

    @ViewBuilder
    func ambientView(phase: Double, pulsing: Bool) -> some View {
        switch self {
        case .morning:
            SplashMorningParticles(phase: phase, color: accentColor)
        case .afternoon:
            SplashGlowRing(pulsing: pulsing, color: accentColor)
        case .evening:
            SplashEveningShimmer(phase: phase, color: accentColor)
        case .night:
            SplashNightOrbit(phase: phase, color: accentColor)
        }
    }
}

// MARK: - Splash Ambient Effect Views

private struct SplashMorningParticles: View {
    let phase: Double
    let color: Color
    private let count = 8
    private let radius: CGFloat = 68

    var body: some View {
        ZStack {
            ForEach(0..<count, id: \.self) { i in
                SplashMorningParticle(
                    index: i,
                    count: count,
                    phase: phase,
                    color: color,
                    radius: radius
                )
            }
        }
        .frame(width: 120, height: 120)
    }
}

private struct SplashMorningParticle: View {
    let index: Int
    let count: Int
    let phase: Double
    let color: Color
    let radius: CGFloat

    var body: some View {
        let angleDeg = Double(index) / Double(count) * 360.0 + phase * 360.0
        let angle = angleDeg * .pi / 180.0
        let size: CGFloat = index % 2 == 0 ? 6 : 4
        let ox = cos(angle) * Double(radius)
        let oy = sin(angle) * Double(radius)
        let op = 0.6 + 0.4 * sin(Double(index))
        return Circle()
            .fill(color)
            .frame(width: size, height: size)
            .offset(x: CGFloat(ox), y: CGFloat(oy))
            .opacity(op)
    }
}

private struct SplashGlowRing: View {
    let pulsing: Bool
    let color: Color

    var body: some View {
        ZStack {
            Circle()
                .fill(color.opacity(pulsing ? 0.1 : 0.05))
                .frame(width: pulsing ? 120 : 110, height: pulsing ? 120 : 110)
            Circle()
                .strokeBorder(color.opacity(0.45), lineWidth: pulsing ? 2.5 : 1.5)
                .frame(width: pulsing ? 114 : 106, height: pulsing ? 114 : 106)
        }
        .animation(.easeInOut(duration: 2.0).repeatForever(autoreverses: true), value: pulsing)
    }
}

private struct SplashEveningShimmer: View {
    let phase: Double
    let color: Color

    var body: some View {
        ZStack {
            ForEach(0..<5, id: \.self) { i in
                let offset = Double(i) / 5.0
                let fy = sin((phase + offset) * .pi * 2) * 16
                let fx = cos((phase + offset) * .pi * 1.5) * 12
                let positions: [(CGFloat, CGFloat)] = [(-44, -28), (44, -28), (-36, 32), (36, 32), (0, -50)]
                let (baseX, baseY) = positions[i]
                Circle()
                    .fill(color)
                    .frame(width: 5, height: 5)
                    .offset(x: baseX + CGFloat(fx), y: baseY + CGFloat(fy))
                    .opacity(0.35 + 0.55 * sin((phase + offset) * .pi * 2))
            }
        }
        .frame(width: 120, height: 120)
    }
}

private struct SplashNightOrbit: View {
    let phase: Double
    let color: Color
    private let radii: [CGFloat] = [56, 64, 58, 62, 60, 54]

    var body: some View {
        ZStack {
            ForEach(0..<6, id: \.self) { i in
                let base = (Double(i) / 6.0) * 360
                let angle = (base + phase * 180) * .pi / 180
                let r = radii[i]
                Circle()
                    .fill(color)
                    .frame(width: 4, height: 4)
                    .offset(x: cos(angle) * r, y: sin(angle) * r)
                    .opacity(0.5 + 0.4 * sin(Double(i)))
            }
        }
        .frame(width: 120, height: 120)
    }
}

// MARK: - Preview

#Preview {
    SplashView(onComplete: {})
}
