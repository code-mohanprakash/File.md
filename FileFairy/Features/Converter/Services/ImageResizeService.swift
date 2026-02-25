// ImageResizeService.swift
// FileFairy

import UIKit
import ImageIO
import UniformTypeIdentifiers

actor ImageResizeService {

    struct ResizeOptions: Sendable {
        let maxWidth: Int?
        let maxHeight: Int?
        let scale: CGFloat?  // 0.1 - 1.0

        static func dimensions(width: Int, height: Int) -> ResizeOptions {
            ResizeOptions(maxWidth: width, maxHeight: height, scale: nil)
        }

        static func percentage(_ scale: CGFloat) -> ResizeOptions {
            ResizeOptions(maxWidth: nil, maxHeight: nil, scale: scale)
        }
    }

    func resize(imageURL: URL, options: ResizeOptions, quality: CGFloat = 0.9) async throws -> URL {
        let accessing = imageURL.startAccessingSecurityScopedResource()
        defer { if accessing { imageURL.stopAccessingSecurityScopedResource() } }

        guard let source = CGImageSourceCreateWithURL(imageURL as CFURL, nil),
              let cgImage = CGImageSourceCreateImageAtIndex(source, 0, nil) else {
            throw AppError.corruptFile("Cannot read \(imageURL.lastPathComponent)")
        }

        let originalWidth = CGFloat(cgImage.width)
        let originalHeight = CGFloat(cgImage.height)

        let targetSize: CGSize
        if let scale = options.scale {
            targetSize = CGSize(
                width: originalWidth * scale,
                height: originalHeight * scale
            )
        } else if let maxW = options.maxWidth, let maxH = options.maxHeight {
            let widthRatio = CGFloat(maxW) / originalWidth
            let heightRatio = CGFloat(maxH) / originalHeight
            let ratio = min(widthRatio, heightRatio, 1.0)
            targetSize = CGSize(
                width: originalWidth * ratio,
                height: originalHeight * ratio
            )
        } else {
            targetSize = CGSize(width: originalWidth, height: originalHeight)
        }

        let renderer = UIGraphicsImageRenderer(size: targetSize)
        let resizedImage = renderer.image { _ in
            UIImage(cgImage: cgImage).draw(in: CGRect(origin: .zero, size: targetSize))
        }

        // Detect output format from input
        let ext = imageURL.pathExtension.lowercased()
        let outputData: Data
        let outputExt: String

        if ext == "png" {
            guard let data = resizedImage.pngData() else {
                throw AppError.conversionFailed("Failed to encode resized PNG")
            }
            outputData = data
            outputExt = "png"
        } else {
            guard let data = resizedImage.jpegData(compressionQuality: quality) else {
                throw AppError.conversionFailed("Failed to encode resized image")
            }
            outputData = data
            outputExt = ext == "heic" ? "heic" : "jpeg"
        }

        let baseName = imageURL.deletingPathExtension().lastPathComponent
        let outputURL = FileManager.default.temporaryDirectory
            .appendingPathComponent("\(baseName)_resized.\(outputExt)")

        try outputData.write(to: outputURL)
        return outputURL
    }
}
