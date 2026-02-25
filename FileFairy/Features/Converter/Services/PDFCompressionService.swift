// PDFCompressionService.swift
// FileFairy

import PDFKit
import UIKit
import CoreGraphics

actor PDFCompressionService {

    enum Quality: String, CaseIterable, Sendable {
        case high   // 150 DPI, quality 0.8
        case medium // 100 DPI, quality 0.6
        case low    // 72 DPI, quality 0.4

        var dpi: CGFloat {
            switch self {
            case .high:   return 150
            case .medium: return 100
            case .low:    return 72
            }
        }

        var jpegQuality: CGFloat {
            switch self {
            case .high:   return 0.8
            case .medium: return 0.6
            case .low:    return 0.4
            }
        }

        var displayName: String {
            switch self {
            case .high:   return "High (150 DPI)"
            case .medium: return "Medium (100 DPI)"
            case .low:    return "Low (72 DPI)"
            }
        }
    }

    func compress(pdfURL: URL, quality: Quality) async throws -> URL {
        guard pdfURL.startAccessingSecurityScopedResource() || true else {
            throw AppError.fileNotFound(pdfURL.lastPathComponent)
        }
        defer { pdfURL.stopAccessingSecurityScopedResource() }

        guard let sourceDoc = PDFDocument(url: pdfURL) else {
            throw AppError.corruptFile("Cannot read \(pdfURL.lastPathComponent)")
        }

        let baseName = pdfURL.deletingPathExtension().lastPathComponent
        let outputURL = FileManager.default.temporaryDirectory
            .appendingPathComponent("\(baseName)_compressed.pdf")

        let scaleFactor = quality.dpi / 72.0

        guard let pdfContext = CGContext(
            outputURL as CFURL,
            mediaBox: nil,
            nil
        ) else {
            throw AppError.conversionFailed("Cannot create PDF context")
        }

        for i in 0..<sourceDoc.pageCount {
            guard let page = sourceDoc.page(at: i) else { continue }

            let mediaBox = page.bounds(for: .mediaBox)
            var pageRect = mediaBox

            // Render page to bitmap at target DPI
            let pixelWidth = Int(mediaBox.width * scaleFactor)
            let pixelHeight = Int(mediaBox.height * scaleFactor)

            let renderer = UIGraphicsImageRenderer(
                size: CGSize(width: pixelWidth, height: pixelHeight)
            )

            let image = renderer.image { ctx in
                UIColor.white.setFill()
                ctx.fill(CGRect(origin: .zero, size: CGSize(width: pixelWidth, height: pixelHeight)))
                ctx.cgContext.scaleBy(x: scaleFactor, y: scaleFactor)
                page.draw(with: .mediaBox, to: ctx.cgContext)
            }

            guard let jpegData = image.jpegData(compressionQuality: quality.jpegQuality),
                  let jpegImage = UIImage(data: jpegData),
                  let cgImage = jpegImage.cgImage else { continue }

            pdfContext.beginPage(mediaBox: &pageRect)
            pdfContext.draw(cgImage, in: pageRect)
            pdfContext.endPage()
        }

        pdfContext.closePDF()
        return outputURL
    }
}
