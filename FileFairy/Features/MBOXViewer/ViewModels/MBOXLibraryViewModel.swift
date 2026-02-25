// MBOXLibraryViewModel.swift
// FileFairy

import SwiftUI
import SwiftData

@Observable
final class MBOXLibraryViewModel {

    var isImporting = false
    var importProgress: Double = 0
    var importedEmailCount: Int = 0
    var errorMessage: String?
    var showFilePicker = false

    private var modelContext: ModelContext?
    private var importTask: Task<Void, Never>?
    private let parser = MBOXParser()

    func setContext(_ context: ModelContext) {
        self.modelContext = context
    }

    @MainActor
    func importFile(url: URL) {
        guard let context = modelContext else { return }
        isImporting = true
        importProgress = 0
        importedEmailCount = 0
        errorMessage = nil

        let accessing = url.startAccessingSecurityScopedResource()

        // Get file size
        let fileSize: Int64 = (try? FileManager.default.attributesOfItem(atPath: url.path)[.size] as? Int64) ?? 0

        // Create MBOX record
        let mboxFile = MBOXFile(
            name: url.deletingPathExtension().lastPathComponent,
            filePath: url.path,
            sizeBytes: fileSize
        )
        context.insert(mboxFile)

        importTask = Task {
            var batchEmails: [EmailMessage] = []
            var count = 0

            for await parsed in await parser.parseStream(url: url, onProgress: { [weak self] progress in
                Task { @MainActor in
                    self?.importProgress = progress.fraction
                }
            }) {
                let email = EmailMessage(
                    messageId: parsed.messageId,
                    from: parsed.from,
                    to: parsed.to,
                    subject: parsed.subject,
                    date: parsed.date,
                    bodyPreview: parsed.bodyPreview,
                    bodyOffset: parsed.bodyOffset,
                    bodyLength: parsed.bodyLength,
                    hasAttachments: parsed.hasAttachments
                )
                email.mboxFile = mboxFile
                batchEmails.append(email)
                count += 1

                // Batch insert every 50 emails
                if batchEmails.count >= 50 {
                    await MainActor.run {
                        for e in batchEmails { context.insert(e) }
                        batchEmails.removeAll()
                        importedEmailCount = count
                    }
                }
            }

            // Insert remaining
            await MainActor.run {
                for e in batchEmails { context.insert(e) }
                mboxFile.emailCount = count
                try? context.save()
                importedEmailCount = count
                isImporting = false
                importProgress = 1.0
                if accessing { url.stopAccessingSecurityScopedResource() }
                HapticEngine.shared.success()
                SoundPlayer.shared.play(.conversionDone)
            }
        }
    }

    func cancelImport() {
        importTask?.cancel()
        isImporting = false
    }

    func deleteMBOXFile(_ file: MBOXFile) {
        guard let context = modelContext else { return }
        context.delete(file)
        try? context.save()
    }
}
