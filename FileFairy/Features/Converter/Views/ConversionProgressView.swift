// ConversionProgressView.swift
// FileFairy

import SwiftUI

struct ConversionProgressView: View {
    let progress: Double
    let type: ConversionType

    @State private var wandRotation: Double = 0

    var body: some View {
        VStack(spacing: Spacing.lg) {
            // Animated wand spinner
            ZStack {
                // Track
                Circle()
                    .stroke(type.featureColor.opacity(0.15), lineWidth: 6)
                    .frame(width: 80, height: 80)

                // Progress ring
                Circle()
                    .trim(from: 0, to: progress)
                    .stroke(
                        type.featureColor,
                        style: StrokeStyle(lineWidth: 6, lineCap: .round)
                    )
                    .frame(width: 80, height: 80)
                    .rotationEffect(.degrees(-90))
                    .animation(.fairyGentle, value: progress)

                // Wand icon
                Image(systemName: "wand.and.stars")
                    .font(.system(size: 24, weight: .medium))
                    .foregroundStyle(type.featureColor)
                    .rotationEffect(.degrees(wandRotation))
            }

            VStack(spacing: Spacing.xs) {
                Text("Converting...")
                    .font(.Fairy.body)
                    .foregroundStyle(Color.Fairy.ink)

                Text("\(Int(progress * 100))%")
                    .font(.Fairy.headline)
                    .foregroundStyle(type.featureColor)
                    .contentTransition(.numericText())
                    .animation(.fairySnappy, value: progress)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, Spacing.xl)
        .onAppear {
            withAnimation(.linear(duration: 2).repeatForever(autoreverses: false)) {
                wandRotation = 360
            }
        }
    }
}
