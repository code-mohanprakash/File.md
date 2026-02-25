// ScannerCameraView.swift
// FileFairy
//
// Full-screen camera view for document scanning.
// From PRD Section 6.2: Camera preview full screen,
// edge overlay, top bar with flash/page count/close,
// filter strip, shutter, gallery, done button.

import SwiftUI

struct ScannerCameraView: View {

    @Bindable var viewModel: ScannerViewModel
    let onDismiss: () -> Void

    var body: some View {
        ZStack {
            // MARK: - Camera Preview (full bleed)
            if viewModel.captureState != .idle &&
               viewModel.captureState != .requestingPermission &&
               viewModel.captureState != .permissionDenied {
                CameraPreviewView(session: viewModel.cameraManager.session)
                    .ignoresSafeArea()
            }

            // MARK: - Edge Detection Overlay
            if viewModel.captureState == .previewing {
                EdgeOverlayView(observation: viewModel.detectedQuad)
                    .ignoresSafeArea()
            }

            // MARK: - Review Mode
            if viewModel.captureState == .reviewing {
                ScanReviewView(viewModel: viewModel)
            }

            // MARK: - Controls Overlay
            if viewModel.captureState == .previewing || viewModel.captureState == .capturing {
                VStack {
                    // Top bar
                    ScannerTopBar(
                        isFlashOn: viewModel.isFlashOn,
                        pageCount: viewModel.pageCount,
                        onFlashToggle: { viewModel.cameraManager.toggleFlash() },
                        onClose: {
                            viewModel.stopScanner()
                            onDismiss()
                        }
                    )

                    Spacer()

                    // Bottom controls
                    ScanCaptureControlsView(
                        viewModel: viewModel,
                        onCapture: {
                            Task { await viewModel.capturePhoto() }
                        },
                        onDone: {
                            viewModel.enterReview()
                        }
                    )
                }
            }

            // MARK: - Permission Denied
            if viewModel.captureState == .permissionDenied {
                VStack(spacing: Spacing.lg) {
                    Image(systemName: "camera.fill")
                        .font(.system(size: 48))
                        .foregroundStyle(Color.Fairy.rose)

                    Text("Camera Access Required")
                        .font(.Fairy.title)
                        .foregroundStyle(Color.Fairy.ink)

                    Text("FileFairy needs camera access to scan documents. Please enable it in Settings.")
                        .font(.Fairy.body)
                        .foregroundStyle(Color.Fairy.slate)
                        .multilineTextAlignment(.center)

                    Button("Open Settings") {
                        if let url = URL(string: UIApplication.openSettingsURLString) {
                            UIApplication.shared.open(url)
                        }
                    }
                    .buttonStyle(PrimaryFairyButtonStyle())
                }
                .padding(Spacing.xl)
            }

            // MARK: - Processing Overlay
            if viewModel.captureState == .processing {
                Color.black.opacity(0.5)
                    .ignoresSafeArea()

                VStack(spacing: Spacing.md) {
                    ProgressView()
                        .tint(Color.Fairy.rose)
                        .scaleEffect(1.5)

                    Text("Processing...")
                        .font(.Fairy.body)
                        .foregroundStyle(.white)
                }
            }
        }
        .background(Color.black)
        .task {
            await viewModel.startScanner()
        }
        .onDisappear {
            viewModel.stopScanner()
        }
    }
}

// MARK: - Top Bar

struct ScannerTopBar: View {
    let isFlashOn: Bool
    let pageCount: Int
    let onFlashToggle: () -> Void
    let onClose: () -> Void

    var body: some View {
        HStack {
            // Flash toggle
            Button(action: onFlashToggle) {
                Image(systemName: isFlashOn ? "bolt.fill" : "bolt.slash.fill")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundStyle(.white)
                    .frame(width: 44, height: 44)
            }

            Spacer()

            // Page count badge
            if pageCount > 0 {
                Text("\(pageCount)")
                    .font(.Fairy.button)
                    .foregroundStyle(.white)
                    .frame(width: 32, height: 32)
                    .background(Color.Fairy.rose, in: Circle())
                    .transition(.fairyScale)
            }

            Spacer()

            // Close button
            Button(action: onClose) {
                Image(systemName: "xmark")
                    .font(.system(size: 16, weight: .bold))
                    .foregroundStyle(.white)
                    .frame(width: 32, height: 32)
                    .background(Color.white.opacity(0.2), in: Circle())
            }
        }
        .padding(.horizontal, Spacing.md)
        .padding(.top, Spacing.xs)
        .background(
            LinearGradient(
                colors: [Color.black.opacity(0.4), Color.clear],
                startPoint: .top,
                endPoint: .bottom
            )
            .frame(height: 80)
            .ignoresSafeArea()
        )
    }
}
