// CSVViewerView.swift
// FileFairy
//
// Renders a CSV file as a scrollable table.
// Header row is highlighted in violet. Uses Grid for structured layout.

import SwiftUI

// MARK: - CSVViewerView

struct CSVViewerView: View {

    let url: URL

    @State private var rows: [[String]] = []
    @State private var loadError: String? = nil
    @State private var isLoading = true

    // MARK: - Body

    var body: some View {
        NavigationStack {
            content
                .navigationTitle(url.lastPathComponent)
                .navigationBarTitleDisplayMode(.inline)
                .background(Color.Fairy.dust)
                .task { await loadCSV() }
        }
    }

    @ViewBuilder
    private var content: some View {
        if isLoading {
            ProgressView("Loading CSV…")
                .frame(maxWidth: .infinity, maxHeight: .infinity)
        } else if let error = loadError {
            FairyEmptyState(
                config: EmptyStateConfig(
                    systemImage: "exclamationmark.triangle",
                    imageColor: .Fairy.softRed,
                    title: "Cannot Read File",
                    subtitle: error
                )
            )
        } else if rows.isEmpty {
            FairyEmptyState(
                config: EmptyStateConfig(
                    systemImage: "tablecells",
                    imageColor: .Fairy.mist,
                    title: "Empty CSV",
                    subtitle: "The file contains no data rows."
                )
            )
        } else {
            ScrollView([.horizontal, .vertical]) {
                csvTable
                    .padding(Spacing.md)
            }
        }
    }

    // MARK: - CSV Table

    private var csvTable: some View {
        let columnCount = rows.first?.count ?? 0
        let columns = Array(repeating: GridItem(.fixed(columnWidth(count: columnCount)), spacing: 1), count: columnCount)

        return LazyVGrid(columns: columns, spacing: 1) {
            ForEach(Array(rows.enumerated()), id: \.offset) { rowIndex, row in
                ForEach(Array(row.enumerated()), id: \.offset) { colIndex, cell in
                    Text(cell)
                        .font(rowIndex == 0
                              ? .system(size: 13, weight: .semibold, design: .rounded)
                              : .system(size: 13, weight: .regular, design: .rounded))
                        .foregroundStyle(rowIndex == 0 ? Color.white : Color.Fairy.ink)
                        .lineLimit(2)
                        .truncationMode(.tail)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.horizontal, Spacing.sm)
                        .padding(.vertical, Spacing.xs)
                        .background(cellBackground(rowIndex: rowIndex))
                }
            }
        }
        .clipShape(RoundedRectangle(cornerRadius: CornerRadius.md, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: CornerRadius.md, style: .continuous)
                .strokeBorder(Color.Fairy.softEdge, lineWidth: 0.5)
        )
    }

    private func cellBackground(rowIndex: Int) -> Color {
        if rowIndex == 0 { return Color.Fairy.violet }
        return rowIndex % 2 == 0 ? Color.white : Color.Fairy.dust
    }

    private func columnWidth(count: Int) -> CGFloat {
        guard count > 0 else { return 120 }
        return max(80, min(200, UIScreen.main.bounds.width / CGFloat(count) - 2))
    }

    // MARK: - Data Loading

    private func loadCSV() async {
        isLoading = true
        loadError = nil

        let accessing = url.startAccessingSecurityScopedResource()
        defer { if accessing { url.stopAccessingSecurityScopedResource() } }

        do {
            let raw = try String(contentsOf: url, encoding: .utf8)
            rows = parseCSV(raw)
        } catch {
            loadError = error.localizedDescription
        }

        isLoading = false
    }

    private func parseCSV(_ text: String) -> [[String]] {
        let lines = text.components(separatedBy: .newlines)
            .filter { !$0.trimmingCharacters(in: .whitespaces).isEmpty }

        return lines.map { line in
            // Naive CSV split — handles quoted fields with commas
            var fields: [String] = []
            var current = ""
            var inQuotes = false

            for char in line {
                switch char {
                case "\"":
                    inQuotes.toggle()
                case ",":
                    if inQuotes {
                        current.append(char)
                    } else {
                        fields.append(current.trimmingCharacters(in: .whitespaces))
                        current = ""
                    }
                default:
                    current.append(char)
                }
            }
            fields.append(current.trimmingCharacters(in: .whitespaces))
            return fields
        }
    }
}

// MARK: - Preview

#Preview {
    // Create a temp CSV for preview
    let csv = "Name,Size,Type,Modified\nReport.pdf,2.3 MB,PDF,Today\nPhoto.jpg,1.1 MB,JPEG,Yesterday\nData.csv,44 KB,CSV,Monday"
    let url = FileManager.default.temporaryDirectory.appendingPathComponent("preview.csv")
    try? csv.write(to: url, atomically: true, encoding: .utf8)
    return CSVViewerView(url: url)
}
