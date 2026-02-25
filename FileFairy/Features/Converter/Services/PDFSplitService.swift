// PDFSplitService.swift
// FileFairy

import PDFKit
import Foundation

actor PDFSplitService {

    struct PageRange: Sendable {
        let start: Int  // 1-based
        let end: Int    // 1-based, inclusive
    }

    func split(pdfURL: URL, range: PageRange) async throws -> URL {
        guard pdfURL.startAccessingSecurityScopedResource() || true else {
            throw AppError.fileNotFound(pdfURL.lastPathComponent)
        }
        defer { pdfURL.stopAccessingSecurityScopedResource() }

        guard let sourceDoc = PDFDocument(url: pdfURL) else {
            throw AppError.corruptFile("Cannot read \(pdfURL.lastPathComponent)")
        }

        let totalPages = sourceDoc.pageCount
        guard range.start >= 1, range.end >= range.start, range.end <= totalPages else {
            throw AppError.conversionFailed("Invalid page range \(range.start)-\(range.end) for a \(totalPages)-page PDF")
        }

        let outputDoc = PDFDocument()
        for i in (range.start - 1)...(range.end - 1) {
            guard let page = sourceDoc.page(at: i) else { continue }
            outputDoc.insert(page, at: outputDoc.pageCount)
        }

        let baseName = pdfURL.deletingPathExtension().lastPathComponent
        let outputURL = FileManager.default.temporaryDirectory
            .appendingPathComponent("\(baseName)_p\(range.start)-\(range.end).pdf")

        guard outputDoc.write(to: outputURL) else {
            throw AppError.conversionFailed("Failed to write split PDF")
        }

        return outputURL
    }

    func pageCount(of url: URL) async throws -> Int {
        guard url.startAccessingSecurityScopedResource() || true else {
            throw AppError.fileNotFound(url.lastPathComponent)
        }
        defer { url.stopAccessingSecurityScopedResource() }

        guard let doc = PDFDocument(url: url) else {
            throw AppError.corruptFile("Cannot read \(url.lastPathComponent)")
        }
        return doc.pageCount
    }
}
