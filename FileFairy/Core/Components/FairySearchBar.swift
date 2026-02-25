// FairySearchBar.swift
// FileFairy
//
// Branded search bar with magnifying glass icon, cream background,
// sm corner radius, soft shadow, and an animated cancel button.
//
// The cancel button slides in from the right when the field is focused
// and slides back out on dismiss. Includes selection haptic on focus.

import SwiftUI

// MARK: - FairySearchBar

struct FairySearchBar: View {

    // MARK: Public API

    let placeholder: String
    @Binding var text: String

    /// Set to true to always show the cancel button even when not focused
    var alwaysShowCancel: Bool

    /// Called when the user taps the cancel button (after clearing text + dismissing)
    var onCancel: (() -> Void)?

    /// Called when user submits the search (keyboard return)
    var onSubmit: (() -> Void)?

    // MARK: Private State

    @FocusState private var isFocused: Bool

    private var showCancel: Bool { isFocused || alwaysShowCancel || !text.isEmpty }

    // MARK: Init

    init(
        _ placeholder: String = "Search",
        text: Binding<String>,
        alwaysShowCancel: Bool = false,
        onCancel: (() -> Void)? = nil,
        onSubmit: (() -> Void)? = nil
    ) {
        self.placeholder = placeholder
        self._text = text
        self.alwaysShowCancel = alwaysShowCancel
        self.onCancel = onCancel
        self.onSubmit = onSubmit
    }

    // MARK: Body

    var body: some View {
        HStack(spacing: Spacing.xs) {
            searchField

            if showCancel {
                cancelButton
                    .transition(
                        .asymmetric(
                            insertion: .move(edge: .trailing).combined(with: .opacity),
                            removal: .move(edge: .trailing).combined(with: .opacity)
                        )
                    )
            }
        }
        .animation(.fairySnappy, value: showCancel)
    }

    // MARK: - Subviews

    private var searchField: some View {
        HStack(spacing: Spacing.xs) {
            // Leading magnifying glass
            Image(systemName: "magnifyingglass")
                .font(.system(size: 15, weight: .medium, design: .rounded))
                .foregroundStyle(isFocused ? Color.Fairy.violet : Color.Fairy.mist)
                .animation(.fairySnappy, value: isFocused)

            // Text input
            TextField(placeholder, text: $text)
                .font(.Fairy.body)
                .foregroundStyle(Color.Fairy.ink)
                .tint(Color.Fairy.violet)
                .autocorrectionDisabled()
                .textInputAutocapitalization(.never)
                .focused($isFocused)
                .submitLabel(.search)
                .onSubmit {
                    HapticEngine.shared.light()
                    onSubmit?()
                }
                .onChange(of: isFocused) { _, focused in
                    if focused {
                        HapticEngine.shared.selection()
                    }
                }

            // Clear button — appears when text is non-empty
            if !text.isEmpty {
                Button {
                    withAnimation(.fairySnappy) {
                        text = ""
                    }
                    HapticEngine.shared.soft()
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .font(.system(size: 15, weight: .regular, design: .rounded))
                        .foregroundStyle(Color.Fairy.mist)
                }
                .buttonStyle(.plain)
                .transition(.fairyScale)
            }
        }
        .padding(.horizontal, Spacing.sm)
        .frame(height: 44)
        .background(Color.Fairy.cream)
        .clipShape(RoundedRectangle(cornerRadius: CornerRadius.sm, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: CornerRadius.sm, style: .continuous)
                .strokeBorder(
                    isFocused ? Color.Fairy.lavenderMist : Color.Fairy.softEdge,
                    lineWidth: isFocused ? 1.5 : 1.0
                )
                .animation(.fairySnappy, value: isFocused)
        )
        .fairyShadow(.soft)
        .animation(.fairySnappy, value: text.isEmpty)
    }

    private var cancelButton: some View {
        Button {
            withAnimation(.fairySnappy) {
                text = ""
                isFocused = false
            }
            HapticEngine.shared.soft()
            onCancel?()
        } label: {
            Text("Cancel")
                .fairyText(.subtext)
                .foregroundStyle(Color.Fairy.violet)
        }
        .buttonStyle(.plain)
        .fixedSize()
    }
}

// MARK: - FairySearchBar with Suggestions

/// Extended search bar that shows a dropdown suggestion list below.
struct FairySearchBarWithSuggestions: View {

    let placeholder: String
    @Binding var text: String

    let suggestions: [String]
    let onSuggestionSelected: (String) -> Void
    var onSubmit: (() -> Void)?

    @FocusState private var isFocused: Bool
    private var showSuggestions: Bool {
        isFocused && !suggestions.isEmpty
    }

    var body: some View {
        VStack(spacing: 0) {
            FairySearchBar(
                placeholder,
                text: $text,
                onSubmit: onSubmit
            )

            if showSuggestions {
                suggestionList
                    .transition(.fairySlideUp)
            }
        }
        .animation(.fairySnappy, value: showSuggestions)
    }

    private var suggestionList: some View {
        VStack(alignment: .leading, spacing: 0) {
            ForEach(suggestions, id: \.self) { suggestion in
                Button {
                    HapticEngine.shared.light()
                    text = suggestion
                    isFocused = false
                    onSuggestionSelected(suggestion)
                } label: {
                    HStack(spacing: Spacing.xs) {
                        Image(systemName: "magnifyingglass")
                            .font(.system(size: 13, weight: .regular, design: .rounded))
                            .foregroundStyle(Color.Fairy.mist)

                        Text(suggestion)
                            .fairyText(.body)
                            .foregroundStyle(Color.Fairy.ink)

                        Spacer()

                        Image(systemName: "arrow.up.left")
                            .font(.system(size: 12, weight: .regular, design: .rounded))
                            .foregroundStyle(Color.Fairy.mist)
                    }
                    .padding(.horizontal, Spacing.md)
                    .padding(.vertical, Spacing.sm)
                }
                .buttonStyle(.plain)
                .pressScale(0.98)

                if suggestion != suggestions.last {
                    Divider()
                        .padding(.leading, Spacing.md + 28)
                }
            }
        }
        .background(Color.Fairy.cream)
        .clipShape(RoundedRectangle(cornerRadius: CornerRadius.md, style: .continuous))
        .fairyShadow(.float)
        .padding(.top, Spacing.xxs)
    }
}

// MARK: - Preview

#Preview("FairySearchBar") {
    @Previewable @State var query = ""
    @Previewable @State var query2 = "invoice"

    VStack(spacing: Spacing.lg) {
        // Default
        FairySearchBar("Search files...", text: $query)

        // With text
        FairySearchBar("Search files...", text: $query2) {
            print("cancel")
        }

        // Always show cancel
        FairySearchBar("Search everything", text: $query, alwaysShowCancel: true)
    }
    .padding(Spacing.md)
    .background(Color.Fairy.dust)
}
