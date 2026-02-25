// ZIPService.swift
// FileFairy
//
// ZIP extraction using ZIPFoundation (via SPM).
// Uses FileManager.unzipItem(at:to:) from ZIPFoundation.

import Foundation
import ZIPFoundation

actor ZIPService {

    struct ExtractionResult: Sendable {
        let outputDirectory: URL
        let fileCount: Int
        let totalSize: Int64
    }

    func extract(zipURL: URL) async throws -> ExtractionResult {
        guard zipURL.startAccessingSecurityScopedResource() || true else {
            throw AppError.fileNotFound(zipURL.lastPathComponent)
        }
        defer { zipURL.stopAccessingSecurityScopedResource() }

        let baseName = zipURL.deletingPathExtension().lastPathComponent
        let outputDir = FileManager.default.temporaryDirectory
            .appendingPathComponent("zip_\(baseName)_\(UUID().uuidString.prefix(8))")

        do {
            try FileManager.default.createDirectory(at: outputDir, withIntermediateDirectories: true)
            // ZIPFoundation provides this method on FileManager
            try FileManager.default.unzipItem(at: zipURL, to: outputDir)
        } catch {
            throw AppError.conversionFailed("Failed to extract ZIP: \(error.localizedDescription)")
        }

        // Count extracted files
        let enumerator = FileManager.default.enumerator(
            at: outputDir,
            includingPropertiesForKeys: [.fileSizeKey, .isRegularFileKey]
        )
        var fileCount = 0
        var totalSize: Int64 = 0

        while let fileURL = enumerator?.nextObject() as? URL {
            let resourceValues = try? fileURL.resourceValues(forKeys: [.isRegularFileKey, .fileSizeKey])
            if resourceValues?.isRegularFile == true {
                fileCount += 1
                totalSize += Int64(resourceValues?.fileSize ?? 0)
            }
        }

        return ExtractionResult(
            outputDirectory: outputDir,
            fileCount: fileCount,
            totalSize: totalSize
        )
    }

    func listContents(zipURL: URL) async throws -> [String] {
        let result = try await extract(zipURL: zipURL)
        let enumerator = FileManager.default.enumerator(
            at: result.outputDirectory,
            includingPropertiesForKeys: nil
        )

        var paths: [String] = []
        let basePath = result.outputDirectory.path

        while let fileURL = enumerator?.nextObject() as? URL {
            let relativePath = String(fileURL.path.dropFirst(basePath.count + 1))
            paths.append(relativePath)
        }

        // Clean up
        try? FileManager.default.removeItem(at: result.outputDirectory)
        return paths.sorted()
    }
}
