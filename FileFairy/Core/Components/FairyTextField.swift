// FairyTextField.swift
// FileFairy
//
// Custom branded text field with animated floating label, focus-state border,
// optional SF Symbol leading icon, and a clear button.
//
// Design spec:
//   - Floating label animates up + shrinks on focus or when text is present
//   - Violet border (1.5pt) when focused; mist border (1pt) at rest
//   - Cream background, lg corner radius (24pt)
//   - Leading icon tinted violet when focused, mist at rest
//   - Clear button appears when text is non-empty

import SwiftUI

// MARK: - FairyTextField

struct FairyTextField: View {

    // MARK: Public API

    let label: String
    let systemIcon: String?
    let keyboardType: UIKeyboardType
    let textContentType: UITextContentType?
    let isSecure: Bool
    var autocapitalization: TextInputAutocapitalization

    @Binding var text: String

    // MARK: Private State

    @FocusState private var isFocused: Bool
    @State private var showSecureText = false

    // MARK: Computed

    private var isFloating: Bool { isFocused || !text.isEmpty }
    private var borderColor: Color { isFocused ? .Fairy.violet : .Fairy.mist }
    private var borderWidth: CGFloat { isFocused ? 1.5 : 1.0 }
    private var iconColor: Color { isFocused ? .Fairy.violet : .Fairy.mist }

    // MARK: Init

    init(
        _ label: String,
        text: Binding<String>,
        systemIcon: String? = nil,
        keyboardType: UIKeyboardType = .default,
        textContentType: UITextContentType? = nil,
        isSecure: Bool = false,
        autocapitalization: TextInputAutocapitalization = .sentences
    ) {
        self.label = label
        self._text = text
        self.systemIcon = systemIcon
        self.keyboardType = keyboardType
        self.textContentType = textContentType
        self.isSecure = isSecure
        self.autocapitalization = autocapitalization
    }

    // MARK: Body

    var body: some View {
        ZStack(alignment: .leading) {
            // Card background + border
            RoundedRectangle(cornerRadius: CornerRadius.lg, style: .continuous)
                .fill(Color.Fairy.cream)
                .overlay(
                    RoundedRectangle(cornerRadius: CornerRadius.lg, style: .continuous)
                        .strokeBorder(borderColor, lineWidth: borderWidth)
                )
                .fairyShadow(isFocused ? .glow : .soft)
                .animation(.fairySnappy, value: isFocused)

            HStack(spacing: 0) {
                // Leading icon
                if let icon = systemIcon {
                    Image(systemName: icon)
                        .font(.system(size: 16, weight: .medium, design: .rounded))
                        .foregroundStyle(iconColor)
                        .frame(width: 44)
                        .animation(.fairySnappy, value: isFocused)
                }

                // Text input area
                ZStack(alignment: .leading) {
                    // Floating label
                    floatingLabel

                    // Input field
                    inputField
                        .padding(.top, isFloating ? 14 : 0)
                }
                .padding(.leading, systemIcon == nil ? Spacing.md : 0)

                // Clear button
                if !text.isEmpty {
                    clearButton
                        .padding(.trailing, Spacing.xs)
                        .transition(.fairyScale)
                }

                // Secure toggle (for password fields)
                if isSecure {
                    secureToggleButton
                        .padding(.trailing, Spacing.xs)
                }
            }
        }
        .frame(height: 56)
        .onTapGesture {
            isFocused = true
        }
    }

    // MARK: - Subviews

    private var floatingLabel: some View {
        Text(label)
            .font(isFloating ? .system(size: 11, weight: .medium, design: .rounded) : .Fairy.body)
            .foregroundStyle(isFloating ? Color.Fairy.violet : Color.Fairy.mist)
            .offset(y: isFloating ? -11 : 0)
            .scaleEffect(isFloating ? 1.0 : 1.0, anchor: .leading)
            .animation(.fairySnappy, value: isFloating)
            .allowsHitTesting(false)
    }

    @ViewBuilder
    private var inputField: some View {
        if isSecure && !showSecureText {
            SecureField("", text: $text)
                .font(.Fairy.body)
                .foregroundStyle(Color.Fairy.ink)
                .tint(Color.Fairy.violet)
                .keyboardType(keyboardType)
                .textContentType(textContentType)
                .autocorrectionDisabled()
                .textInputAutocapitalization(.never)
                .focused($isFocused)
                .onChange(of: isFocused) { _, focused in
                    if focused { HapticEngine.shared.selection() }
                }
        } else {
            TextField("", text: $text)
                .font(.Fairy.body)
                .foregroundStyle(Color.Fairy.ink)
                .tint(Color.Fairy.violet)
                .keyboardType(keyboardType)
                .textContentType(textContentType)
                .textInputAutocapitalization(autocapitalization)
                .focused($isFocused)
                .onChange(of: isFocused) { _, focused in
                    if focused { HapticEngine.shared.selection() }
                }
        }
    }

    private var clearButton: some View {
        Button {
            withAnimation(.fairySnappy) {
                text = ""
            }
            HapticEngine.shared.soft()
        } label: {
            Image(systemName: "xmark.circle.fill")
                .font(.system(size: 16, weight: .regular, design: .rounded))
                .foregroundStyle(Color.Fairy.mist)
        }
        .buttonStyle(.plain)
    }

    private var secureToggleButton: some View {
        Button {
            showSecureText.toggle()
            HapticEngine.shared.soft()
        } label: {
            Image(systemName: showSecureText ? "eye.slash" : "eye")
                .font(.system(size: 16, weight: .regular, design: .rounded))
                .foregroundStyle(iconColor)
                .animation(.fairySnappy, value: showSecureText)
        }
        .buttonStyle(.plain)
        .padding(.trailing, Spacing.xs)
    }
}

// MARK: - FairyTextField with External Focus Binding

/// Variant that exposes focus binding for programmatic control
struct FairyTextFieldFocusable<FocusField: Hashable>: View {

    let label: String
    let systemIcon: String?
    let field: FocusField

    @Binding var text: String
    @FocusState.Binding var focusedField: FocusField?

    private var isFocused: Bool { focusedField == field }
    private var isFloating: Bool { isFocused || !text.isEmpty }
    private var borderColor: Color { isFocused ? .Fairy.violet : .Fairy.mist }
    private var borderWidth: CGFloat { isFocused ? 1.5 : 1.0 }

    var body: some View {
        ZStack(alignment: .leading) {
            RoundedRectangle(cornerRadius: CornerRadius.lg, style: .continuous)
                .fill(Color.Fairy.cream)
                .overlay(
                    RoundedRectangle(cornerRadius: CornerRadius.lg, style: .continuous)
                        .strokeBorder(borderColor, lineWidth: borderWidth)
                )
                .fairyShadow(isFocused ? .glow : .soft)
                .animation(.fairySnappy, value: isFocused)

            HStack(spacing: 0) {
                if let icon = systemIcon {
                    Image(systemName: icon)
                        .font(.system(size: 16, weight: .medium, design: .rounded))
                        .foregroundStyle(isFocused ? Color.Fairy.violet : Color.Fairy.mist)
                        .frame(width: 44)
                        .animation(.fairySnappy, value: isFocused)
                }

                ZStack(alignment: .leading) {
                    Text(label)
                        .font(isFloating ? .system(size: 11, weight: .medium, design: .rounded) : .Fairy.body)
                        .foregroundStyle(isFloating ? Color.Fairy.violet : Color.Fairy.mist)
                        .offset(y: isFloating ? -11 : 0)
                        .animation(.fairySnappy, value: isFloating)
                        .allowsHitTesting(false)

                    TextField("", text: $text)
                        .font(.Fairy.body)
                        .foregroundStyle(Color.Fairy.ink)
                        .tint(Color.Fairy.violet)
                        .padding(.top, isFloating ? 14 : 0)
                        .focused($focusedField, equals: field)
                }
                .padding(.leading, systemIcon == nil ? Spacing.md : 0)

                if !text.isEmpty {
                    Button {
                        withAnimation(.fairySnappy) { text = "" }
                        HapticEngine.shared.soft()
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .font(.system(size: 16, weight: .regular))
                            .foregroundStyle(Color.Fairy.mist)
                    }
                    .buttonStyle(.plain)
                    .padding(.trailing, Spacing.xs)
                    .transition(.fairyScale)
                }
            }
        }
        .frame(height: 56)
        .animation(.fairySnappy, value: text.isEmpty)
    }
}

// MARK: - Preview

#Preview("FairyTextField") {
    @Previewable @State var email = ""
    @Previewable @State var password = ""
    @Previewable @State var notes = "Some notes here"

    ScrollView {
        VStack(spacing: Spacing.md) {
            FairyTextField(
                "Email Address",
                text: $email,
                systemIcon: "envelope",
                keyboardType: .emailAddress,
                textContentType: .emailAddress,
                autocapitalization: .never
            )

            FairyTextField(
                "Password",
                text: $password,
                systemIcon: "lock",
                textContentType: .password,
                isSecure: true
            )

            FairyTextField(
                "Notes",
                text: $notes,
                systemIcon: "pencil"
            )

            FairyTextField(
                "No icon field",
                text: $email
            )
        }
        .padding(Spacing.md)
    }
    .background(Color.Fairy.dust)
}
