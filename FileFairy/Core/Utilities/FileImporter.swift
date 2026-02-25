// FileImporter.swift
// FileFairy
//
// A SwiftUI ViewModifier that presents UIDocumentPickerViewController for
// importing files from the Files app, iCloud Drive, and third-party providers.
// Supports multiple UTTypes and multi-file selection.
//
// Usage:
//   .fileImporter(isPresented: $showPicker, allowedTypes: [.pdf, .mbox]) { result in
//       switch result {
//       case .success(let urls): // handle urls
//       case .failure(let error): // handle error
//       }
//   }

import SwiftUI
import UIKit
import UniformTypeIdentifiers

// MARK: - FileImporter ViewModifier

struct FileImporterModifier: ViewModifier {

    @Binding var isPresented: Bool
    let allowedTypes: [UTType]
    let allowsMultipleSelection: Bool
    let onCompletion: (Result<[URL], Error>) -> Void

    func body(content: Content) -> some View {
        content
            .background {
                // Using a zero-size background view to host the UIKit presenter
                // keeps the modifier side-effect-free from the SwiftUI layout perspective.
                FileImporterRepresentable(
                    isPresented: $isPresented,
                    allowedTypes: allowedTypes,
                    allowsMultipleSelection: allowsMultipleSelection,
                    onCompletion: onCompletion
                )
                .frame(width: 0, height: 0)
            }
    }
}

// MARK: - UIViewControllerRepresentable

private struct FileImporterRepresentable: UIViewControllerRepresentable {

    @Binding var isPresented: Bool
    let allowedTypes: [UTType]
    let allowsMultipleSelection: Bool
    let onCompletion: (Result<[URL], Error>) -> Void

    func makeUIViewController(context: Context) -> UIViewController {
        // Invisible host controller — the picker is presented modally from here.
        UIViewController()
    }

    func updateUIViewController(_ uiViewController: UIViewController, context: Context) {
        guard isPresented, uiViewController.presentedViewController == nil else { return }

        let picker = UIDocumentPickerViewController(forOpeningContentTypes: allowedTypes)
        picker.allowsMultipleSelection = allowsMultipleSelection
        picker.shouldShowFileExtensions = true
        picker.delegate = context.coordinator

        uiViewController.present(picker, animated: true)
    }

    func makeCoordinator() -> Coordinator {
        Coordinator(parent: self)
    }

    // MARK: - Coordinator

    final class Coordinator: NSObject, UIDocumentPickerDelegate {
        let parent: FileImporterRepresentable

        init(parent: FileImporterRepresentable) {
            self.parent = parent
        }

        func documentPicker(
            _ controller: UIDocumentPickerViewController,
            didPickDocumentsAt urls: [URL]
        ) {
            parent.isPresented = false

            // Start security-scoped access and copy files to a stable temp location
            // before handing them off. The security scope ends when the caller's
            // work with the file is complete.
            let securedURLs: [URL] = urls.compactMap { url in
                guard url.startAccessingSecurityScopedResource() else { return nil }
                defer { url.stopAccessingSecurityScopedResource() }

                // Copy to app's temp directory so the file remains accessible
                // after the security scope ends.
                let tempDest = TempDirectory.shared.url(for: url.lastPathComponent)
                do {
                    if FileManager.default.fileExists(atPath: tempDest.path) {
                        try FileManager.default.removeItem(at: tempDest)
                    }
                    try FileManager.default.copyItem(at: url, to: tempDest)
                    return tempDest
                } catch {
                    return nil
                }
            }

            if securedURLs.isEmpty && !urls.isEmpty {
                parent.onCompletion(.failure(AppError.permissionDenied))
            } else {
                parent.onCompletion(.success(securedURLs))
            }
        }

        func documentPickerWasCancelled(_ controller: UIDocumentPickerViewController) {
            parent.isPresented = false
            // Cancellation is not an error; deliver an empty success.
            parent.onCompletion(.success([]))
        }
    }
}

// MARK: - View Extension

extension View {

    /// Presents a document picker when `isPresented` is true.
    ///
    /// - Parameters:
    ///   - isPresented: Binding that controls picker presentation.
    ///   - allowedTypes: The UTTypes the picker will show. Defaults to all files.
    ///   - allowsMultipleSelection: Whether the user can select multiple files.
    ///   - onCompletion: Called with the result. On success, an array of local file
    ///     URLs copied to the app's temporary directory. On cancellation, an empty array.
    func fileImporter(
        isPresented: Binding<Bool>,
        allowedTypes: [UTType] = [.data],
        allowsMultipleSelection: Bool = false,
        onCompletion: @escaping (Result<[URL], Error>) -> Void
    ) -> some View {
        modifier(FileImporterModifier(
            isPresented: isPresented,
            allowedTypes: allowedTypes,
            allowsMultipleSelection: allowsMultipleSelection,
            onCompletion: onCompletion
        ))
    }
}

// MARK: - Common UTType Groups

extension Array where Element == UTType {
    /// Common types accepted across FileFairy modules.
    static let fairySupported: [UTType] = [
        .pdf,
        .plainText,
        .rtf,
        .jpeg,
        .png,
        .heic,
        UTType(filenameExtension: "mbox") ?? .data,
        UTType(filenameExtension: "docx") ?? .data,
        UTType(filenameExtension: "xlsx") ?? .data,
        UTType(filenameExtension: "pptx") ?? .data
    ]

    /// Types accepted by the MBOX module.
    static let mboxTypes: [UTType] = [
        UTType(filenameExtension: "mbox") ?? .data,
        .emailMessage
    ]

    /// Types accepted by the Converter module.
    static let convertibleTypes: [UTType] = [
        .pdf,
        .jpeg,
        .png,
        .heic,
        .gif,
        .webP,
        .tiff,
        .plainText,
        .rtf,
        UTType(filenameExtension: "docx") ?? .data,
        UTType(filenameExtension: "xlsx") ?? .data,
        UTType(filenameExtension: "pptx") ?? .data
    ]
}
