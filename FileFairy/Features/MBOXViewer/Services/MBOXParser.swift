// MBOXParser.swift
// FileFairy
//
// High-performance streaming MBOX parser.
// From PRD: Custom Swift MBOX parser (line-by-line, "From " delimiter detection).
// Handles 2GB+ files with 64KB buffered reads.
// Never loads full file into memory.

import Foundation

actor MBOXParser {

    private let chunkSize = 65_536  // 64KB chunks
    private let maxPreviewLength = 200

    /// Progress callback: (bytesRead, totalBytes)
    struct Progress: Sendable {
        let bytesRead: Int64
        let totalBytes: Int64
        var fraction: Double {
            guard totalBytes > 0 else { return 0 }
            return Double(bytesRead) / Double(totalBytes)
        }
    }

    /// Parsed email summary (lightweight, for building index)
    struct ParsedEmail: Sendable {
        let messageId: String
        let from: String
        let to: String
        let subject: String
        let date: Date
        let bodyPreview: String
        let bodyOffset: Int64
        let bodyLength: Int
        let hasAttachments: Bool
    }

    // MARK: - Parse Stream

    /// Parse an MBOX file and emit emails as they're found via AsyncStream
    func parseStream(
        url: URL,
        onProgress: @Sendable @escaping (Progress) -> Void = { _ in }
    ) -> AsyncStream<ParsedEmail> {
        AsyncStream { continuation in
            Task.detached(priority: .utility) { [chunkSize, maxPreviewLength] in
                guard let fileHandle = try? FileHandle(forReadingFrom: url) else {
                    continuation.finish()
                    return
                }
                defer { try? fileHandle.close() }

                // Get total file size
                let totalBytes: Int64
                if let attrs = try? FileManager.default.attributesOfItem(atPath: url.path),
                   let size = attrs[.size] as? Int64 {
                    totalBytes = size
                } else {
                    totalBytes = 0
                }

                var bytesRead: Int64 = 0
                var lineBuffer = ""
                var currentHeaders: [String: String] = [:]
                var currentBodyLines: [String] = []
                var messageStartOffset: Int64 = 0
                var inHeaders = true
                var messageCount = 0
                let dateParser = MBOXDateParser()

                func emitCurrentMessage() {
                    guard !currentHeaders.isEmpty else { return }

                    let from = Self.extractEmailAddress(currentHeaders["From"] ?? "")
                    let subject = currentHeaders["Subject"] ?? "(No Subject)"
                    let to = Self.extractEmailAddress(currentHeaders["To"] ?? "")
                    let messageId = currentHeaders["Message-ID"] ?? UUID().uuidString
                    let dateString = currentHeaders["Date"] ?? ""
                    let date = dateParser.parse(dateString) ?? Date.distantPast

                    let bodyText = currentBodyLines.joined(separator: " ")
                    let preview = String(bodyText.prefix(maxPreviewLength))
                        .replacingOccurrences(of: "\n", with: " ")
                        .trimmingCharacters(in: .whitespacesAndNewlines)

                    let hasAttachments = currentHeaders["Content-Type"]?
                        .lowercased().contains("multipart/mixed") ?? false

                    let bodyLength = Int(bytesRead - messageStartOffset)

                    let email = ParsedEmail(
                        messageId: messageId,
                        from: from,
                        to: to,
                        subject: subject,
                        date: date,
                        bodyPreview: preview,
                        bodyOffset: messageStartOffset,
                        bodyLength: bodyLength,
                        hasAttachments: hasAttachments
                    )

                    continuation.yield(email)
                    messageCount += 1
                }

                // Process file in chunks
                while true {
                    let chunk = fileHandle.readData(ofLength: chunkSize)
                    guard !chunk.isEmpty else { break }

                    bytesRead += Int64(chunk.count)

                    // Convert chunk to string (try UTF-8 first, then Latin-1)
                    let chunkString: String
                    if let utf8 = String(data: chunk, encoding: .utf8) {
                        chunkString = utf8
                    } else if let latin1 = String(data: chunk, encoding: .isoLatin1) {
                        chunkString = latin1
                    } else {
                        continue
                    }

                    lineBuffer += chunkString

                    // Process complete lines
                    while let newlineRange = lineBuffer.range(of: "\n") {
                        let line = String(lineBuffer[lineBuffer.startIndex..<newlineRange.lowerBound])
                        lineBuffer = String(lineBuffer[newlineRange.upperBound...])

                        // Check for MBOX "From " separator (message boundary)
                        if line.hasPrefix("From ") && (line.contains("@") || line.contains(" Mon ") ||
                            line.contains(" Tue ") || line.contains(" Wed ") || line.contains(" Thu ") ||
                            line.contains(" Fri ") || line.contains(" Sat ") || line.contains(" Sun ")) {

                            // Emit previous message
                            emitCurrentMessage()

                            // Start new message
                            currentHeaders = [:]
                            currentBodyLines = []
                            messageStartOffset = bytesRead - Int64(lineBuffer.utf8.count)
                            inHeaders = true
                            continue
                        }

                        if inHeaders {
                            if line.isEmpty {
                                // Empty line separates headers from body
                                inHeaders = false
                                continue
                            }

                            // Handle header continuation (folded headers start with whitespace)
                            if line.hasPrefix(" ") || line.hasPrefix("\t") {
                                // Append to previous header
                                if let lastKey = currentHeaders.keys.sorted().last {
                                    currentHeaders[lastKey]?.append(" " + line.trimmingCharacters(in: .whitespaces))
                                }
                            } else if let colonIndex = line.firstIndex(of: ":") {
                                let key = String(line[line.startIndex..<colonIndex]).trimmingCharacters(in: .whitespaces)
                                let value = String(line[line.index(after: colonIndex)...]).trimmingCharacters(in: .whitespaces)
                                currentHeaders[key] = value
                            }
                        } else {
                            // Only store limited body lines for preview
                            if currentBodyLines.joined().count < maxPreviewLength * 2 {
                                // Strip HTML tags for preview
                                let cleanLine = line.replacingOccurrences(
                                    of: "<[^>]+>",
                                    with: "",
                                    options: .regularExpression
                                )
                                if !cleanLine.trimmingCharacters(in: .whitespaces).isEmpty {
                                    currentBodyLines.append(cleanLine)
                                }
                            }
                        }
                    }

                    // Report progress
                    onProgress(Progress(bytesRead: bytesRead, totalBytes: totalBytes))
                }

                // Emit final message
                emitCurrentMessage()
                continuation.finish()
            }
        }
    }

    // MARK: - Load Full Message Body

    /// Load the full body of a specific email from the MBOX file
    func loadFullBody(from url: URL, offset: Int64, length: Int) async -> String? {
        guard let fileHandle = try? FileHandle(forReadingFrom: url) else { return nil }
        defer { try? fileHandle.close() }

        try? fileHandle.seek(toOffset: UInt64(offset))
        let data = fileHandle.readData(ofLength: length)

        if let text = String(data: data, encoding: .utf8) {
            return text
        }
        return String(data: data, encoding: .isoLatin1)
    }

    // MARK: - Helpers

    /// Extract email address from "Name <email@example.com>" format
    static func extractEmailAddress(_ raw: String) -> String {
        if let start = raw.firstIndex(of: "<"),
           let end = raw.firstIndex(of: ">") {
            let name = raw[raw.startIndex..<start].trimmingCharacters(in: .whitespaces.union(.init(charactersIn: "\"")))
            if !name.isEmpty {
                return name
            }
            return String(raw[raw.index(after: start)..<end])
        }
        return raw.trimmingCharacters(in: .whitespaces.union(.init(charactersIn: "\"")))
    }
}

// MARK: - Date Parser

/// Parses various email date formats (RFC 2822 and common variants)
final class MBOXDateParser: Sendable {

    func parse(_ string: String) -> Date? {
        let trimmed = string.trimmingCharacters(in: .whitespaces)

        // Try ISO 8601 first
        if let date = ISO8601DateFormatter().date(from: trimmed) {
            return date
        }

        // Try common email date formats
        let formats = [
            "EEE, dd MMM yyyy HH:mm:ss Z",      // RFC 2822
            "EEE, dd MMM yyyy HH:mm:ss ZZZZ",
            "dd MMM yyyy HH:mm:ss Z",
            "EEE, d MMM yyyy HH:mm:ss Z",
            "yyyy-MM-dd'T'HH:mm:ssZ",
            "yyyy-MM-dd HH:mm:ss",
        ]

        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")

        for format in formats {
            formatter.dateFormat = format
            if let date = formatter.date(from: trimmed) {
                return date
            }
        }

        return nil
    }
}
