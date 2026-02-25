// Data+Formatting.swift
// FileFairy
//
// Human-readable formatting helpers for byte counts, data sizes, and
// other numeric quantities that appear throughout the app's UI.

import Foundation

// MARK: - ByteCount Formatting

/// A namespace for file size formatting utilities.
/// Wraps ByteCountFormatter for consistent, locale-aware output.
enum FileSizeFormatter {

    // MARK: - Private Formatters (cached for performance)

    /// Standard binary formatter: "1.2 MB", "345 KB", "3 GB"
    private static let binaryFormatter: ByteCountFormatter = {
        let f = ByteCountFormatter()
        f.allowedUnits = [.useKB, .useMB, .useGB, .useTB]
        f.countStyle = .binary        // 1 KB = 1024 bytes
        f.includesUnit = true
        f.isAdaptive = true
        return f
    }()

    /// Decimal formatter: "1.2 MB", "345 KB" using SI (1 KB = 1000 bytes).
    /// Used when comparing against storage quotas or showing download sizes.
    private static let decimalFormatter: ByteCountFormatter = {
        let f = ByteCountFormatter()
        f.allowedUnits = [.useKB, .useMB, .useGB, .useTB]
        f.countStyle = .decimal       // 1 KB = 1000 bytes
        f.includesUnit = true
        f.isAdaptive = true
        return f
    }()

    /// File-style formatter: shows bytes below 1 KB as "X bytes".
    private static let fileFormatter: ByteCountFormatter = {
        let f = ByteCountFormatter()
        f.allowedUnits = [.useBytes, .useKB, .useMB, .useGB, .useTB]
        f.countStyle = .file
        f.includesUnit = true
        f.isAdaptive = true
        return f
    }()

    // MARK: - Public API

    /// Formats a byte count as a human-readable file size string.
    ///
    /// Uses binary units (1 KB = 1024 bytes) and adapts the unit automatically.
    ///
    /// - Parameter bytes: The size in bytes.
    /// - Returns: A localized string such as "2.4 MB" or "512 KB".
    static func string(fromBytes bytes: Int64) -> String {
        binaryFormatter.string(fromByteCount: bytes)
    }

    /// Formats using SI decimal units (1 KB = 1000 bytes).
    static func decimalString(fromBytes bytes: Int64) -> String {
        decimalFormatter.string(fromByteCount: bytes)
    }

    /// Formats using the OS file-style count, showing bytes for very small values.
    static func fileString(fromBytes bytes: Int64) -> String {
        fileFormatter.string(fromByteCount: bytes)
    }

    /// Returns a compact approximate string: "< 1 KB" for very small files,
    /// "~2 MB" for rounded values. Used in tight UI contexts like list rows.
    static func compactString(fromBytes bytes: Int64) -> String {
        if bytes < 1024 {
            return "< 1 KB"
        }
        return "~\(binaryFormatter.string(fromByteCount: bytes))"
    }
}

// MARK: - Convenience Global Function

/// Formats a byte count to a display string. Mirrors `FileSizeFormatter.string(fromBytes:)`.
///
/// Usage: `formattedFileSize(bytes: file.sizeBytes)`
func formattedFileSize(bytes: Int64) -> String {
    FileSizeFormatter.string(fromBytes: bytes)
}

// MARK: - Data Extension

extension Data {
    /// The byte count formatted as a human-readable string.
    /// e.g. Data with 2_048_000 bytes returns "2 MB".
    var formattedSize: String {
        FileSizeFormatter.string(fromBytes: Int64(count))
    }
}

// MARK: - Int / Int64 Extensions

extension Int64 {
    /// Formats the receiver as a file size string. e.g. `4_096.formattedFileSize` → "4 KB"
    var formattedFileSize: String {
        FileSizeFormatter.string(fromBytes: self)
    }
}

extension Int {
    /// Formats the receiver as a file size string.
    var formattedFileSize: String {
        FileSizeFormatter.string(fromBytes: Int64(self))
    }
}
