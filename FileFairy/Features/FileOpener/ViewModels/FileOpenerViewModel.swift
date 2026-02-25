// FileOpenerViewModel.swift
// FileFairy
//
// Manages file importing, QuickLook preview, and recent file tracking.

import SwiftUI
import SwiftData
import QuickLook

@Observable
final class FileOpenerViewModel {

    var selectedFileURL: URL?
    var showPreview: Bool = false
    var showFilePicker: Bool = false
    var errorMessage: String?

    private var modelContext: ModelContext?

    func setContext(_ context: ModelContext) {
        self.modelContext = context
    }

    // MARK: - Open File

    @MainActor
    func openFile(url: URL) {
        // Copy to app's inbox for persistent access
        let inbox = FileManager.default.temporaryDirectory.appendingPathComponent("FileOpener")
        try? FileManager.default.createDirectory(at: inbox, withIntermediateDirectories: true)

        let destURL = inbox.appendingPathComponent(url.lastPathComponent)

        // Remove existing copy
        try? FileManager.default.removeItem(at: destURL)

        do {
            // Start accessing security-scoped resource
            let accessing = url.startAccessingSecurityScopedResource()
            defer {
                if accessing { url.stopAccessingSecurityScopedResource() }
            }

            try FileManager.default.copyItem(at: url, to: destURL)

            selectedFileURL = destURL
            showPreview = true

            // Track in recent files
            trackRecentFile(url: destURL)

            HapticEngine.shared.light()
        } catch {
            errorMessage = "Couldn't open file: \(error.localizedDescription)"
        }
    }

    // MARK: - Track Recent File

    private func trackRecentFile(url: URL) {
        guard let context = modelContext else { return }

        let fileInfo = FileTypeResolver.resolve(url)

        let fileSize: Int64
        if let attrs = try? FileManager.default.attributesOfItem(atPath: url.path),
           let size = attrs[.size] as? Int64 {
            fileSize = size
        } else {
            fileSize = 0
        }

        let recent = RecentFile(
            displayName: url.deletingPathExtension().lastPathComponent,
            filePath: url.path,
            fileType: fileInfo.type,
            sizeBytes: fileSize
        )

        context.insert(recent)
        try? context.save()
    }

    // MARK: - Clear History

    func clearHistory() {
        guard let context = modelContext else { return }
        do {
            try context.delete(model: RecentFile.self)
            try context.save()
        } catch {
            errorMessage = "Couldn't clear history: \(error.localizedDescription)"
        }
    }

    // MARK: - Delete Recent File

    func deleteRecentFile(_ file: RecentFile) {
        guard let context = modelContext else { return }
        context.delete(file)
        try? context.save()
    }
}
