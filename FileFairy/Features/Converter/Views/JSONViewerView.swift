// JSONViewerView.swift
// FileFairy
//
// Pretty-prints a JSON file with basic syntax highlighting.
// Keys in violet, string values in green, numbers in amber.
// Displayed in a monospaced ScrollView.

import SwiftUI

// MARK: - JSONViewerView

struct JSONViewerView: View {

    let url: URL

    @State private var highlightedText: AttributedString = AttributedString()
    @State private var rawText: String = ""
    @State private var loadError: String? = nil
    @State private var isLoading = true

    // MARK: - Body

    var body: some View {
        NavigationStack {
            content
                .navigationTitle(url.lastPathComponent)
                .navigationBarTitleDisplayMode(.inline)
                .background(Color.Fairy.dust)
                .task { await loadJSON() }
        }
    }

    @ViewBuilder
    private var content: some View {
        if isLoading {
            ProgressView("Parsing JSON…")
                .frame(maxWidth: .infinity, maxHeight: .infinity)
        } else if let error = loadError {
            FairyEmptyState(
                config: EmptyStateConfig(
                    systemImage: "exclamationmark.triangle",
                    imageColor: .Fairy.softRed,
                    title: "Cannot Parse JSON",
                    subtitle: error
                )
            )
        } else {
            ScrollView {
                Text(highlightedText)
                    .font(.system(size: 12, design: .monospaced))
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(Spacing.md)
                    .textSelection(.enabled)
            }
            .background(Color.white)
        }
    }

    // MARK: - JSON Loading

    private func loadJSON() async {
        isLoading = true
        loadError = nil

        let accessing = url.startAccessingSecurityScopedResource()
        defer { if accessing { url.stopAccessingSecurityScopedResource() } }

        do {
            let data = try Data(contentsOf: url)
            // Pretty-print
            let obj = try JSONSerialization.jsonObject(with: data)
            let prettyData = try JSONSerialization.data(withJSONObject: obj, options: [.prettyPrinted, .sortedKeys])
            rawText = String(decoding: prettyData, as: UTF8.self)
            highlightedText = buildHighlightedText(rawText)
        } catch {
            loadError = error.localizedDescription
        }

        isLoading = false
    }

    // MARK: - Syntax Highlighting

    private func buildHighlightedText(_ source: String) -> AttributedString {
        var result = AttributedString()

        // Tokenise line-by-line for a clean enough highlight pass
        let lines = source.components(separatedBy: "\n")
        for (lineIndex, line) in lines.enumerated() {
            var lineAttr = tokeniseLine(line)
            if lineIndex < lines.count - 1 {
                lineAttr.append(AttributedString("\n"))
            }
            result.append(lineAttr)
        }
        return result
    }

    /// Applies colour to a single JSON line.
    private func tokeniseLine(_ line: String) -> AttributedString {
        // Regex-free token scan using character inspection
        var result = AttributedString()

        // Trim leading whitespace (preserve it as-is)
        let trimmed = line
        let indent = String(line.prefix(while: { $0 == " " }))

        if !indent.isEmpty {
            result.append(AttributedString(indent))
        }

        let body = String(trimmed.dropFirst(indent.count))

        // Detect pattern: "key": value
        if let colonRange = body.range(of: "\":") {
            // Key portion
            let keyPart = String(body[body.startIndex...colonRange.lowerBound])
            var keyAttr = AttributedString(keyPart + "\":")
            keyAttr.foregroundColor = UIColor(Color.Fairy.violet)
            result.append(keyAttr)

            // Value portion
            let afterColon = String(body[colonRange.upperBound...])
            result.append(colourValue(afterColon.trimmingCharacters(in: .init(charactersIn: " "))))
        } else {
            // Could be a standalone value, closing brace/bracket, or pure string
            result.append(colourValue(body))
        }

        return result
    }

    private func colourValue(_ text: String) -> AttributedString {
        var attr = AttributedString(" " + text)

        if text.hasPrefix("\"") {
            // String value — green
            attr.foregroundColor = UIColor(Color(hex: "#059669"))
        } else if text.first?.isNumber == true || text.hasPrefix("-") {
            // Number — amber
            attr.foregroundColor = UIColor(Color.Fairy.amber)
        } else if text == "true" || text == "false" {
            // Boolean — teal
            attr.foregroundColor = UIColor(Color.Fairy.teal)
        } else if text == "null" {
            // Null — mist
            attr.foregroundColor = UIColor(Color.Fairy.mist)
        } else {
            // Structural characters
            attr.foregroundColor = UIColor(Color.Fairy.ink)
        }

        return attr
    }
}

// MARK: - Preview

#Preview {
    let json = """
    {
      "name": "FileFairy",
      "version": "1.0.0",
      "features": ["scan", "convert", "mbox"],
      "count": 42,
      "active": true,
      "metadata": null
    }
    """
    let url = FileManager.default.temporaryDirectory.appendingPathComponent("preview.json")
    try? json.write(to: url, atomically: true, encoding: .utf8)
    return JSONViewerView(url: url)
}
