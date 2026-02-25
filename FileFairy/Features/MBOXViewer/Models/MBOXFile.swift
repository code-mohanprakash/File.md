// MBOXFile.swift
// FileFairy
//
// SwiftData model for an imported MBOX archive.

import SwiftData
import Foundation

@Model
final class MBOXFile {
    var id: UUID
    var name: String
    var filePath: String
    var sizeBytes: Int64
    var importedAt: Date
    var emailCount: Int

    @Relationship(deleteRule: .cascade, inverse: \EmailMessage.mboxFile)
    var emails: [EmailMessage] = []

    init(
        name: String,
        filePath: String,
        sizeBytes: Int64 = 0
    ) {
        self.id = UUID()
        self.name = name
        self.filePath = filePath
        self.sizeBytes = sizeBytes
        self.importedAt = Date()
        self.emailCount = 0
    }
}
