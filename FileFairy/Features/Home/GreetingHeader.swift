// GreetingHeader.swift
// FileFairy
//
// App logo with time-based ambient animation + contextual greeting.
// Morning: golden sparkle particles. Afternoon: violet glow ring.
// Evening: rose shimmer float. Night: deep blue orbiting stars.

import SwiftUI

// MARK: - Time Period

private enum TimePeriod {
    case morning    // 6am – 12pm
    case afternoon  // 12pm – 6pm
    case evening    // 6pm – 10pm
    case night      // 10pm – 6am

    static var current: TimePeriod {
        let hour = Calendar.current.component(.hour, from: Date())
        switch hour {
        case 6..<12:  return .morning
        case 12..<18: return .afternoon
        case 18..<22: return .evening
        default:       return .night
        }
    }

    var greetingText: String {
        switch self {
        case .morning:   return "Good morning ✦"
        case .afternoon: return "Good afternoon ✦"
        case .evening:   return "Good evening ✦"
        case .night:     return "Good night ✦"
        }
    }

    var accentColor: Color {
        switch self {
        case .morning:   return Color.Fairy.amber
        case .afternoon: return Color.Fairy.violet
        case .evening:   return Color.Fairy.rose
        case .night:     return Color(hex: "#1E3A5F")
        }
    }
}

// MARK: - GreetingHeader

struct GreetingHeader: View {

    private let period = TimePeriod.current

    @State private var animationPhase: Double = 0
    @State private var pulsing: Bool = false

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.sm) {
            // Logo + animation
            HStack(alignment: .center, spacing: Spacing.md) {
                logoWithAnimation
                    .frame(width: 72, height: 72)

                VStack(alignment: .leading, spacing: Spacing.xxxs) {
                    Text(period.greetingText)
                        .font(.Fairy.title)
                        .foregroundStyle(Color.Fairy.ink)

                    Text("What shall we do today?")
                        .font(.Fairy.body)
                        .foregroundStyle(Color.Fairy.mist)
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, Spacing.md)
        .padding(.top, Spacing.lg)
        .onAppear {
            withAnimation(
                .linear(duration: 3)
                .repeatForever(autoreverses: false)
            ) {
                animationPhase = 1.0
            }
            withAnimation(
                .easeInOut(duration: 2.0)
                .repeatForever(autoreverses: true)
            ) {
                pulsing = true
            }
        }
    }

    // MARK: - Logo + Ambient Effect

    @ViewBuilder
    private var logoWithAnimation: some View {
        ZStack {
            switch period {
            case .morning:
                MorningParticles(phase: animationPhase, color: period.accentColor)
            case .afternoon:
                AfternoonGlowRing(pulsing: pulsing, color: period.accentColor)
            case .evening:
                EveningShimmer(phase: animationPhase, color: period.accentColor)
            case .night:
                NightOrbit(phase: animationPhase, color: period.accentColor)
            }

            // App logo
            logoImage
                .scaleEffect(period == .morning ? (pulsing ? 1.04 : 1.0) : 1.0)
                .animation(.easeInOut(duration: 2.0).repeatForever(autoreverses: true), value: pulsing)
        }
    }

    private var logoImage: some View {
        Group {
            if UIImage(named: "AppLogo") != nil {
                Image("AppLogo")
                    .resizable()
                    .scaledToFit()
            } else {
                // Fallback when asset is absent
                Image(systemName: "wand.and.stars")
                    .resizable()
                    .scaledToFit()
                    .padding(14)
                    .foregroundStyle(Color.Fairy.violet)
            }
        }
        .frame(width: 72, height: 72)
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        .shadow(color: period.accentColor.opacity(0.25), radius: 8, x: 0, y: 4)
    }
}

// MARK: - Morning Particles (golden sparkles rotating)

private struct MorningParticles: View {
    let phase: Double
    let color: Color

    private let particleCount = 6
    private let orbitRadius: CGFloat = 46

    var body: some View {
        ZStack {
            ForEach(0..<particleCount, id: \.self) { index in
                let angle = (Double(index) / Double(particleCount) * 360 + phase * 360)
                let radians = angle * .pi / 180
                let x = cos(radians) * orbitRadius
                let y = sin(radians) * orbitRadius
                let size: CGFloat = index % 2 == 0 ? 5 : 3

                Circle()
                    .fill(color)
                    .frame(width: size, height: size)
                    .offset(x: x, y: y)
                    .opacity(0.7 + 0.3 * sin(Double(index) * .pi / 2))
            }
        }
        .frame(width: 72, height: 72)
    }
}

// MARK: - Afternoon Glow Ring (violet pulse)

private struct AfternoonGlowRing: View {
    let pulsing: Bool
    let color: Color

    var body: some View {
        ZStack {
            // Outer soft glow
            Circle()
                .fill(color.opacity(pulsing ? 0.08 : 0.04))
                .frame(width: pulsing ? 88 : 80, height: pulsing ? 88 : 80)

            // Ring stroke
            Circle()
                .strokeBorder(color.opacity(0.4), lineWidth: pulsing ? 2 : 1)
                .frame(width: pulsing ? 84 : 78, height: pulsing ? 84 : 78)
        }
        .animation(.easeInOut(duration: 2.0).repeatForever(autoreverses: true), value: pulsing)
    }
}

// MARK: - Evening Shimmer (rose floating particles)

private struct EveningShimmer: View {
    let phase: Double
    let color: Color

    private let dots = 4

    var body: some View {
        ZStack {
            ForEach(0..<dots, id: \.self) { index in
                let offset = Double(index) / Double(dots)
                let floatY = sin((phase + offset) * .pi * 2) * 12
                let floatX = cos((phase + offset) * .pi * 1.5) * 8
                let opacity = 0.4 + 0.5 * sin((phase + offset) * .pi * 2)

                Circle()
                    .fill(color)
                    .frame(width: 4, height: 4)
                    .offset(
                        x: CGFloat(floatX) + CGFloat(index % 2 == 0 ? 32 : -32),
                        y: CGFloat(floatY) + CGFloat(index < 2 ? -28 : 28)
                    )
                    .opacity(opacity)
            }
        }
        .frame(width: 72, height: 72)
    }
}

// MARK: - Night Orbit (deep blue stars)

private struct NightOrbit: View {
    let phase: Double
    let color: Color

    private let starCount = 5
    private let radii: [CGFloat] = [40, 50, 44, 48, 42]

    var body: some View {
        ZStack {
            ForEach(0..<starCount, id: \.self) { index in
                let baseAngle = (Double(index) / Double(starCount)) * 360
                let angle = baseAngle + phase * 180  // slower rotation
                let radians = angle * .pi / 180
                let r = radii[index]

                Circle()
                    .fill(color)
                    .frame(width: 4, height: 4)
                    .offset(
                        x: cos(radians) * r,
                        y: sin(radians) * r
                    )
                    .opacity(0.6 + 0.4 * sin(Double(index)))
            }
        }
        .frame(width: 72, height: 72)
    }
}

// MARK: - Preview

#Preview {
    VStack(spacing: 0) {
        GreetingHeader()
        Spacer()
    }
    .background(Color.Fairy.dust)
}
