// MBOXImportProgressView.swift
// FileFairy

import SwiftUI

struct MBOXImportProgressView: View {
    let progress: Double
    let emailCount: Int
    let onCancel: () -> Void

    var body: some View {
        ZStack {
            Color.black.opacity(0.4).ignoresSafeArea()
            VStack(spacing: Spacing.lg) {
                FairyProgressView(progress: progress, variant: .circular, color: .Fairy.teal, size: 80)
                Text("\(emailCount) emails found")
                    .font(.Fairy.number)
                    .foregroundStyle(Color.Fairy.ink)
                Text("Importing...")
                    .font(.Fairy.body)
                    .foregroundStyle(Color.Fairy.slate)
                Button("Cancel", action: onCancel)
                    .font(.Fairy.button)
                    .foregroundStyle(Color.Fairy.softRed)
            }
            .padding(Spacing.xl)
            .background(Color.Fairy.cream, in: RoundedRectangle.fairyXL)
            .fairyShadow(.float)
            .padding(Spacing.xl)
        }
    }
}
