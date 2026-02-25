// SubscriptionCard.swift
// FileFairy

import SwiftUI
import StoreKit

struct SubscriptionCard: View {
    let product: Product
    let isSelected: Bool
    let badge: String?
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: Spacing.md) {
                // Radio indicator
                ZStack {
                    Circle()
                        .stroke(
                            isSelected ? Color.Fairy.violet : Color.Fairy.mist.opacity(0.4),
                            lineWidth: 2
                        )
                        .frame(width: 24, height: 24)

                    if isSelected {
                        Circle()
                            .fill(Color.Fairy.violet)
                            .frame(width: 14, height: 14)
                            .transition(.scale)
                    }
                }

                // Plan details
                VStack(alignment: .leading, spacing: 2) {
                    HStack(spacing: Spacing.sm) {
                        Text(planName)
                            .font(.Fairy.body)
                            .fontWeight(.semibold)
                            .foregroundStyle(Color.Fairy.ink)

                        if let badge {
                            Text(badge)
                                .font(.Fairy.micro)
                                .fontWeight(.bold)
                                .foregroundStyle(.white)
                                .padding(.horizontal, Spacing.xs)
                                .padding(.vertical, 2)
                                .background(Color.Fairy.green, in: Capsule())
                        }
                    }

                    Text(product.description)
                        .font(.Fairy.micro)
                        .foregroundStyle(Color.Fairy.mist)
                        .lineLimit(1)
                }

                Spacer()

                // Price
                VStack(alignment: .trailing, spacing: 2) {
                    Text(product.displayPrice)
                        .font(.Fairy.headline)
                        .foregroundStyle(Color.Fairy.ink)

                    Text(periodLabel)
                        .font(.Fairy.micro)
                        .foregroundStyle(Color.Fairy.mist)
                }
            }
            .padding(Spacing.md)
            .background(
                isSelected
                    ? Color.Fairy.violet.opacity(0.06)
                    : Color.Fairy.cream,
                in: RoundedRectangle.fairyLarge
            )
            .overlay(
                RoundedRectangle(cornerRadius: CornerRadius.lg, style: .continuous)
                    .strokeBorder(
                        isSelected ? Color.Fairy.violet : Color.clear,
                        lineWidth: 2
                    )
            )
        }
        .buttonStyle(.plain)
        .pressScale(0.98)
    }

    // MARK: - Computed

    private var planName: String {
        if product.id.contains("annual") {
            return "Annual"
        } else {
            return "Monthly"
        }
    }

    private var periodLabel: String {
        if product.id.contains("annual") {
            return "per year"
        } else {
            return "per month"
        }
    }
}
