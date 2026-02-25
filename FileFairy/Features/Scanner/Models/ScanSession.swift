// ScanSession.swift
// FileFairy
//
// SwiftData model for a document scan session.
// Contains multiple pages and export metadata.

import SwiftData
import Foundation

@Model
final class ScanSession {
    var id: UUID
    var title: String
    var createdAt: Date
    var pageCount: Int
    var exportFormat: String  // "pdf" or "jpeg"
    var isExported: Bool

    @Relationship(deleteRule: .cascade, inverse: \ScannedPage.session)
    var pages: [ScannedPage] = []

    init(
        title: String = "",
        exportFormat: String = "pdf"
    ) {
        self.id = UUID()
        self.title = title.isEmpty ? "Scan \(Date().formatted(date: .abbreviated, time: .shortened))" : title
        self.createdAt = Date()
        self.pageCount = 0
        self.exportFormat = exportFormat
        self.isExported = false
    }
}
