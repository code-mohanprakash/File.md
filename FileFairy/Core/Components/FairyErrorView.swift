// FairyErrorView.swift
// FileFairy
//
// Soft-red themed inline error state with a shake entrance animation.
// Displays an error icon, title, descriptive message, and a retry CTA.
//
// Design spec:
//   - xmark.circle.fill icon, softRed tint
//   - Title: .headline, ink
//   - Message: .subtext, slate, multi-line
//   - Retry: primary FairyButton (violet)
//   - Entrance: horizontal shake (ShakeEffect) then settles

import SwiftUI

// MARK: - FairyErrorView

struct FairyErrorView: View {

    // MARK: Public API

    let title: String
    let message: String
    var retryTitle: String
    var retryIcon: String
    var onRetry: (() -> Void)?

    // MARK: Private State

    @State private var shakeAmount: CGFloat = 0
    @State private var appeared = false

    // MARK: Init

    init(
        title: String = "Something Went Wrong",
        message: String,
        retryTitle: String = "Try Again",
        retryIcon: String = "arrow.clockwise",
        onRetry: (() -> Void)? = nil
    ) {
        self.title = title
        self.message = message
        self.retryTitle = retryTitle
        self.retryIcon = retryIcon
        self.onRetry = onRetry
    }

    // MARK: Body

    var body: some View {
        VStack(spacing: 0) {
            Spacer(minLength: Spacing.xl)

            // Error icon
            errorIcon
                .modifier(ShakeEffect(animatableData: shakeAmount))

            Spacer().frame(height: Spacing.lg)

            // Title
            Text(title)
                .fairyText(.headline)
                .foregroundStyle(Color.Fairy.ink)
                .multilineTextAlignment(.center)
                .opacity(appeared ? 1 : 0)
                .offset(y: appeared ? 0 : 8)

            Spacer().frame(height: Spacing.xs)

            // Message
            Text(message)
                .fairyText(.subtext)
                .foregroundStyle(Color.Fairy.slate)
                .multilineTextAlignment(.center)
                .padding(.horizontal, Spacing.xl)
                .opacity(appeared ? 1 : 0)
                .offset(y: appeared ? 0 : 6)

            Spacer().frame(height: Spacing.xl)

            // Retry button
            if let onRetry {
                FairyButton(retryTitle, icon: retryIcon, style: .primary, action: {
                    triggerShake()
                    onRetry()
                })
                .frame(maxWidth: 260)
                .opacity(appeared ? 1 : 0)
                .scaleEffect(appeared ? 1 : 0.9)
            }

            Spacer(minLength: Spacing.xl)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .onAppear {
            triggerEntrance()
        }
    }

    // MARK: - Subviews

    private var errorIcon: some View {
        ZStack {
            // Outer halo
            Circle()
                .fill(Color.Fairy.softRed.opacity(0.06))
                .frame(width: 120, height: 120)

            // Inner background
            Circle()
                .fill(
                    LinearGradient(
                        colors: [
                            Color.Fairy.softRed.opacity(0.15),
                            Color.Fairy.softRed.opacity(0.08)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .frame(width: 92, height: 92)

            // xmark.circle.fill icon
            Image(systemName: "xmark.circle.fill")
                .font(.system(size: 40, weight: .regular, design: .rounded))
                .foregroundStyle(Color.Fairy.softRed)
                .symbolRenderingMode(.hierarchical)
        }
        .scaleEffect(appeared ? 1 : 0.5)
        .opacity(appeared ? 1 : 0)
    }

    // MARK: - Animations

    private func triggerEntrance() {
        // Icon bounces in
        withAnimation(.fairyCelebrate) {
            appeared = true
        }

        // Shake plays after a short delay
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
            withAnimation(.fairyShake) {
                shakeAmount = 1
            }
            HapticEngine.shared.error()
            SoundPlayer.shared.play(.error)
        }
    }

    /// Re-triggers the shake (on retry tap)
    private func triggerShake() {
        shakeAmount = 0
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) {
            withAnimation(.fairyShake) {
                shakeAmount = 1
            }
            HapticEngine.shared.error()
        }
    }
}

// MARK: - Inline Error Banner

/// Compact error message banner for use inside forms or below input fields.
struct FairyErrorBanner: View {

    let message: String
    var onDismiss: (() -> Void)?

    @State private var shakeAmount: CGFloat = 0
    @State private var visible = false

    var body: some View {
        HStack(spacing: Spacing.xs) {
            Image(systemName: "exclamationmark.circle.fill")
                .font(.system(size: 14, weight: .medium, design: .rounded))
                .foregroundStyle(Color.Fairy.softRed)

            Text(message)
                .font(.Fairy.caption)
                .foregroundStyle(Color.Fairy.softRed)
                .fixedSize(horizontal: false, vertical: true)

            Spacer()

            if let onDismiss {
                Button(action: {
                    withAnimation(.fairyDismiss) { visible = false }
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                        onDismiss()
                    }
                }) {
                    Image(systemName: "xmark")
                        .font(.system(size: 11, weight: .medium))
                        .foregroundStyle(Color.Fairy.softRed.opacity(0.6))
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.horizontal, Spacing.sm)
        .padding(.vertical, Spacing.xs)
        .background(
            RoundedRectangle(cornerRadius: CornerRadius.sm, style: .continuous)
                .fill(Color.Fairy.softRed.opacity(0.08))
                .overlay(
                    RoundedRectangle(cornerRadius: CornerRadius.sm, style: .continuous)
                        .strokeBorder(Color.Fairy.softRed.opacity(0.2), lineWidth: 1)
                )
        )
        .modifier(ShakeEffect(animatableData: shakeAmount))
        .opacity(visible ? 1 : 0)
        .offset(y: visible ? 0 : -4)
        .onAppear {
            withAnimation(.fairySnappy) { visible = true }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                withAnimation(.fairyShake) { shakeAmount = 1 }
                HapticEngine.shared.error()
            }
        }
    }
}

// MARK: - Error Config Presets

struct ErrorConfig {
    let title: String
    let message: String
    let retryTitle: String
    let retryIcon: String

    static let network = ErrorConfig(
        title: "Connection Lost",
        message: "Check your internet connection and try again.",
        retryTitle: "Retry",
        retryIcon: "wifi"
    )

    static let fileNotFound = ErrorConfig(
        title: "File Not Found",
        message: "This file may have been moved or deleted from Files.",
        retryTitle: "Browse Files",
        retryIcon: "folder"
    )

    static let conversionFailed = ErrorConfig(
        title: "Conversion Failed",
        message: "This file format may not be supported. Try a different file.",
        retryTitle: "Try Again",
        retryIcon: "arrow.clockwise"
    )

    static let permissionDenied = ErrorConfig(
        title: "Permission Required",
        message: "FileFairy needs access to your camera to scan documents.",
        retryTitle: "Open Settings",
        retryIcon: "gear"
    )
}

// MARK: - Preview

#Preview("FairyErrorView") {
    TabView {
        FairyErrorView(
            title: "Connection Lost",
            message: "Check your internet connection and try again.",
            onRetry: { print("retry") }
        )
        .tabItem { Label("Network", systemImage: "wifi.slash") }

        FairyErrorView(
            title: "Conversion Failed",
            message: "This file format is not supported. Please try a different file.",
            retryTitle: "Choose File",
            retryIcon: "folder",
            onRetry: { print("pick file") }
        )
        .tabItem { Label("Convert", systemImage: "exclamationmark.triangle") }

        VStack(spacing: Spacing.md) {
            FairyErrorBanner(message: "Invalid email address", onDismiss: {})
            FairyErrorBanner(message: "Password must be at least 8 characters")
        }
        .padding()
        .background(Color.Fairy.dust)
        .tabItem { Label("Inline", systemImage: "text.badge.xmark") }
    }
    .background(Color.Fairy.dust)
}
