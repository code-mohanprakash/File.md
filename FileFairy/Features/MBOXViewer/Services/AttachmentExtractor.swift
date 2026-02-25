// AttachmentExtractor.swift
// FileFairy
//
// Extracts email attachments from raw MIME messages.
// Base64/Quoted-Printable decode, returns data for QLPreview.

import Foundation

actor AttachmentExtractor {

    /// Extract all attachments from a raw email message
    func extractAttachments(from rawMessage: String) -> [EmailAttachment] {
        // Find Content-Type to get boundary
        guard let contentType = extractHeader("Content-Type", from: rawMessage),
              contentType.lowercased().contains("multipart"),
              let boundary = extractBoundary(from: contentType) else {
            return []
        }

        let separator = "--\(boundary)"
        let parts = rawMessage.components(separatedBy: separator)
        var attachments: [EmailAttachment] = []

        for part in parts {
            let lower = part.lowercased()

            // Look for attachment parts
            guard lower.contains("content-disposition: attachment") ||
                  lower.contains("content-disposition:attachment") ||
                  (lower.contains("name=") && !lower.contains("text/plain") && !lower.contains("text/html")) else {
                continue
            }

            // Extract filename
            let filename = extractFilename(from: part) ?? "attachment"

            // Extract Content-Type for MIME type
            let partContentType = extractHeader("Content-Type", from: part) ?? "application/octet-stream"
            let mimeType = partContentType.components(separatedBy: ";").first?.trimmingCharacters(in: .whitespaces) ?? "application/octet-stream"

            // Extract and decode content
            let sections = part.components(separatedBy: "\n\n")
            guard sections.count >= 2 else { continue }

            let partHeaders = sections[0]
            let content = sections.dropFirst().joined(separator: "\n\n")
                .trimmingCharacters(in: .whitespacesAndNewlines)

            let encoding = extractHeader("Content-Transfer-Encoding", from: partHeaders)?.lowercased() ?? ""

            var data: Data?
            if encoding.contains("base64") {
                let cleaned = content.replacingOccurrences(of: "\n", with: "")
                    .replacingOccurrences(of: "\r", with: "")
                data = Data(base64Encoded: cleaned, options: .ignoreUnknownCharacters)
            } else {
                data = content.data(using: .utf8)
            }

            if let data {
                attachments.append(EmailAttachment(
                    filename: filename,
                    mimeType: mimeType,
                    size: data.count,
                    data: data
                ))
            }
        }

        return attachments
    }

    // MARK: - Helpers

    private func extractHeader(_ name: String, from text: String) -> String? {
        let lines = text.components(separatedBy: "\n")
        for line in lines {
            if line.lowercased().hasPrefix(name.lowercased() + ":") {
                return String(line.dropFirst(name.count + 1)).trimmingCharacters(in: .whitespaces)
            }
        }
        return nil
    }

    private func extractBoundary(from contentType: String) -> String? {
        guard let range = contentType.range(of: "boundary=", options: .caseInsensitive) else { return nil }
        var boundary = String(contentType[range.upperBound...])
        boundary = boundary.trimmingCharacters(in: CharacterSet(charactersIn: "\"' ;"))
        if let semicolon = boundary.firstIndex(of: ";") {
            boundary = String(boundary[..<semicolon])
        }
        return boundary
    }

    private func extractFilename(from part: String) -> String? {
        // Try Content-Disposition filename
        if let range = part.range(of: "filename=", options: .caseInsensitive) {
            var name = String(part[range.upperBound...])
            if let newline = name.firstIndex(of: "\n") {
                name = String(name[..<newline])
            }
            if let semicolon = name.firstIndex(of: ";") {
                name = String(name[..<semicolon])
            }
            return name.trimmingCharacters(in: CharacterSet(charactersIn: "\"' \r\n"))
        }

        // Try Content-Type name
        if let range = part.range(of: "name=", options: .caseInsensitive) {
            var name = String(part[range.upperBound...])
            if let newline = name.firstIndex(of: "\n") {
                name = String(name[..<newline])
            }
            if let semicolon = name.firstIndex(of: ";") {
                name = String(name[..<semicolon])
            }
            return name.trimmingCharacters(in: CharacterSet(charactersIn: "\"' \r\n"))
        }

        return nil
    }
}
