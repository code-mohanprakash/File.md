// AppSchema.swift
// FileFairy
//
// Shared ModelContainer. All @Model types live in their feature folders.
// To migrate: add a new schema version here and supply a MigrationPlan.

import Foundation
import SwiftData

// MARK: - AppSchema

enum AppSchema {

    /// The production ModelContainer. Injected via `.modelContainer(AppSchema.container)` in FileFairyApp.
    static let container: ModelContainer = {
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
            isStoredInMemoryOnly: false,
            allowsSave: true
        )

        do {
            return try ModelContainer(for: schema, configurations: [config])
        } catch {
            fatalError("FileFairy: Failed to create ModelContainer: \(error)")
        }
    }()
}
