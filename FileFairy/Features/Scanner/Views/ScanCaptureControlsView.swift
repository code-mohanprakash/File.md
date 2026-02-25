// ScanCaptureControlsView.swift
// FileFairy
//
// Camera controls: shutter button, flash toggle, page gallery strip.
// From PRD Section 6.2:
// - Shutter: 64pt circle, pink fill, white camera icon, spring bounce on capture
// - Gallery Strip: horizontal scroll of captured page thumbnails (48pt rounded squares)
// - Done Button: pill shape, "Done (3)" with page count, violet fill

import SwiftUI

struct ScanCaptureControlsView: View {

    @Bindable var viewModel: ScannerViewModel
    let onCapture: () -> Void
    let onDone: () -> Void

    var body: some View {
        VStack(spacing: Spacing.md) {

            // MARK: - Filter Strip
            FilterPickerView(
                selectedFilter: $viewModel.currentFilter
            )

            // MARK: - Bottom Controls
            HStack(alignment: .bottom) {

                // Gallery strip (left)
                if viewModel.hasPages {
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: Spacing.xs) {
                            ForEach(Array(viewModel.capturedPages.enumerated()), id: \.offset) { index, image in
                                Image(uiImage: image)
                                    .resizable()
                                    .aspectRatio(contentMode: .fill)
                                    .frame(width: 48, height: 48)
                                    .clipShape(RoundedRectangle(cornerRadius: CornerRadius.sm, style: .continuous))
                                    .overlay(
                                        RoundedRectangle(cornerRadius: CornerRadius.sm, style: .continuous)
                                            .stroke(Color.white.opacity(0.5), lineWidth: 1)
                                    )
                                    .onTapGesture {
                                        viewModel.currentReviewIndex = index
                                        viewModel.enterReview()
                                    }
                            }
                        }
                    }
                    .frame(maxWidth: 120)
                } else {
                    Spacer()
                        .frame(width: 120)
                }

                Spacer()

                // Shutter button (center)
                ShutterButton(action: onCapture)

                Spacer()

                // Done button (right)
                if viewModel.hasPages {
                    Button(action: onDone) {
                        Text("Done (\(viewModel.pageCount))")
                            .font(.Fairy.button)
                            .foregroundStyle(.white)
                            .padding(.horizontal, Spacing.md)
                            .padding(.vertical, Spacing.sm)
                            .background(Color.Fairy.violet, in: .capsule)
                    }
                    .pressScale()
                } else {
                    Spacer()
                        .frame(width: 100)
                }
            }
            .padding(.horizontal, Spacing.md)
        }
        .padding(.bottom, Spacing.xl)
    }
}

// MARK: - Shutter Button

struct ShutterButton: View {

    let action: () -> Void
    @State private var isPressed = false

    var body: some View {
        Button(action: {
            action()
        }) {
            ZStack {
                // Outer ring
                Circle()
                    .fill(Color.white.opacity(0.3))
                    .frame(width: 72, height: 72)

                // Inner circle - rose pink
                Circle()
                    .fill(Color.Fairy.rose)
                    .frame(width: 64, height: 64)

                // Camera icon
                Image(systemName: "camera.fill")
                    .font(.system(size: 24, weight: .semibold))
                    .foregroundStyle(.white)
            }
            .scaleEffect(isPressed ? 0.9 : 1.0)
            .animation(.fairyBounce, value: isPressed)
        }
        .buttonStyle(.plain)
        .simultaneousGesture(
            DragGesture(minimumDistance: 0)
                .onChanged { _ in isPressed = true }
                .onEnded { _ in isPressed = false }
        )
    }
}
