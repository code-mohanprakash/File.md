// ScanExportService.swift
// FileFairy
//
// Exports scanned pages as PDF or JPEG.
// From PRD: PDFKit for PDF generation, UIActivityViewController for sharing.

import PDFKit
import UIKit

actor ScanExportService {

    enum ExportFormat: String {
        case pdf
        case jpeg
    }

    // MARK: - Export as PDF

    func exportAsPDF(
        pages: [UIImage],
        title: String,
        progress: @Sendable (Double) -> Void = { _ in }
    ) async throws -> URL {
        let pdfDocument = PDFDocument()
        let total = Double(pages.count)

        for (index, image) in pages.enumerated() {
            guard let page = PDFPage(image: image) else { continue }
            pdfDocument.insert(page, at: index)
            progress(Double(index + 1) / total)
        }

        let outputURL = FileManager.default.temporaryDirectory
            .appendingPathComponent(sanitizeFilename(title))
            .appendingPathExtension("pdf")

        guard pdfDocument.write(to: outputURL) else {
            throw AppError.conversionFailed("Failed to write PDF file")
        }

        return outputURL
    }

    // MARK: - Export as JPEG Bundle

    func exportAsJPEGs(
        pages: [UIImage],
        title: String,
        quality: CGFloat = 0.9,
        progress: @Sendable (Double) -> Void = { _ in }
    ) async throws -> [URL] {
        var urls: [URL] = []
        let total = Double(pages.count)
        let baseName = sanitizeFilename(title)

        for (index, image) in pages.enumerated() {
            guard let data = image.jpegData(compressionQuality: quality) else { continue }

            let filename = pages.count == 1
                ? "\(baseName).jpeg"
                : "\(baseName)_page\(index + 1).jpeg"

            let url = FileManager.default.temporaryDirectory
                .appendingPathComponent(filename)

            try data.write(to: url)
            urls.append(url)
            progress(Double(index + 1) / total)
        }

        return urls
    }

    // MARK: - Save to Documents

    func saveToDocuments(from tempURL: URL) throws -> URL {
        guard let documentsDir = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first else {
            throw AppError.fileNotFound("Documents directory unavailable")
        }
        let scansDir = documentsDir.appendingPathComponent("Scans", isDirectory: true)

        // Create Scans directory if needed
        if !FileManager.default.fileExists(atPath: scansDir.path) {
            try FileManager.default.createDirectory(at: scansDir, withIntermediateDirectories: true)
        }

        let destURL = scansDir.appendingPathComponent(tempURL.lastPathComponent)

        // Remove existing file if present
        if FileManager.default.fileExists(atPath: destURL.path) {
            try FileManager.default.removeItem(at: destURL)
        }

        try FileManager.default.copyItem(at: tempURL, to: destURL)
        return destURL
    }

    // MARK: - Helpers

    private func sanitizeFilename(_ name: String) -> String {
        let allowed = CharacterSet.alphanumerics.union(CharacterSet(charactersIn: "-_ "))
        return name
            .unicodeScalars
            .filter { allowed.contains($0) }
            .map { String($0) }
            .joined()
            .trimmingCharacters(in: .whitespaces)
            .replacingOccurrences(of: " ", with: "_")
    }
}
