// ImageConversionService.swift
// FileFairy - ImageIO-based HEIC/WebP/PNG/JPEG conversion

import ImageIO
import UIKit
import UniformTypeIdentifiers

actor ImageConversionService {

    enum ImageFormat: String {
        case jpeg, png, heic, webp

        var utType: CFString {
            switch self {
            case .jpeg: return UTType.jpeg.identifier as CFString
            case .png:  return UTType.png.identifier as CFString
            case .heic: return UTType.heic.identifier as CFString
            case .webp: return UTType.webP.identifier as CFString
            }
        }

        var fileExtension: String { rawValue }
    }

    func convert(from inputURL: URL, to format: ImageFormat, quality: CGFloat = 0.9) async throws -> URL {
        let accessing = inputURL.startAccessingSecurityScopedResource()
        defer { if accessing { inputURL.stopAccessingSecurityScopedResource() } }

        guard let source = CGImageSourceCreateWithURL(inputURL as CFURL, nil) else {
            throw AppError.unsupportedFormat("Cannot read image: \(inputURL.lastPathComponent)")
        }

        guard let cgImage = CGImageSourceCreateImageAtIndex(source, 0, [
            kCGImageSourceShouldCacheImmediately: false
        ] as CFDictionary) else {
            throw AppError.corruptFile("Cannot decode image data")
        }

        let outputName = inputURL.deletingPathExtension().lastPathComponent + "." + format.fileExtension
        let outputURL = FileManager.default.temporaryDirectory.appendingPathComponent(outputName)

        guard let destination = CGImageDestinationCreateWithURL(
            outputURL as CFURL, format.utType, 1, nil
        ) else {
            throw AppError.conversionFailed("Cannot create output file")
        }

        let options: [CFString: Any] = [
            kCGImageDestinationLossyCompressionQuality: quality
        ]
        CGImageDestinationAddImage(destination, cgImage, options as CFDictionary)

        guard CGImageDestinationFinalize(destination) else {
            throw AppError.conversionFailed("Failed to write \(format.rawValue.uppercased()) file")
        }

        return outputURL
    }

    func imagesToPDF(from urls: [URL]) async throws -> URL {
        let outputURL = FileManager.default.temporaryDirectory.appendingPathComponent("merged_images.pdf")
        guard let pdfContext = CGContext(outputURL as CFURL, mediaBox: nil, nil) else {
            throw AppError.conversionFailed("Cannot create PDF context")
        }

        for url in urls {
            let accessing = url.startAccessingSecurityScopedResource()
            defer { if accessing { url.stopAccessingSecurityScopedResource() } }
            guard let source = CGImageSourceCreateWithURL(url as CFURL, nil),
                  let cgImage = CGImageSourceCreateImageAtIndex(source, 0, nil) else { continue }

            let w = CGFloat(cgImage.width)
            let h = CGFloat(cgImage.height)
            var mediaBox = CGRect(x: 0, y: 0, width: w, height: h)
            pdfContext.beginPage(mediaBox: &mediaBox)
            pdfContext.draw(cgImage, in: mediaBox)
            pdfContext.endPage()
        }

        pdfContext.closePDF()
        return outputURL
    }
}
