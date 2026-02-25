// ConverterHubView.swift
// FileFairy

import SwiftUI
import SwiftData

struct ConverterHubView: View {
    @Environment(AppEnvironment.self) private var appEnv
    @State private var viewModel = ConverterHubViewModel()

    var body: some View {
        ScrollView {
            VStack(spacing: Spacing.lg) {
                // Search
                FairySearchBar("Search tools...", text: $viewModel.searchText)
                    .padding(.horizontal, Spacing.md)

                // Category filter chips
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: Spacing.sm) {
                        categoryChip(nil, label: "All")
                        ForEach(ConversionCategory.allCases, id: \.rawValue) { category in
                            categoryChip(category, label: category.rawValue)
                        }
                    }
                    .padding(.horizontal, Spacing.md)
                }

                // Tool grid
                ForEach(viewModel.groupedTypes, id: \.category) { group in
                    VStack(alignment: .leading, spacing: Spacing.sm) {
                        Text(group.category.rawValue)
                            .font(.Fairy.headline)
                            .foregroundStyle(Color.Fairy.ink)
                            .padding(.horizontal, Spacing.md)

                        LazyVGrid(
                            columns: [GridItem(.flexible()), GridItem(.flexible())],
                            spacing: Spacing.sm
                        ) {
                            ForEach(group.types) { type in
                                NavigationLink(value: type) {
                                    toolCard(type)
                                }
                                .buttonStyle(.plain)
                            }
                        }
                        .padding(.horizontal, Spacing.md)
                    }
                }

                Spacer().frame(height: 100)
            }
            .padding(.top, Spacing.sm)
        }
        .background(Color.Fairy.dust)
    }

    // MARK: - Subviews

    private func categoryChip(_ category: ConversionCategory?, label: String) -> some View {
        let isSelected = viewModel.selectedCategory == category
        return Button {
            viewModel.selectCategory(category)
        } label: {
            Text(label)
                .font(.Fairy.caption)
                .fontWeight(isSelected ? .semibold : .regular)
                .foregroundStyle(isSelected ? .white : Color.Fairy.ink)
                .padding(.horizontal, Spacing.md)
                .padding(.vertical, Spacing.xs)
                .background(
                    isSelected ? Color.Fairy.amber : Color.Fairy.cream,
                    in: Capsule()
                )
        }
        .buttonStyle(.plain)
    }

    private func toolCard(_ type: ConversionType) -> some View {
        VStack(spacing: Spacing.sm) {
            ZStack {
                RoundedRectangle(cornerRadius: CornerRadius.md, style: .continuous)
                    .fill(type.featureColor.opacity(0.1))
                    .frame(width: 48, height: 48)

                Image(systemName: type.icon)
                    .font(.system(size: 20, weight: .semibold))
                    .foregroundStyle(type.featureColor)
            }

            VStack(spacing: 2) {
                Text(type.displayName)
                    .font(.Fairy.body)
                    .foregroundStyle(Color.Fairy.ink)
                    .lineLimit(1)

                Text(type.subtitle)
                    .font(.Fairy.micro)
                    .foregroundStyle(Color.Fairy.mist)
                    .lineLimit(1)
            }

            // No PRO badge — all features are free
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, Spacing.md)
        .background(Color.Fairy.cream, in: RoundedRectangle.fairyLarge)
        .fairyShadow(.soft)
        .pressScale()
    }
}
