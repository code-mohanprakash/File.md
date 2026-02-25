// OnboardingView.swift
// FileFairy
//
// 5-page full-bleed gradient onboarding flow.
// Each page: gradient bg, frosted glass icon circle, bold white title,
// white subtitle, page dots. Swipe or tap Next/Get Started to progress.

import SwiftUI

// MARK: - OnboardingPage Model

private struct OnboardingPage {
    let assetName: String
    let fallbackSymbol: String
    let title: String
    let subtitle: String
    let gradient: LinearGradient
}

// MARK: - OnboardingView

struct OnboardingView: View {

    @Environment(\.dismiss) private var dismiss
    @Environment(AppEnvironment.self) private var appEnv

    @State private var currentPage = 0
    @State private var dragOffset: CGFloat = 0

    private let pages: [OnboardingPage] = [
        OnboardingPage(
            assetName: "FeatureScanner",
            fallbackSymbol: "camera.viewfinder",
            title: "Scan Any Document",
            subtitle: "Point your camera at any document. FileFairy detects edges automatically and exports as PDF or JPEG.",
            gradient: LinearGradient(
                colors: [Color(hex: "#DB2777"), Color(hex: "#9D174D")],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        ),
        OnboardingPage(
            assetName: "FeatureMbox",
            fallbackSymbol: "envelope.fill",
            title: "Read Email Archives",
            subtitle: "Import .mbox files from Gmail, Apple Mail, or Outlook. Search, filter, and save attachments.",
            gradient: LinearGradient(
                colors: [Color(hex: "#0891B2"), Color(hex: "#164E63")],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        ),
        OnboardingPage(
            assetName: "FeatureConverter",
            fallbackSymbol: "arrow.triangle.2.circlepath",
            title: "Convert Anything",
            subtitle: "HEIC to JPEG, PNG to PDF, compress images, merge and split PDFs — all on device.",
            gradient: LinearGradient(
                colors: [Color(hex: "#D97706"), Color(hex: "#92400E")],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        ),
        OnboardingPage(
            assetName: "FeatureFiles",
            fallbackSymbol: "folder.fill",
            title: "Open Any File",
            subtitle: "Open documents, preview them instantly, and share with any app on your device.",
            gradient: LinearGradient(
                colors: [Color(hex: "#4F46E5"), Color(hex: "#312E81")],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        ),
        OnboardingPage(
            assetName: "FeaturePDF",
            fallbackSymbol: "doc.fill",
            title: "Powerful PDF Tools",
            subtitle: "Merge, split, and compress PDFs without uploading to the cloud. Your files stay private.",
            gradient: LinearGradient(
                colors: [Color(hex: "#059669"), Color(hex: "#064E3B")],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        )
    ]

    // MARK: - Body

    var body: some View {
        ZStack {
            // Background gradient — animates on page change
            pages[currentPage].gradient
                .ignoresSafeArea()
                .animation(.easeInOut(duration: 0.45), value: currentPage)

            VStack(spacing: 0) {
                // Skip button (top-right)
                HStack {
                    Spacer()
                    if currentPage < pages.count - 1 {
                        Button("Skip") {
                            complete()
                        }
                        .font(.system(size: 16, weight: .medium, design: .rounded))
                        .foregroundStyle(.white.opacity(0.8))
                        .padding(.horizontal, Spacing.md)
                        .padding(.top, Spacing.lg)
                    } else {
                        Color.clear.frame(height: 44)
                            .padding(.top, Spacing.lg)
                    }
                }
                .padding(.horizontal, Spacing.sm)

                Spacer()

                // Page content
                TabView(selection: $currentPage) {
                    ForEach(Array(pages.enumerated()), id: \.offset) { index, page in
                        OnboardingPageView(page: page)
                            .tag(index)
                    }
                }
                .tabViewStyle(.page(indexDisplayMode: .never))
                .animation(.easeInOut(duration: 0.35), value: currentPage)

                Spacer()

                // Bottom controls
                VStack(spacing: Spacing.lg) {
                    // Page dots
                    PageDotsView(count: pages.count, current: currentPage)

                    // CTA button
                    if currentPage == pages.count - 1 {
                        OnboardingCTAButton(title: "Get Started", icon: "sparkles") {
                            complete()
                        }
                    } else {
                        OnboardingCTAButton(title: "Next", icon: "arrow.right") {
                            withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                                currentPage += 1
                            }
                        }
                    }
                }
                .padding(.horizontal, Spacing.lg)
                .padding(.bottom, Spacing.xxl)
            }
        }
        .preferredColorScheme(.dark)
    }

    // MARK: - Actions

    private func complete() {
        appEnv.hasCompletedOnboarding = true
        dismiss()
    }
}

// MARK: - OnboardingPageView

private struct OnboardingPageView: View {

    let page: OnboardingPage
    @State private var appeared = false

    var body: some View {
        VStack(spacing: Spacing.xl) {
            // Frosted glass icon circle
            ZStack {
                Circle()
                    .fill(.ultraThinMaterial)
                    .frame(width: 160, height: 160)

                Circle()
                    .strokeBorder(Color.white.opacity(0.3), lineWidth: 1)
                    .frame(width: 160, height: 160)

                Group {
                    if UIImage(named: page.assetName) != nil {
                        Image(page.assetName)
                            .resizable()
                            .scaledToFit()
                            .frame(width: 90, height: 90)
                    } else {
                        Image(systemName: page.fallbackSymbol)
                            .font(.system(size: 56, weight: .semibold))
                            .foregroundStyle(.white)
                    }
                }
            }
            .scaleEffect(appeared ? 1 : 0.7)
            .opacity(appeared ? 1 : 0)

            // Text content
            VStack(spacing: Spacing.sm) {
                Text(page.title)
                    .font(.system(size: 30, weight: .bold, design: .rounded))
                    .foregroundStyle(.white)
                    .multilineTextAlignment(.center)

                Text(page.subtitle)
                    .font(.system(size: 17, weight: .regular, design: .rounded))
                    .foregroundStyle(.white.opacity(0.85))
                    .multilineTextAlignment(.center)
                    .lineSpacing(3)
                    .padding(.horizontal, Spacing.md)
            }
            .opacity(appeared ? 1 : 0)
            .offset(y: appeared ? 0 : 16)
        }
        .padding(.horizontal, Spacing.md)
        .onAppear {
            withAnimation(.spring(response: 0.55, dampingFraction: 0.75).delay(0.1)) {
                appeared = true
            }
        }
        .onDisappear {
            appeared = false
        }
    }
}

// MARK: - PageDotsView

private struct PageDotsView: View {
    let count: Int
    let current: Int

    var body: some View {
        HStack(spacing: Spacing.xs) {
            ForEach(0..<count, id: \.self) { index in
                Capsule()
                    .fill(Color.white.opacity(index == current ? 1.0 : 0.4))
                    .frame(width: index == current ? 24 : 8, height: 8)
                    .animation(.spring(response: 0.35, dampingFraction: 0.75), value: current)
            }
        }
    }
}

// MARK: - OnboardingCTAButton

private struct OnboardingCTAButton: View {
    let title: String
    let icon: String
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: Spacing.xs) {
                Text(title)
                    .font(.system(size: 17, weight: .semibold, design: .rounded))
                Image(systemName: icon)
                    .font(.system(size: 15, weight: .semibold))
            }
            .foregroundStyle(.black.opacity(0.85))
            .frame(maxWidth: .infinity)
            .padding(.vertical, Spacing.md)
            .background(.white, in: Capsule())
        }
        .buttonStyle(.plain)
        .pressScale()
    }
}

// MARK: - Preview

#Preview {
    OnboardingView()
        .environment(AppEnvironment())
}
