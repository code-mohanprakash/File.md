// URL+FileHelpers.swift
// FileFairy
//
// Convenience properties on URL for common file-inspection tasks.
// All properties are computed and non-throwing — errors are swallowed
// and expressed as nil or false, keeping call sites clean.

import Foundation
import UniformTypeIdentifiers

// MARK: - URL File Helpers

extension URL {

    // MARK: - Metadata

    /// The file's size in bytes, or nil if the URL is not a local file
    /// or the size cannot be determined.
    var fileSize: Int64? {
        guard isFileURL else { return nil }
        let values = try? resourceValues(forKeys: [.fileSizeKey])
        guard let size = values?.fileSize else { return nil }
        return Int64(size)
    }

    /// The MIME type derived from the file's UTType, or nil if undetermined.
    /// Examples: "application/pdf", "image/jpeg", "message/rfc822"
    var mimeType: String? {
        guard let utType = UTType(filenameExtension: pathExtension) else { return nil }
        return utType.preferredMIMEType
    }

    /// The file name without its path extension, decoded for display.
    /// Falls back to `lastPathComponent` if deletion fails.
    var displayName: String {
        let nameWithExtension = lastPathComponent
        let withoutExtension = (nameWithExtension as NSString).deletingPathExtension
        return withoutExtension.isEmpty ? nameWithExtension : withoutExtension
    }

    /// The lowercased file extension, without the leading dot.
    /// Returns an empty string if the URL has no extension.
    var fileExtension: String {
        pathExtension.lowercased()
    }

    // MARK: - Type Checks

    /// True if the file is a common image format (JPEG, PNG, HEIC, HEIF, GIF, WebP, TIFF, BMP).
    var isImage: Bool {
        let imageExtensions: Set<String> = ["jpg", "jpeg", "png", "heic", "heif", "gif", "webp", "tiff", "tif", "bmp"]
        return imageExtensions.contains(fileExtension)
    }

    /// True if the file is a PDF document.
    var isPDF: Bool {
        fileExtension == "pdf"
    }

    /// True if the file is an MBOX mail archive.
    var isMBOX: Bool {
        fileExtension == "mbox"
    }

    /// True if the file is a Microsoft Word document (modern or legacy).
    var isWord: Bool {
        let wordExtensions: Set<String> = ["docx", "doc", "rtf", "odt"]
        return wordExtensions.contains(fileExtension)
    }

    /// True if the file is a plain-text document.
    var isText: Bool {
        let textExtensions: Set<String> = ["txt", "text", "md", "csv", "log"]
        return textExtensions.contains(fileExtension)
    }

    /// True if the file is a spreadsheet (Excel, Numbers, CSV).
    var isSpreadsheet: Bool {
        let spreadsheetExtensions: Set<String> = ["xlsx", "xls", "numbers", "csv", "ods"]
        return spreadsheetExtensions.contains(fileExtension)
    }

    // MARK: - Availability

    /// True if the file currently exists and is reachable on disk.
    var isReachable: Bool {
        (try? checkResourceIsReachable()) == true
    }

    // MARK: - Security-Scoped Resource Helpers

    /// Calls `startAccessingSecurityScopedResource`, executes the closure,
    /// then always calls `stopAccessingSecurityScopedResource`.
    /// Use this when working with files selected via UIDocumentPickerViewController.
    @discardableResult
    func withSecurityScope<T>(_ work: (URL) throws -> T) rethrows -> T {
        let granted = startAccessingSecurityScopedResource()
        defer {
            if granted { stopAccessingSecurityScopedResource() }
        }
        return try work(self)
    }

    // MARK: - Path Helpers

    /// Returns a new URL with a numeric suffix to avoid overwriting an existing file.
    /// e.g. "report.pdf" → "report (2).pdf" → "report (3).pdf"
    func uniqueURL() -> URL {
        guard FileManager.default.fileExists(atPath: path) else { return self }

        let base       = deletingPathExtension().lastPathComponent
        let ext        = pathExtension
        let dir        = deletingLastPathComponent()
        var counter    = 2
        var candidate  = dir
            .appendingPathComponent("\(base) (\(counter))")
            .appendingPathExtension(ext)

        while FileManager.default.fileExists(atPath: candidate.path) {
            counter += 1
            candidate = dir
                .appendingPathComponent("\(base) (\(counter))")
                .appendingPathExtension(ext)
        }
        return candidate
    }
}
