// ScanExportSheet.swift
// FileFairy
//
// Export options: name scan, choose PDF or JPEG, save/share.
// From PRD: Name your scan (default: "Scan [date]"), choose PDF or JPEG.

import SwiftUI

struct ScanExportSheet: View {

    @Bindable var viewModel: ScannerViewModel
    @Environment(\.dismiss) private var dismiss
    @State private var exportFormat: ExportFormat = .pdf
    @State private var isExporting = false
    @State private var exportedURL: URL?
    @State private var showShareSheet = false
    @State private var errorMessage: String?

    enum ExportFormat: String, CaseIterable {
        case pdf = "PDF"
        case jpeg = "JPEG"
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: Spacing.lg) {

                // Scan name
                VStack(alignment: .leading, spacing: Spacing.xs) {
                    Text("Scan Name")
                        .font(.Fairy.subtext)
                        .foregroundStyle(Color.Fairy.mist)

                    TextField(
                        "Scan \(Date().formatted(date: .abbreviated, time: .shortened))",
                        text: $viewModel.sessionTitle
                    )
                    .font(.Fairy.body)
                    .padding(Spacing.sm)
                    .background(Color.Fairy.dust, in: RoundedRectangle.fairyMedium)
                }

                // Format picker
                VStack(alignment: .leading, spacing: Spacing.xs) {
                    Text("Format")
                        .font(.Fairy.subtext)
                        .foregroundStyle(Color.Fairy.mist)

                    Picker("Format", selection: $exportFormat) {
                        ForEach(ExportFormat.allCases, id: \.self) { format in
                            Text(format.rawValue).tag(format)
                        }
                    }
                    .pickerStyle(.segmented)
                }

                // Page count info
                HStack {
                    Image(systemName: "doc.on.doc.fill")
                        .foregroundStyle(Color.Fairy.violet)
                    Text("\(viewModel.pageCount) page\(viewModel.pageCount == 1 ? "" : "s")")
                        .font(.Fairy.body)
                        .foregroundStyle(Color.Fairy.slate)
                    Spacer()
                }
                .padding(Spacing.sm)
                .background(Color.Fairy.dust, in: RoundedRectangle.fairyMedium)

                Spacer()

                // Export buttons
                VStack(spacing: Spacing.sm) {
                    // Save button
                    Button {
                        Task { await exportAndSave() }
                    } label: {
                        HStack {
                            if isExporting {
                                ProgressView()
                                    .tint(.white)
                            } else {
                                Image(systemName: "square.and.arrow.down.fill")
                            }
                            Text(isExporting ? "Saving..." : "Save to Files")
                        }
                        .font(.Fairy.button)
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, Spacing.sm)
                        .background(Color.Fairy.violet, in: .capsule)
                    }
                    .disabled(isExporting)

                    // Share button
                    Button {
                        Task {
                            await exportAndSave()
                            showShareSheet = true
                        }
                    } label: {
                        HStack {
                            Image(systemName: "square.and.arrow.up")
                            Text("Share")
                        }
                        .font(.Fairy.button)
                        .foregroundStyle(Color.Fairy.violet)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, Spacing.sm)
                        .background(Color.Fairy.dust, in: .capsule)
                        .overlay(Capsule().stroke(Color.Fairy.violet, lineWidth: 1.5))
                    }
                    .disabled(isExporting)
                }

                if let errorMessage {
                    Text(errorMessage)
                        .font(.Fairy.caption)
                        .foregroundStyle(Color.Fairy.softRed)
                }
            }
            .padding(Spacing.lg)
            .background(Color.Fairy.cream)
            .navigationTitle("Export Scan")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
            }
        }
        .sheet(isPresented: $showShareSheet) {
            if let url = exportedURL {
                ShareSheet(items: [url])
            }
        }
    }

    private func exportAndSave() async {
        isExporting = true
        errorMessage = nil

        do {
            switch exportFormat {
            case .pdf:
                exportedURL = try await viewModel.exportAsPDF()
            case .jpeg:
                let urls = try await viewModel.exportAsJPEG()
                exportedURL = urls.first
            }
        } catch {
            errorMessage = error.localizedDescription
        }

        isExporting = false
    }
}
