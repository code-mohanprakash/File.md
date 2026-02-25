// PaywallView.swift
// FileFairy

import SwiftUI

struct PaywallView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var viewModel = PremiumViewModel()
    @State private var appeared = false

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: Spacing.lg) {
                    // Mascot header
                    mascotHeader
                        .padding(.top, Spacing.lg)

                    // Feature list
                    featureList

                    // Subscription cards
                    subscriptionCards

                    // Purchase button
                    purchaseButton

                    // Restore + Terms
                    footerLinks

                    // Error
                    if let error = viewModel.errorMessage {
                        Text(error)
                            .font(.Fairy.caption)
                            .foregroundStyle(Color.Fairy.rose)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, Spacing.md)
                    }

                    Spacer().frame(height: Spacing.xl)
                }
            }
            .background(
                LinearGradient(
                    colors: [Color.Fairy.dust, Color.Fairy.violet.opacity(0.05)],
                    startPoint: .top,
                    endPoint: .bottom
                )
            )
            .navigationTitle("Go Premium")
            .toolbarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button { dismiss() } label: {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundStyle(Color.Fairy.mist)
                            .font(.system(size: 24))
                    }
                }
            }
            .task { await viewModel.loadProducts() }
            .onAppear {
                withAnimation(.fairyMagic.delay(0.2)) {
                    appeared = true
                }
            }
        }
    }

    // MARK: - Mascot Header

    private var mascotHeader: some View {
        VStack(spacing: Spacing.md) {
            MascotView(mood: .celebrating, size: 100)
                .scaleEffect(appeared ? 1 : 0.5)
                .opacity(appeared ? 1 : 0)

            VStack(spacing: Spacing.xs) {
                Text("Unlock All Tools")
                    .font(.Fairy.display)
                    .foregroundStyle(Color.Fairy.ink)

                Text("Get the full FileFairy experience")
                    .font(.Fairy.subtext)
                    .foregroundStyle(Color.Fairy.mist)
            }
        }
        .frame(maxWidth: .infinity)
    }

    // MARK: - Feature List

    private var featureList: some View {
        VStack(spacing: Spacing.sm) {
            ForEach(Array(PremiumViewModel.features.enumerated()), id: \.offset) { index, feature in
                HStack(spacing: Spacing.md) {
                    ZStack {
                        RoundedRectangle(cornerRadius: CornerRadius.sm, style: .continuous)
                            .fill(Color.Fairy.violet.opacity(0.1))
                            .frame(width: 40, height: 40)

                        Image(systemName: feature.icon)
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundStyle(Color.Fairy.violet)
                    }

                    VStack(alignment: .leading, spacing: 2) {
                        Text(feature.title)
                            .font(.Fairy.body)
                            .foregroundStyle(Color.Fairy.ink)
                        Text(feature.description)
                            .font(.Fairy.micro)
                            .foregroundStyle(Color.Fairy.mist)
                    }

                    Spacer()
                }
                .opacity(appeared ? 1 : 0)
                .offset(x: appeared ? 0 : -20)
                .animation(.fairyGentle.delay(Double(index) * 0.08), value: appeared)
            }
        }
        .padding(.horizontal, Spacing.md)
    }

    // MARK: - Subscription Cards

    private var subscriptionCards: some View {
        VStack(spacing: Spacing.sm) {
            if let annual = viewModel.annualProduct {
                SubscriptionCard(
                    product: annual,
                    isSelected: viewModel.selectedPlan == .annual,
                    badge: viewModel.annualSavingsPercent > 0
                        ? "Save \(viewModel.annualSavingsPercent)%"
                        : nil
                ) {
                    withAnimation(.fairySnappy) {
                        viewModel.selectedPlan = .annual
                    }
                }
            }

            if let monthly = viewModel.monthlyProduct {
                SubscriptionCard(
                    product: monthly,
                    isSelected: viewModel.selectedPlan == .monthly,
                    badge: nil
                ) {
                    withAnimation(.fairySnappy) {
                        viewModel.selectedPlan = .monthly
                    }
                }
            }
        }
        .padding(.horizontal, Spacing.md)
    }

    // MARK: - Purchase Button

    private var purchaseButton: some View {
        FairyButton(
            "Subscribe Now",
            style: .primary,
            color: Color.Fairy.violet,
            isLoading: viewModel.purchaseInProgress
        ) {
            Task { await viewModel.purchase() }
        }
        .disabled(viewModel.purchaseInProgress || viewModel.selectedProduct == nil)
        .padding(.horizontal, Spacing.md)
    }

    // MARK: - Footer

    private var footerLinks: some View {
        VStack(spacing: Spacing.sm) {
            Button("Restore Purchases") {
                Task { await viewModel.restore() }
            }
            .font(.Fairy.caption)
            .foregroundStyle(Color.Fairy.violet)

            HStack(spacing: Spacing.md) {
                Button("Terms of Use") {
                    // Opens terms URL
                }
                .font(.Fairy.micro)
                .foregroundStyle(Color.Fairy.mist)

                Text("•")
                    .foregroundStyle(Color.Fairy.mist)

                Button("Privacy Policy") {
                    // Opens privacy URL
                }
                .font(.Fairy.micro)
                .foregroundStyle(Color.Fairy.mist)
            }

            Text("Cancel anytime. Billed through your Apple ID.")
                .font(.Fairy.micro)
                .foregroundStyle(Color.Fairy.mist)
                .multilineTextAlignment(.center)
        }
    }
}
