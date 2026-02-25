// PDFCompressView.swift
// FileFairy

import SwiftUI
import UniformTypeIdentifiers
import QuickLook

struct PDFCompressView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(AppEnvironment.self) private var appEnv
    @State private var viewModel = ConversionJobViewModel(conversionType: .pdfCompress)
    @State private var showFilePicker = false
    @State private var previewURL: URL?

    var body: some View {
        ScrollView {
            VStack(spacing: Spacing.lg) {
                // Header
                VStack(spacing: Spacing.sm) {
                    DuotoneIcon(
                        systemName: "arrow.down.doc.fill",
                        color: Color.Fairy.green,
                        size: 56
                    )
                    Text("Reduce PDF file size")
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
                            .foregroundStyle(Color.Fairy.green)

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

                // Quality picker
                if !viewModel.inputURLs.isEmpty {
                    VStack(alignment: .leading, spacing: Spacing.md) {
                        Text("Compression Level")
                            .font(.Fairy.headline)
                            .foregroundStyle(Color.Fairy.ink)

                        ForEach(PDFCompressionService.Quality.allCases, id: \.rawValue) { quality in
                            Button {
                                withAnimation(.fairySnappy) {
                                    viewModel.compressionQuality = quality
                                }
                            } label: {
                                HStack {
                                    VStack(alignment: .leading, spacing: 2) {
                                        Text(quality.rawValue.capitalized)
                                            .font(.Fairy.body)
                                            .foregroundStyle(Color.Fairy.ink)
                                        Text(quality.displayName)
                                            .font(.Fairy.micro)
                                            .foregroundStyle(Color.Fairy.mist)
                                    }
                                    Spacer()
                                    if viewModel.compressionQuality == quality {
                                        Image(systemName: "checkmark.circle.fill")
                                            .foregroundStyle(Color.Fairy.green)
                                            .font(.system(size: 20))
                                    }
                                }
                                .padding(Spacing.sm)
                                .background(
                                    viewModel.compressionQuality == quality
                                        ? Color.Fairy.green.opacity(0.08)
                                        : Color.clear,
                                    in: RoundedRectangle.fairyMedium
                                )
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    .padding(Spacing.md)
                    .background(Color.Fairy.cream, in: RoundedRectangle.fairyLarge)
                    .padding(.horizontal, Spacing.md)

                    // Compress button
                    if !viewModel.isComplete {
                        FairyButton("Compress PDF", style: .primary, color: Color.Fairy.green, isLoading: viewModel.isProcessing) {
                            Task { await viewModel.convert() }
                        }
                        .disabled(viewModel.isProcessing)
                        .padding(.horizontal, Spacing.md)
                    }
                }

                // Progress
                if viewModel.isProcessing {
                    ConversionProgressView(progress: viewModel.progress, type: .pdfCompress)
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
                        conversionType: .pdfCompress,
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
        .navigationTitle("Compress PDF")
        .toolbarTitleDisplayMode(.inline)
        .fileImporter(
            isPresented: $showFilePicker,
            allowedContentTypes: [.pdf],
            allowsMultipleSelection: false
        ) { result in
            if case .success(let urls) = result, let url = urls.first {
                viewModel.inputURLs = [url]
            }
        }
        .quickLookPreview($previewURL)
        .onAppear { viewModel.setContext(modelContext) }
    }
}
