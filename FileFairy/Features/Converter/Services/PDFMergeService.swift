// PDFMergeService.swift
// FileFairy

import PDFKit
import Foundation

actor PDFMergeService {

    func merge(pdfs urls: [URL]) async throws -> URL {
        guard urls.count >= 2 else {
            throw AppError.conversionFailed("Need at least 2 PDFs to merge")
        }

        let outputDoc = PDFDocument()
        var pageIndex = 0

        for url in urls {
            guard url.startAccessingSecurityScopedResource() || true else { continue }
            defer { url.stopAccessingSecurityScopedResource() }

            guard let doc = PDFDocument(url: url) else {
                throw AppError.corruptFile("Cannot read \(url.lastPathComponent)")
            }

            for i in 0..<doc.pageCount {
                guard let page = doc.page(at: i) else { continue }
                outputDoc.insert(page, at: pageIndex)
                pageIndex += 1
            }
        }

        guard outputDoc.pageCount > 0 else {
            throw AppError.conversionFailed("No pages found in the selected PDFs")
        }

        let outputURL = FileManager.default.temporaryDirectory
            .appendingPathComponent("merged_\(UUID().uuidString.prefix(8)).pdf")

        guard outputDoc.write(to: outputURL) else {
            throw AppError.conversionFailed("Failed to write merged PDF")
        }

        return outputURL
    }
}
