// EmailBodyRenderer.swift
// FileFairy
//
// Converts raw MIME email body to clean HTML for WKWebView rendering.
// Injects FileFairy design system CSS for beautiful email display.

import Foundation

actor EmailBodyRenderer {

    /// Render a raw email message string into HTML for WKWebView
    func renderHTML(from rawMessage: String) -> String {
        // Split headers and body
        let parts = rawMessage.components(separatedBy: "\n\n")
        guard parts.count >= 2 else {
            return wrapInHTML(plainText: rawMessage)
        }

        let headers = parts[0]
        let body = parts.dropFirst().joined(separator: "\n\n")

        // Check content type
        let contentType = extractHeader("Content-Type", from: headers)?.lowercased() ?? "text/plain"
        let transferEncoding = extractHeader("Content-Transfer-Encoding", from: headers)?.lowercased() ?? ""

        var decodedBody = body

        // Decode transfer encoding
        if transferEncoding.contains("quoted-printable") {
            decodedBody = decodeQuotedPrintable(body)
        } else if transferEncoding.contains("base64") {
            if let data = Data(base64Encoded: body.replacingOccurrences(of: "\n", with: ""),
                              options: .ignoreUnknownCharacters),
               let decoded = String(data: data, encoding: .utf8) {
                decodedBody = decoded
            }
        }

        // Handle multipart
        if contentType.contains("multipart") {
            let boundary = extractBoundary(from: contentType)
            if let htmlPart = extractHTMLPart(from: decodedBody, boundary: boundary) {
                return wrapInHTML(htmlContent: htmlPart)
            }
            if let textPart = extractTextPart(from: decodedBody, boundary: boundary) {
                return wrapInHTML(plainText: textPart)
            }
        }

        // Single part
        if contentType.contains("text/html") {
            return wrapInHTML(htmlContent: decodedBody)
        }

        return wrapInHTML(plainText: decodedBody)
    }

    // MARK: - HTML Wrapper with Fairy Design System CSS

    private func wrapInHTML(htmlContent: String) -> String {
        """
        <!DOCTYPE html>
        <html>
        <head>
            <meta charset="utf-8">
            <meta name="viewport" content="width=device-width, initial-scale=1.0, maximum-scale=1.0">
            <meta http-equiv="Content-Security-Policy" content="default-src 'self' 'unsafe-inline'; img-src * data:; style-src 'self' 'unsafe-inline'">
            <style>
                * { box-sizing: border-box; }
                body {
                    font-family: -apple-system, 'SF Pro Rounded', system-ui, sans-serif;
                    font-size: 15px;
                    line-height: 1.6;
                    color: #374151;
                    background-color: #FAF5FF;
                    padding: 16px;
                    margin: 0;
                    word-wrap: break-word;
                    overflow-wrap: break-word;
                    -webkit-text-size-adjust: 100%;
                }
                a { color: #8B5CF6; text-decoration: none; }
                a:hover { text-decoration: underline; }
                img { max-width: 100%; height: auto; border-radius: 8px; }
                blockquote {
                    border-left: 3px solid #C4B5FD;
                    margin: 8px 0;
                    padding: 4px 12px;
                    color: #6B7280;
                    background: rgba(139, 92, 246, 0.04);
                    border-radius: 0 8px 8px 0;
                }
                pre, code {
                    font-family: 'SF Mono', monospace;
                    font-size: 13px;
                    background: #FEFCE8;
                    padding: 2px 6px;
                    border-radius: 4px;
                }
                pre { padding: 12px; overflow-x: auto; }
                table { border-collapse: collapse; max-width: 100%; }
                td, th { padding: 6px 10px; border: 1px solid #E5E7EB; }
                hr { border: none; border-top: 1px solid #E5E7EB; margin: 16px 0; }
            </style>
        </head>
        <body>
            \(htmlContent)
        </body>
        </html>
        """
    }

    private func wrapInHTML(plainText: String) -> String {
        let escaped = plainText
            .replacingOccurrences(of: "&", with: "&amp;")
            .replacingOccurrences(of: "<", with: "&lt;")
            .replacingOccurrences(of: ">", with: "&gt;")

        return wrapInHTML(htmlContent: "<pre style=\"white-space: pre-wrap; font-family: inherit;\">\(escaped)</pre>")
    }

    // MARK: - MIME Parsing

    private func extractHeader(_ name: String, from headers: String) -> String? {
        let lines = headers.components(separatedBy: "\n")
        for line in lines {
            if line.lowercased().hasPrefix(name.lowercased() + ":") {
                return String(line.dropFirst(name.count + 1)).trimmingCharacters(in: .whitespaces)
            }
        }
        return nil
    }

    private func extractBoundary(from contentType: String) -> String? {
        guard let range = contentType.range(of: "boundary=") else { return nil }
        var boundary = String(contentType[range.upperBound...])
        boundary = boundary.trimmingCharacters(in: CharacterSet(charactersIn: "\"' ;"))
        if let semicolon = boundary.firstIndex(of: ";") {
            boundary = String(boundary[..<semicolon])
        }
        return boundary
    }

    private func extractHTMLPart(from body: String, boundary: String?) -> String? {
        guard let boundary else { return nil }
        return extractPart(from: body, boundary: boundary, contentType: "text/html")
    }

    private func extractTextPart(from body: String, boundary: String?) -> String? {
        guard let boundary else { return nil }
        return extractPart(from: body, boundary: boundary, contentType: "text/plain")
    }

    private func extractPart(from body: String, boundary: String, contentType: String) -> String? {
        let separator = "--\(boundary)"
        let parts = body.components(separatedBy: separator)

        for part in parts {
            if part.lowercased().contains("content-type: \(contentType)") ||
               part.lowercased().contains("content-type:\(contentType)") {
                // Split headers and content
                let sections = part.components(separatedBy: "\n\n")
                if sections.count >= 2 {
                    let partHeaders = sections[0]
                    let content = sections.dropFirst().joined(separator: "\n\n")

                    // Check transfer encoding
                    let encoding = extractHeader("Content-Transfer-Encoding", from: partHeaders)?.lowercased() ?? ""
                    if encoding.contains("quoted-printable") {
                        return decodeQuotedPrintable(content)
                    } else if encoding.contains("base64") {
                        if let data = Data(base64Encoded: content.replacingOccurrences(of: "\n", with: ""),
                                          options: .ignoreUnknownCharacters),
                           let decoded = String(data: data, encoding: .utf8) {
                            return decoded
                        }
                    }
                    return content
                }
            }
        }
        return nil
    }

    // MARK: - Quoted-Printable Decoding

    private func decodeQuotedPrintable(_ input: String) -> String {
        var result = ""
        var i = input.startIndex

        // Remove soft line breaks (=\r\n or =\n)
        let cleaned = input
            .replacingOccurrences(of: "=\r\n", with: "")
            .replacingOccurrences(of: "=\n", with: "")

        i = cleaned.startIndex
        while i < cleaned.endIndex {
            let char = cleaned[i]
            if char == "=" {
                let nextIndex = cleaned.index(i, offsetBy: 1, limitedBy: cleaned.endIndex)
                let afterIndex = cleaned.index(i, offsetBy: 2, limitedBy: cleaned.endIndex)

                if let next = nextIndex, let after = afterIndex {
                    let hex = String(cleaned[next..<after])
                    if let byte = UInt8(hex, radix: 16) {
                        result.append(Character(UnicodeScalar(byte)))
                        i = after
                        continue
                    }
                }
            }
            result.append(char)
            i = cleaned.index(after: i)
        }

        return result
    }
}
