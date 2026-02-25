// RecentFile.swift
// FileFairy
//
// SwiftData model tracking recently opened files.

import SwiftData
import Foundation

@Model
final class RecentFile {
    var id: UUID
    var displayName: String
    var filePath: String
    var fileType: String       // File extension (pdf, jpeg, mbox, etc.)
    var openedAt: Date
    var sizeBytes: Int64

    init(
        displayName: String,
        filePath: String,
        fileType: String,
        sizeBytes: Int64 = 0
    ) {
        self.id = UUID()
        self.displayName = displayName
        self.filePath = filePath
        self.fileType = fileType
        self.openedAt = Date()
        self.sizeBytes = sizeBytes
    }
}
