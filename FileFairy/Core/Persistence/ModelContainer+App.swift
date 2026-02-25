// ModelContainer+App.swift
// FileFairy
//
// Helpers for creating in-memory containers used in SwiftUI Previews and
// XCTest targets. In-memory containers are isolated per invocation and
// never write to disk, making tests deterministic and previews fast.

import SwiftData
import Foundation

// MARK: - ModelContainer Preview Extension

extension ModelContainer {

    // MARK: - Empty Preview Container

    /// Returns a fresh, empty in-memory container configured with the full
    /// production schema. Use this in previews that don't need seed data.
    ///
    /// Usage:
    /// ```swift
    /// #Preview {
    ///     SomeView()
    ///         .modelContainer(.preview)
    /// }
    /// ```
    static var preview: ModelContainer {
        makeInMemoryContainer()
    }

    // MARK: - Seeded Preview Containers

    /// In-memory container pre-populated with sample ScanSessions and pages.
    @MainActor
    static var previewWithScans: ModelContainer {
        let container = makeInMemoryContainer()
        let context = container.mainContext

        let session1 = ScanSession(
            title: "Receipt - Coffee Shop",
            exportFormat: "PDF"
        )
        let page1 = ScannedPage(pageIndex: 0, filterName: "Document")
        let page2 = ScannedPage(pageIndex: 1, filterName: "Grayscale")
        session1.pages = [page1, page2]
        context.insert(session1)

        let session2 = ScanSession(
            title: "Contract Draft",
            exportFormat: "PDF"
        )
        context.insert(session2)

        let session3 = ScanSession(
            title: "Business Card",
            exportFormat: "JPEG"
        )
        context.insert(session3)

        try? context.save()
        return container
    }

    /// In-memory container pre-populated with a sample MBOXFile and messages.
    @MainActor
    static var previewWithEmails: ModelContainer {
        let container = makeInMemoryContainer()
        let context = container.mainContext

        let mbox = MBOXFile(
            name: "archive-2024.mbox",
            filePath: "/tmp/archive-2024.mbox",
            sizeBytes: 52_428_800
        )
        context.insert(mbox)

        let emails: [(String, String, String)] = [
            ("Alice Smith <alice@example.com>", "Project Update", "Hi team, just checking in on the current status of the Q4 project."),
            ("Bob Jones <bob@corp.com>", "Invoice #4821", "Please find attached the invoice for last month's services rendered."),
            ("Newsletter <news@design.io>", "Weekly Design Digest", "This week in design: accessibility trends, new tools, and inspiration."),
            ("no-reply@bank.com", "Your statement is ready", "Your monthly statement for October 2024 is now available to view.")
        ]

        for (index, (from, subject, preview)) in emails.enumerated() {
            let msg = EmailMessage(
                messageId: "<msg-\(index)@example.com>",
                from: from,
                subject: subject,
                date: Date.now.addingTimeInterval(Double(-index) * 7200),
                bodyPreview: preview,
                bodyOffset: Int64(index * 4096),
                bodyLength: 2048,
                hasAttachments: index == 1
            )
            msg.mboxFile = mbox
            context.insert(msg)
        }

        try? context.save()
        return container
    }

    /// In-memory container pre-populated with ConversionJobs.
    @MainActor
    static var previewWithConversions: ModelContainer {
        let container = makeInMemoryContainer()
        let context = container.mainContext

        let jobs: [(String, ConversionType, String)] = [
            ("photo.heic",  .heicToJpeg,  "completed"),
            ("photo2.heic", .heicToPng,   "completed"),
            ("slides.png",  .pdfMerge,    "processing"),
            ("archive.zip", .zipExtract,  "failed")
        ]

        for (idx, (input, type_, status)) in jobs.enumerated() {
            let job = ConversionJob(
                inputFileName: input,
                conversionType: type_,
                inputSize: Int64((idx + 1) * 512_000)
            )
            job.status = status
            context.insert(job)
        }

        try? context.save()
        return container
    }

    /// In-memory container with RecentFiles seeded for Home screen previews.
    @MainActor
    static var previewWithRecentFiles: ModelContainer {
        let container = makeInMemoryContainer()
        let context = container.mainContext

        let recentFiles: [(String, String, String, Int64)] = [
            ("Q4 Report.pdf",        "/docs/q4-report.pdf",     "pdf",   2_097_152),
            ("archive-2024.mbox",    "/docs/archive-2024.mbox", "mbox",  52_428_800),
            ("headshot.heic",        "/photos/headshot.heic",   "image", 4_194_304),
            ("presentation.pptx",    "/docs/slides.pptx",       "pptx",  8_388_608)
        ]

        for (_, (name, path, type_, size)) in recentFiles.enumerated() {
            let file = RecentFile(
                displayName: name,
                filePath: path,
                fileType: type_,
                sizeBytes: size
            )
            context.insert(file)
        }

        try? context.save()
        return container
    }

    // MARK: - Factory

    /// Creates a new in-memory ModelContainer with the production schema.
    /// Each call returns an independent, isolated container instance.
    static func makeInMemoryContainer() -> ModelContainer {
        let schema = Schema([
            ScanSession.self,
            ScannedPage.self,
            MBOXFile.self,
            EmailMessage.self,
            ConversionJob.self,
            RecentFile.self
        ])

        let config = ModelConfiguration(
            schema: schema,
            isStoredInMemoryOnly: true
        )

        do {
            return try ModelContainer(for: schema, configurations: [config])
        } catch {
            fatalError("FileFairy: Failed to create in-memory ModelContainer: \(error)")
        }
    }
}
