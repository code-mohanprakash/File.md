// MascotView.swift
// FileFairy
//
// Fae mascot with per-mood appearance, animation, and haptic feedback.
// Uses SF Symbols as illustration placeholders until custom art assets are added.
// Asset swap path: replace the `symbolName` property with an Image("fae_\(mood.rawValue)").
//
// Moods:
//   .idle        → wand.and.stars.inverse  + gentle float loop
//   .happy       → sparkles                + bounce on appear
//   .thinking    → questionmark.circle     + slow rotation loop
//   .celebrating → party.popper            + bounce + sparkle particles
//   .sleeping    → moon.zzz                + slow pulse
//   .error       → exclamationmark.triangle + shake

import SwiftUI

// MARK: - Mascot Mood

enum MascotMood: String, CaseIterable {
    case idle
    case happy
    case thinking
    case celebrating
    case sleeping
    case error
}

// MARK: - MascotView

struct MascotView: View {

    let mood: MascotMood
    var size: CGFloat

    // Animation states
    @State private var floatOffset: CGFloat = 0
    @State private var scale: CGFloat = 0.5
    @State private var opacity: Double = 0
    @State private var rotation: Double = 0
    @State private var shakeAmount: CGFloat = 0
    @State private var pulseScale: CGFloat = 1.0
    @State private var showParticles = false

    init(mood: MascotMood = .idle, size: CGFloat = 96) {
        self.mood = mood
        self.size = size
    }

    var body: some View {
        ZStack {
            // Particle layer (celebrating only)
            if mood == .celebrating && showParticles {
                ParticleField(color: moodColor, count: 10, radius: size * 0.9)
                    .transition(.fairyScale)
            }

            // Background glow circle
            Circle()
                .fill(
                    RadialGradient(
                        colors: [moodColor.opacity(0.18), moodColor.opacity(0.0)],
                        center: .center,
                        startRadius: size * 0.2,
                        endRadius: size * 0.7
                    )
                )
                .frame(width: size * 1.4, height: size * 1.4)

            // Main icon circle
            Circle()
                .fill(
                    LinearGradient(
                        colors: [
                            moodColor.opacity(0.2),
                            moodColor.opacity(0.08)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .frame(width: size, height: size)

            // Mascot icon
            Image(systemName: moodSymbol)
                .font(.system(size: size * 0.42, weight: .medium, design: .rounded))
                .foregroundStyle(
                    LinearGradient(
                        colors: [moodColor, moodColor.opacity(0.75)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .symbolRenderingMode(.hierarchical)
                .rotationEffect(.degrees(rotation))
                .scaleEffect(pulseScale)
        }
        .scaleEffect(scale)
        .opacity(opacity)
        .offset(y: floatOffset)
        .modifier(ShakeEffect(animatableData: shakeAmount))
        .onChange(of: mood, initial: true) { _, newMood in
            playMoodTransition(for: newMood)
        }
    }

    // MARK: - Mood Metadata

    private var moodSymbol: String {
        switch mood {
        case .idle:         return "wand.and.stars.inverse"
        case .happy:        return "sparkles"
        case .thinking:     return "questionmark.circle"
        case .celebrating:  return "party.popper"
        case .sleeping:     return "moon.zzz"
        case .error:        return "exclamationmark.triangle"
        }
    }

    private var moodColor: Color {
        switch mood {
        case .idle:         return .Fairy.violet
        case .happy:        return .Fairy.rose
        case .thinking:     return .Fairy.amber
        case .celebrating:  return .Fairy.mint
        case .sleeping:     return .Fairy.lavenderMist
        case .error:        return .Fairy.softRed
        }
    }

    // MARK: - Mood Animations

    private func playMoodTransition(for newMood: MascotMood) {
        // Reset all animated state
        withAnimation(.none) {
            floatOffset = 0
            rotation = 0
            shakeAmount = 0
            pulseScale = 1.0
            showParticles = false
        }

        // Fade + scale entrance
        scale = 0.6
        opacity = 0

        withAnimation(.fairyCelebrate) {
            scale = 1.0
            opacity = 1.0
        }

        // Per-mood animation
        switch newMood {
        case .idle:
            startIdleFloat()

        case .happy:
            HapticEngine.shared.success()
            SoundPlayer.shared.play(.conversionDone)
            withAnimation(.fairyCelebrate) {
                scale = 1.15
            }
            withAnimation(.fairyGentle.delay(0.3)) {
                scale = 1.0
            }
            startIdleFloat()

        case .thinking:
            startThinkingRotation()

        case .celebrating:
            HapticEngine.shared.fairyMagic()
            SoundPlayer.shared.play(.conversionDone)
            withAnimation(.fairyCelebrate) {
                scale = 1.25
            }
            withAnimation(.fairyBounce.delay(0.35)) {
                scale = 1.0
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                withAnimation(.fairyMagic) { showParticles = true }
            }
            startIdleFloat()

        case .sleeping:
            startSleepingPulse()

        case .error:
            HapticEngine.shared.error()
            SoundPlayer.shared.play(.error)
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                withAnimation(.fairyShake) { shakeAmount = 1 }
            }
        }
    }

    private func startIdleFloat() {
        withAnimation(
            .easeInOut(duration: 2.4)
            .repeatForever(autoreverses: true)
        ) {
            floatOffset = -(size * 0.1)
        }
    }

    private func startThinkingRotation() {
        withAnimation(.linear(duration: 4.0).repeatForever(autoreverses: false)) {
            rotation = 360
        }
    }

    private func startSleepingPulse() {
        withAnimation(
            .easeInOut(duration: 2.0)
            .repeatForever(autoreverses: true)
        ) {
            pulseScale = 0.88
        }
    }
}

// MARK: - Particle Field

/// Decorative confetti-style circles that radiate outward on celebration.
private struct ParticleField: View {

    let color: Color
    let count: Int
    let radius: CGFloat

    var body: some View {
        ZStack {
            ForEach(0..<count, id: \.self) { index in
                ParticleDot(
                    color: color,
                    angle: Double(index) / Double(count) * 360,
                    radius: radius,
                    delay: Double(index) * 0.05
                )
            }
        }
    }
}

private struct ParticleDot: View {

    let color: Color
    let angle: Double
    let radius: CGFloat
    let delay: Double

    @State private var offset: CGFloat = 0
    @State private var opacity: Double = 1

    var body: some View {
        Circle()
            .fill(color.opacity(opacity))
            .frame(width: 5, height: 5)
            .offset(
                x: cos(angle * .pi / 180) * offset,
                y: sin(angle * .pi / 180) * offset
            )
            .onAppear {
                withAnimation(
                    .easeOut(duration: 0.9)
                    .delay(delay)
                ) {
                    offset = radius
                    opacity = 0
                }
            }
    }
}

// MARK: - Mascot with Message Bubble

/// Mascot paired with a speech bubble displaying a contextual message.
struct MascotWithMessage: View {

    let mood: MascotMood
    let message: String
    var mascotSize: CGFloat

    @State private var bubbleVisible = false

    init(mood: MascotMood, message: String, mascotSize: CGFloat = 80) {
        self.mood = mood
        self.message = message
        self.mascotSize = mascotSize
    }

    var body: some View {
        VStack(spacing: 0) {
            // Speech bubble
            if bubbleVisible {
                HStack(spacing: 0) {
                    Text(message)
                        .font(.Fairy.subtext)
                        .foregroundStyle(Color.Fairy.ink)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, Spacing.md)
                        .padding(.vertical, Spacing.sm)
                        .background(
                            RoundedRectangle(cornerRadius: CornerRadius.md, style: .continuous)
                                .fill(Color.Fairy.cloud)
                                .fairyShadow(.soft)
                        )
                        .fixedSize(horizontal: false, vertical: true)
                }
                .padding(.horizontal, Spacing.md)
                .padding(.bottom, Spacing.xs)
                .transition(
                    .asymmetric(
                        insertion: .scale(scale: 0.8, anchor: .bottom).combined(with: .opacity),
                        removal: .scale(scale: 0.8, anchor: .bottom).combined(with: .opacity)
                    )
                )
            }

            // Bubble tail
            if bubbleVisible {
                Triangle()
                    .fill(Color.Fairy.cloud)
                    .frame(width: 14, height: 7)
                    .padding(.bottom, -1)
                    .transition(.opacity)
            }

            // Mascot
            MascotView(mood: mood, size: mascotSize)
        }
        .onAppear {
            withAnimation(.fairyAppear.delay(0.4)) {
                bubbleVisible = true
            }
        }
        .onChange(of: message) { _, _ in
            bubbleVisible = false
            withAnimation(.fairySnappy.delay(0.2)) {
                bubbleVisible = true
            }
        }
    }
}

// MARK: - Triangle Shape (Speech Bubble Tail)

private struct Triangle: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        path.move(to: CGPoint(x: rect.midX, y: rect.maxY))
        path.addLine(to: CGPoint(x: rect.minX, y: rect.minY))
        path.addLine(to: CGPoint(x: rect.maxX, y: rect.minY))
        path.closeSubpath()
        return path
    }
}

// MARK: - Preview

#Preview("MascotView") {
    @Previewable @State var selectedMood: MascotMood = .idle

    VStack(spacing: Spacing.xl) {
        MascotView(mood: selectedMood, size: 120)
            .frame(height: 160)

        // Mood selector
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: Spacing.xs) {
                ForEach(MascotMood.allCases, id: \.self) { mood in
                    Button(mood.rawValue.capitalized) {
                        selectedMood = mood
                    }
                    .font(.Fairy.caption)
                    .padding(.horizontal, Spacing.sm)
                    .padding(.vertical, Spacing.xxs)
                    .background(
                        selectedMood == mood
                            ? Color.Fairy.violet
                            : Color.Fairy.cream,
                        in: Capsule()
                    )
                    .foregroundStyle(
                        selectedMood == mood ? Color.white : Color.Fairy.violet
                    )
                    .buttonStyle(.plain)
                }
            }
            .padding(.horizontal, Spacing.md)
        }

        // All moods grid
        LazyVGrid(columns: [GridItem(.adaptive(minimum: 80))], spacing: Spacing.md) {
            ForEach(MascotMood.allCases, id: \.self) { mood in
                VStack(spacing: Spacing.xxs) {
                    MascotView(mood: mood, size: 56)
                    Text(mood.rawValue)
                        .fairyText(.caption)
                }
            }
        }
        .padding(Spacing.md)

        // With speech bubble
        MascotWithMessage(
            mood: .happy,
            message: "Great scan! Your document is ready.",
            mascotSize: 72
        )
    }
    .padding(Spacing.md)
    .background(Color.Fairy.dust)
}
