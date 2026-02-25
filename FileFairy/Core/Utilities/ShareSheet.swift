// ShareSheet.swift
// FileFairy
//
// Thin SwiftUI wrapper around UIActivityViewController.
// Supports sharing any mix of items (URLs, Data, String, UIImage).
//
// Usage:
//   .shareSheet(isPresented: $showShare, items: [fileURL])

import SwiftUI
import UIKit

// MARK: - ShareSheet ViewModifier

struct ShareSheetModifier: ViewModifier {
    @Binding var isPresented: Bool
    let items: [Any]
    let applicationActivities: [UIActivity]?
    let onDismiss: (() -> Void)?

    func body(content: Content) -> some View {
        content
            .background {
                ShareSheetRepresentable(
                    isPresented: $isPresented,
                    items: items,
                    applicationActivities: applicationActivities,
                    onDismiss: onDismiss
                )
                .frame(width: 0, height: 0)
            }
    }
}

// MARK: - UIViewControllerRepresentable

struct ShareSheetRepresentable: UIViewControllerRepresentable {

    @Binding var isPresented: Bool
    let items: [Any]
    let applicationActivities: [UIActivity]?
    let onDismiss: (() -> Void)?

    func makeUIViewController(context: Context) -> UIViewController {
        UIViewController()
    }

    func updateUIViewController(_ uiViewController: UIViewController, context: Context) {
        guard isPresented, uiViewController.presentedViewController == nil else { return }

        let activityVC = UIActivityViewController(
            activityItems: items,
            applicationActivities: applicationActivities
        )

        activityVC.completionWithItemsHandler = { _, _, _, _ in
            isPresented = false
            onDismiss?()
        }

        // On iPad, UIActivityViewController requires a sourceView or popover anchor.
        if let popover = activityVC.popoverPresentationController {
            popover.sourceView = uiViewController.view
            popover.sourceRect = CGRect(
                x: uiViewController.view.bounds.midX,
                y: uiViewController.view.bounds.midY,
                width: 0,
                height: 0
            )
            popover.permittedArrowDirections = []
        }

        uiViewController.present(activityVC, animated: true)
    }

    func makeCoordinator() -> Coordinator {
        Coordinator()
    }

    final class Coordinator: NSObject {}
}

// MARK: - ShareSheet Standalone View

/// Use as a full-fledged view when you need to embed the share sheet trigger
/// directly in a view hierarchy rather than as a modifier.
struct ShareSheet: View {
    let items: [Any]
    let applicationActivities: [UIActivity]?

    init(items: [Any], applicationActivities: [UIActivity]? = nil) {
        self.items = items
        self.applicationActivities = applicationActivities
    }

    var body: some View {
        ShareSheetRepresentable(
            isPresented: .constant(true),
            items: items,
            applicationActivities: applicationActivities,
            onDismiss: nil
        )
        .frame(width: 0, height: 0)
    }
}

// MARK: - View Extension

extension View {

    /// Presents a share sheet when `isPresented` is true.
    ///
    /// - Parameters:
    ///   - isPresented: Controls presentation.
    ///   - items: Objects to share (URLs, Data, String, UIImage, etc.).
    ///   - applicationActivities: Optional custom UIActivity instances.
    ///   - onDismiss: Called when the share sheet is dismissed.
    func shareSheet(
        isPresented: Binding<Bool>,
        items: [Any],
        applicationActivities: [UIActivity]? = nil,
        onDismiss: (() -> Void)? = nil
    ) -> some View {
        modifier(ShareSheetModifier(
            isPresented: isPresented,
            items: items,
            applicationActivities: applicationActivities,
            onDismiss: onDismiss
        ))
    }
}
