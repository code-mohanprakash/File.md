// FilterPickerView.swift
// FileFairy
//
// Horizontal filter carousel with 4 filter pills.
// From PRD: Colour, Grey, B&W, Photo. Selected = filled pink, others = outline.

import SwiftUI

struct FilterPickerView: View {

    @Binding var selectedFilter: ImageFilterService.FilterPreset

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: Spacing.xs) {
                ForEach(ImageFilterService.FilterPreset.allCases) { preset in
                    FilterPill(
                        title: preset.rawValue,
                        isSelected: selectedFilter == preset
                    ) {
                        withAnimation(.fairySnappy) {
                            selectedFilter = preset
                        }
                        HapticEngine.shared.selection()
                    }
                }
            }
            .padding(.horizontal, Spacing.md)
        }
    }
}

struct FilterPill: View {

    let title: String
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.Fairy.subtext)
                .foregroundStyle(isSelected ? .white : Color.Fairy.rose)
                .padding(.horizontal, Spacing.md)
                .padding(.vertical, Spacing.xs)
                .background(
                    isSelected
                        ? AnyShapeStyle(Color.Fairy.rose)
                        : AnyShapeStyle(Color.clear)
                )
                .clipShape(.capsule)
                .overlay(
                    Capsule()
                        .stroke(Color.Fairy.rose.opacity(isSelected ? 0 : 0.5), lineWidth: 1.5)
                )
        }
        .buttonStyle(.plain)
    }
}

#Preview {
    FilterPickerView(selectedFilter: .constant(.colour))
        .padding()
        .background(Color.black.opacity(0.5))
}
