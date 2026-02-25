// TextViewerService.swift
// FileFairy
//
// Streaming reader for CSV, JSON, and plain text files.
// Returns structured data suitable for SwiftUI presentation.

import Foundation

actor TextViewerService {

    // MARK: - CSV

    struct CSVData: Sendable {
        let headers: [String]
        let rows: [[String]]
        let rowCount: Int
        let columnCount: Int
    }

    func parseCSV(url: URL, delimiter: Character = ",", maxRows: Int = 10_000) async throws -> CSVData {
        guard url.startAccessingSecurityScopedResource() || true else {
            throw AppError.fileNotFound(url.lastPathComponent)
        }
        defer { url.stopAccessingSecurityScopedResource() }

        guard let data = try? Data(contentsOf: url),
              let content = String(data: data, encoding: .utf8) ?? String(data: data, encoding: .isoLatin1) else {
            throw AppError.corruptFile("Cannot read \(url.lastPathComponent)")
        }

        let lines = content.components(separatedBy: .newlines).filter { !$0.isEmpty }
        guard !lines.isEmpty else {
            throw AppError.corruptFile("CSV file is empty")
        }

        let headers = parseCSVLine(lines[0], delimiter: delimiter)
        var rows: [[String]] = []

        for i in 1..<min(lines.count, maxRows + 1) {
            let row = parseCSVLine(lines[i], delimiter: delimiter)
            rows.append(row)
        }

        return CSVData(
            headers: headers,
            rows: rows,
            rowCount: rows.count,
            columnCount: headers.count
        )
    }

    private func parseCSVLine(_ line: String, delimiter: Character) -> [String] {
        var fields: [String] = []
        var current = ""
        var inQuotes = false

        for char in line {
            if char == "\"" {
                inQuotes.toggle()
            } else if char == delimiter && !inQuotes {
                fields.append(current.trimmingCharacters(in: .whitespaces))
                current = ""
            } else {
                current.append(char)
            }
        }
        fields.append(current.trimmingCharacters(in: .whitespaces))
        return fields
    }

    // MARK: - JSON

    enum JSONNode: Sendable {
        case object([(key: String, value: JSONNode)])
        case array([JSONNode])
        case string(String)
        case number(Double)
        case bool(Bool)
        case null

        var displayType: String {
            switch self {
            case .object(let pairs): return "Object (\(pairs.count) keys)"
            case .array(let items):  return "Array (\(items.count) items)"
            case .string:            return "String"
            case .number:            return "Number"
            case .bool:              return "Boolean"
            case .null:              return "Null"
            }
        }
    }

    func parseJSON(url: URL) async throws -> JSONNode {
        guard url.startAccessingSecurityScopedResource() || true else {
            throw AppError.fileNotFound(url.lastPathComponent)
        }
        defer { url.stopAccessingSecurityScopedResource() }

        let data = try Data(contentsOf: url)
        let jsonObject = try JSONSerialization.jsonObject(with: data, options: [.fragmentsAllowed])
        return convertToNode(jsonObject)
    }

    func prettyPrintJSON(url: URL) async throws -> String {
        guard url.startAccessingSecurityScopedResource() || true else {
            throw AppError.fileNotFound(url.lastPathComponent)
        }
        defer { url.stopAccessingSecurityScopedResource() }

        let data = try Data(contentsOf: url)
        let jsonObject = try JSONSerialization.jsonObject(with: data, options: [.fragmentsAllowed])
        let prettyData = try JSONSerialization.data(withJSONObject: jsonObject, options: [.prettyPrinted, .sortedKeys])
        guard let prettyString = String(data: prettyData, encoding: .utf8) else {
            throw AppError.parsingError("Cannot format JSON")
        }
        return prettyString
    }

    private func convertToNode(_ value: Any) -> JSONNode {
        switch value {
        case let dict as [String: Any]:
            let pairs = dict.sorted { $0.key < $1.key }.map { (key: $0.key, value: convertToNode($0.value)) }
            return .object(pairs)
        case let array as [Any]:
            return .array(array.map { convertToNode($0) })
        case let string as String:
            return .string(string)
        case let number as NSNumber:
            if CFBooleanGetTypeID() == CFGetTypeID(number) {
                return .bool(number.boolValue)
            }
            return .number(number.doubleValue)
        case is NSNull:
            return .null
        default:
            return .string(String(describing: value))
        }
    }

    // MARK: - Plain Text

    struct TextData: Sendable {
        let content: String
        let lineCount: Int
        let characterCount: Int
        let encoding: String
    }

    func readText(url: URL, maxCharacters: Int = 500_000) async throws -> TextData {
        guard url.startAccessingSecurityScopedResource() || true else {
            throw AppError.fileNotFound(url.lastPathComponent)
        }
        defer { url.stopAccessingSecurityScopedResource() }

        let data = try Data(contentsOf: url)
        let encodingName: String
        let content: String

        if let utf8 = String(data: data, encoding: .utf8) {
            content = utf8
            encodingName = "UTF-8"
        } else if let latin1 = String(data: data, encoding: .isoLatin1) {
            content = latin1
            encodingName = "ISO-8859-1"
        } else if let ascii = String(data: data, encoding: .ascii) {
            content = ascii
            encodingName = "ASCII"
        } else {
            throw AppError.corruptFile("Cannot determine text encoding")
        }

        let truncated = content.count > maxCharacters
            ? String(content.prefix(maxCharacters))
            : content

        let lineCount = truncated.components(separatedBy: .newlines).count

        return TextData(
            content: truncated,
            lineCount: lineCount,
            characterCount: content.count,
            encoding: encodingName
        )
    }
}
