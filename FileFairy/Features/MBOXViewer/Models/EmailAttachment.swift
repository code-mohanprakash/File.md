// EmailAttachment.swift
// FileFairy
//
// Lightweight struct for email attachments.
// Not a SwiftData @Model - extracted on-demand from MIME data.

import Foundation

struct EmailAttachment: Identifiable, Sendable {
    let id: UUID
    let filename: String
    let mimeType: String
    let size: Int
    let data: Data

    init(
        filename: String,
        mimeType: String,
        size: Int,
        data: Data
    ) {
        self.id = UUID()
        self.filename = filename
        self.mimeType = mimeType
        self.size = size
        self.data = data
    }

    var displaySize: String {
        ByteCountFormatter.string(fromByteCount: Int64(size), countStyle: .file)
    }

    var fileIcon: String {
        switch mimeType.lowercased() {
        case let type where type.contains("image"):  return "photo.fill"
        case let type where type.contains("pdf"):    return "doc.fill"
        case let type where type.contains("zip"):    return "archivebox.fill"
        case let type where type.contains("text"):   return "doc.text.fill"
        default:                                      return "paperclip"
        }
    }
}
