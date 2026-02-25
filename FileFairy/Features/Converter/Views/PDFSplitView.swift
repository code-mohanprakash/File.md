// PDFSplitView.swift
// FileFairy

import SwiftUI
import UniformTypeIdentifiers
import QuickLook

struct PDFSplitView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(AppEnvironment.self) private var appEnv
    @State private var viewModel = ConversionJobViewModel(conversionType: .pdfSplit)
    @State private var showFilePicker = false
    @State private var previewURL: URL?

    var body: some View {
        ScrollView {
            VStack(spacing: Spacing.lg) {
                // Header
                VStack(spacing: Spacing.sm) {
                    DuotoneIcon(
                        systemName: "scissors",
                        color: Color.Fairy.green,
                        size: 56
                    )
                    Text("Extract pages from a PDF")
                        .font(.Fairy.subtext)
                        .foregroundStyle(Color.Fairy.mist)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, Spacing.md)

                // File picker
                Button { showFilePicker = true } label: {
                    HStack(spacing: Spacing.sm) {
                        Image(systemName: viewModel.inputURLs.isEmpty ? "doc.badge.plus" : "checkmark.circle.fill")
                            .font(.system(size: 24))
                            .foregroundStyle(viewModel.inputURLs.isEmpty ? Color.Fairy.green : Color.Fairy.green)

                        Text(viewModel.inputURLs.isEmpty ? "Select PDF" : viewModel.inputDescription)
                            .font(.Fairy.body)
                            .foregroundStyle(Color.Fairy.ink)
                    }
                    .frame(maxWidth: .infinity)
                    .frame(height: 64)
                    .background(Color.Fairy.cream, in: RoundedRectangle.fairyLarge)
                    .overlay(
                        RoundedRectangle(cornerRadius: CornerRadius.lg, style: .continuous)
                            .strokeBorder(Color.Fairy.green.opacity(0.3), style: StrokeStyle(lineWidth: 2, dash: [8, 6]))
                    )
                }
                .buttonStyle(.plain)
                .pressScale(0.98)
                .padding(.horizontal, Spacing.md)

                // Page range picker
                if viewModel.totalPages > 0 {
                    VStack(alignment: .leading, spacing: Spacing.md) {
                        Text("Page Range")
                            .font(.Fairy.headline)
                            .foregroundStyle(Color.Fairy.ink)

                        Text("\(viewModel.totalPages) pages total")
                            .font(.Fairy.caption)
                            .foregroundStyle(Color.Fairy.mist)

                        HStack(spacing: Spacing.md) {
                            VStack(alignment: .leading) {
                                Text("From")
                                    .font(.Fairy.caption)
                                    .foregroundStyle(Color.Fairy.mist)
                                Stepper(
                                    "\(viewModel.splitStart)",
                                    value: $viewModel.splitStart,
                                    in: 1...max(1, viewModel.splitEnd)
                                )
                                .font(.Fairy.body)
                            }

                            VStack(alignment: .leading) {
                                Text("To")
                                    .font(.Fairy.caption)
                                    .foregroundStyle(Color.Fairy.mist)
                                Stepper(
                                    "\(viewModel.splitEnd)",
                                    value: $viewModel.splitEnd,
                                    in: max(1, viewModel.splitStart)...viewModel.totalPages
                                )
                                .font(.Fairy.body)
                            }
                        }

                        Text("Extracting pages \(viewModel.splitStart)–\(viewModel.splitEnd) (\(viewModel.splitEnd - viewModel.splitStart + 1) pages)")
                            .font(.Fairy.caption)
                            .foregroundStyle(Color.Fairy.green)
                    }
                    .padding(Spacing.md)
                    .background(Color.Fairy.cream, in: RoundedRectangle.fairyLarge)
                    .padding(.horizontal, Spacing.md)

                    // Split button
                    if !viewModel.isComplete {
                        FairyButton("Split PDF", style: .primary, color: Color.Fairy.green, isLoading: viewModel.isProcessing) {
                            Task { await viewModel.convert() }
                        }
                        .disabled(viewModel.isProcessing)
                        .padding(.horizontal, Spacing.md)
                    }
                }

                // Progress
                if viewModel.isProcessing {
                    ConversionProgressView(progress: viewModel.progress, type: .pdfSplit)
                        .padding(.horizontal, Spacing.md)
                }

                // Error
                if let error = viewModel.errorMessage {
                    FairyErrorView(message: error) { viewModel.reset() }
                        .padding(.horizontal, Spacing.md)
                }

                // Result
                if viewModel.isComplete, let url = viewModel.outputURL {
                    ConversionResultView(
                        outputURL: url,
                        conversionType: .pdfSplit,
                        onPreview: { previewURL = url },
                        onReset: { viewModel.reset() }
                    )
                    .padding(.horizontal, Spacing.md)
                }

                Spacer().frame(height: 100)
            }
            .padding(.top, Spacing.md)
        }
        .background(Color.Fairy.dust)
        .navigationTitle("Split PDF")
        .toolbarTitleDisplayMode(.inline)
        .fileImporter(
            isPresented: $showFilePicker,
            allowedContentTypes: [.pdf],
            allowsMultipleSelection: false
        ) { result in
            if case .success(let urls) = result, let url = urls.first {
                viewModel.inputURLs = [url]
                Task { await viewModel.loadPDFPageCount() }
            }
        }
        .quickLookPreview($previewURL)
        .onAppear { viewModel.setContext(modelContext) }
    }
}
