// FairySheet.swift
// FileFairy
//
// Custom bottom sheet with a drag handle, branded header area,
// cream background, and XL top corner radius.
//
// Supports three detent heights via a FairySheetDetent enum.
// Drag gesture on the handle (and anywhere on the header) dismisses or
// snaps between detents. Tap the scrim to dismiss.
//
// Design spec:
//   - Cream background
//   - Corner radius XL (32pt) on top corners only
//   - Drag handle: 36x4 mist-colored pill, centered at top
//   - Optional title + subtitle header
//   - Float shadow
//   - Entrance: .fairySheet transition

import SwiftUI

// MARK: - Sheet Detent

enum FairySheetDetent {
    case small    // ~35% screen height
    case medium   // ~55% screen height
    case large    // ~90% screen height

    func height(in geometry: GeometryProxy) -> CGFloat {
        let total = geometry.size.height + geometry.safeAreaInsets.bottom
        switch self {
        case .small:  return total * 0.35
        case .medium: return total * 0.55
        case .large:  return total * 0.90
        }
    }
}

// MARK: - FairySheet (Overlay Presentation)

/// Custom bottom sheet overlay. Present using a `ZStack` at the root
/// of a screen and bind `isPresented` to show/hide.
///
/// Usage:
/// ```swift
/// FairySheet(
///     isPresented: $showSheet,
///     detent: .medium,
///     title: "Choose Format"
/// ) {
///     FormatPickerView()
/// }
/// ```
struct FairySheet<SheetContent: View>: View {

    // MARK: Public

    @Binding var isPresented: Bool
    let detent: FairySheetDetent
    var title: String?
    var subtitle: String?
    var showCloseButton: Bool
    @ViewBuilder var sheetContent: () -> SheetContent

    // MARK: Private

    @State private var dragOffset: CGFloat = 0
    @State private var appeared = false

    // MARK: Init

    init(
        isPresented: Binding<Bool>,
        detent: FairySheetDetent = .medium,
        title: String? = nil,
        subtitle: String? = nil,
        showCloseButton: Bool = true,
        @ViewBuilder content: @escaping () -> SheetContent
    ) {
        self._isPresented = isPresented
        self.detent = detent
        self.title = title
        self.subtitle = subtitle
        self.showCloseButton = showCloseButton
        self.sheetContent = content
    }

    // MARK: Body

    var body: some View {
        GeometryReader { geo in
            ZStack(alignment: .bottom) {
                // Scrim
                if isPresented {
                    Color.black
                        .opacity(0.32)
                        .ignoresSafeArea()
                        .onTapGesture { dismiss() }
                        .transition(.opacity)
                }

                // Sheet panel
                if isPresented {
                    sheetPanel(geometry: geo)
                        .transition(.fairySheet)
                }
            }
            .animation(.fairyGentle, value: isPresented)
        }
        .ignoresSafeArea()
    }

    // MARK: - Sheet Panel

    @ViewBuilder
    private func sheetPanel(geometry: GeometryProxy) -> some View {
        VStack(spacing: 0) {
            // Drag handle
            dragHandle

            // Header (title + optional close button)
            if title != nil || showCloseButton {
                sheetHeader
            }

            // Content
            sheetContent()
                .frame(maxWidth: .infinity)
        }
        .frame(
            width: geometry.size.width,
            height: detent.height(in: geometry) + abs(min(dragOffset, 0))
        )
        .background(Color.Fairy.cream)
        .clipShape(
            UnevenRoundedRectangle(
                topLeadingRadius: CornerRadius.xl,
                bottomLeadingRadius: 0,
                bottomTrailingRadius: 0,
                topTrailingRadius: CornerRadius.xl,
                style: .continuous
            )
        )
        .fairyShadow(.float)
        .offset(y: max(dragOffset, 0))
        .gesture(dragGesture(geometry: geometry))
    }

    // MARK: - Drag Handle

    private var dragHandle: some View {
        VStack(spacing: 0) {
            Capsule()
                .fill(Color.Fairy.mist.opacity(0.5))
                .frame(width: 36, height: 4)
                .padding(.top, Spacing.sm)
                .padding(.bottom, Spacing.xs)
        }
        .frame(maxWidth: .infinity)
        .contentShape(Rectangle())
    }

    // MARK: - Sheet Header

    private var sheetHeader: some View {
        HStack(alignment: title != nil ? .top : .center) {
            VStack(alignment: .leading, spacing: Spacing.xxxs) {
                if let title {
                    Text(title)
                        .fairyText(.headline)
                        .foregroundStyle(Color.Fairy.ink)
                }
                if let subtitle {
                    Text(subtitle)
                        .fairyText(.caption)
                        .foregroundStyle(Color.Fairy.mist)
                }
            }

            Spacer()

            if showCloseButton {
                FairyIconButton(
                    systemName: "xmark",
                    color: .Fairy.mist,
                    size: 32,
                    action: dismiss
                )
            }
        }
        .padding(.horizontal, Spacing.md)
        .padding(.bottom, Spacing.sm)
    }

    // MARK: - Drag Gesture

    private func dragGesture(geometry: GeometryProxy) -> some Gesture {
        DragGesture(minimumDistance: 8)
            .onChanged { value in
                dragOffset = value.translation.height
            }
            .onEnded { value in
                let threshold = detent.height(in: geometry) * 0.35
                if value.translation.height > threshold {
                    dismiss()
                } else {
                    withAnimation(.fairyBounce) {
                        dragOffset = 0
                    }
                }
            }
    }

    // MARK: - Dismiss

    private func dismiss() {
        withAnimation(.fairyGentle) {
            dragOffset = 0
            isPresented = false
        }
        HapticEngine.shared.soft()
    }
}

// MARK: - FairySheet ViewModifier

/// Presents a FairySheet from any view.
///
/// Usage:
/// ```swift
/// ContentView()
///     .fairySheet(isPresented: $showSheet, title: "Options") {
///         OptionsListView()
///     }
/// ```
struct FairySheetModifier<SheetContent: View>: ViewModifier {

    @Binding var isPresented: Bool
    let detent: FairySheetDetent
    let title: String?
    let subtitle: String?
    let showCloseButton: Bool
    @ViewBuilder var sheetContent: () -> SheetContent

    func body(content: Content) -> some View {
        ZStack {
            content

            FairySheet(
                isPresented: $isPresented,
                detent: detent,
                title: title,
                subtitle: subtitle,
                showCloseButton: showCloseButton,
                content: sheetContent
            )
        }
    }
}

extension View {
    func fairySheet<SheetContent: View>(
        isPresented: Binding<Bool>,
        detent: FairySheetDetent = .medium,
        title: String? = nil,
        subtitle: String? = nil,
        showCloseButton: Bool = true,
        @ViewBuilder content: @escaping () -> SheetContent
    ) -> some View {
        modifier(FairySheetModifier(
            isPresented: isPresented,
            detent: detent,
            title: title,
            subtitle: subtitle,
            showCloseButton: showCloseButton,
            sheetContent: content
        ))
    }
}

// MARK: - Preview

#Preview("FairySheet") {
    @Previewable @State var showSmall = false
    @Previewable @State var showMedium = false
    @Previewable @State var showLarge = false

    ZStack {
        Color.Fairy.dust.ignoresSafeArea()

        VStack(spacing: Spacing.md) {
            Text("Bottom Sheet Demo")
                .fairyText(.title)

            FairyButton("Small Sheet", style: .secondary) { showSmall = true }
            FairyButton("Medium Sheet", style: .primary) { showMedium = true }
            FairyButton("Large Sheet", style: .ghost) { showLarge = true }
        }
        .padding(Spacing.md)

        FairySheet(
            isPresented: $showSmall,
            detent: .small,
            title: "Quick Actions",
            subtitle: "Choose an action for this file"
        ) {
            VStack(spacing: Spacing.sm) {
                ForEach(["Share", "Rename", "Duplicate", "Delete"], id: \.self) { action in
                    Button(action) {}
                        .fairyText(.body)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.horizontal, Spacing.md)
                }
            }
            .padding(.bottom, Spacing.xxl)
        }

        FairySheet(
            isPresented: $showMedium,
            detent: .medium,
            title: "Export Options"
        ) {
            VStack(spacing: Spacing.md) {
                FairyButton("Export as PDF", icon: "doc.richtext", style: .primary) {}
                FairyButton("Export as DOCX", icon: "doc.text", style: .secondary) {}
                FairyButton("Share", icon: "square.and.arrow.up", style: .ghost) {}
            }
            .padding(.horizontal, Spacing.md)
            .padding(.bottom, Spacing.xxl)
        }

        FairySheet(
            isPresented: $showLarge,
            detent: .large,
            title: "File Details",
            subtitle: "Annual Report 2024.pdf"
        ) {
            ScrollView {
                VStack(spacing: Spacing.md) {
                    ForEach(0..<12) { i in
                        RoundedRectangle.fairyMedium
                            .fill(Color.Fairy.lavenderMist.opacity(0.2))
                            .frame(height: 44)
                    }
                }
                .padding(Spacing.md)
            }
        }
    }
}
