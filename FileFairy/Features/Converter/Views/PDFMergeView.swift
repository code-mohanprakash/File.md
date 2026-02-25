// PDFMergeView.swift
// FileFairy

import SwiftUI
import UniformTypeIdentifiers
import QuickLook

struct PDFMergeView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(AppEnvironment.self) private var appEnv
    @State private var viewModel: ConversionJobViewModel = ConversionJobViewModel(conversionType: .pdfMerge)
    @State private var showFilePicker = false
    @State private var previewURL: URL?

    var body: some View {
        ScrollView {
            VStack(spacing: Spacing.lg) {
                headerView
                fileListView
                addButton
                mergeButton
                progressView
                errorView
                resultView
                Spacer().frame(height: 100)
            }
            .padding(.top, Spacing.md)
        }
        .background(Color.Fairy.dust)
        .navigationTitle("Merge PDFs")
        .toolbarTitleDisplayMode(.inline)
        .fileImporter(
            isPresented: $showFilePicker,
            allowedContentTypes: [.pdf],
            allowsMultipleSelection: true
        ) { result in
            if case .success(let urls) = result {
                viewModel.inputURLs.append(contentsOf: urls)
            }
        }
        .quickLookPreview($previewURL)
        .onAppear { viewModel.setContext(modelContext) }
    }

    // MARK: - Sub-views

    private var headerView: some View {
        VStack(spacing: Spacing.sm) {
            DuotoneIcon(
                systemName: "arrow.triangle.merge",
                color: Color.Fairy.green,
                size: 56
            )
            Text("Combine multiple PDFs into one")
                .font(.Fairy.subtext)
                .foregroundStyle(Color.Fairy.mist)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, Spacing.md)
    }

    @ViewBuilder
    private var fileListView: some View {
        if !viewModel.inputURLs.isEmpty {
            VStack(alignment: .leading, spacing: Spacing.sm) {
                HStack {
                    Text("\(viewModel.inputURLs.count) PDFs")
                        .font(.Fairy.headline)
                        .foregroundStyle(Color.Fairy.ink)
                    Spacer()
                    Button("Clear") {
                        withAnimation(.fairySnappy) { viewModel.inputURLs.removeAll() }
                    }
                    .font(.Fairy.caption)
                    .foregroundStyle(Color.Fairy.mist)
                }

                ForEach(Array(viewModel.inputURLs.enumerated()), id: \.offset) { (index, url) in
                    HStack(spacing: Spacing.sm) {
                        Image(systemName: "doc.fill")
                            .foregroundStyle(Color.Fairy.green)
                            .font(.system(size: 16))
                        Text(url.lastPathComponent)
                            .font(.Fairy.body)
                            .foregroundStyle(Color.Fairy.ink)
                            .lineLimit(1)
                        Spacer()
                        Text("#\(index + 1)")
                            .font(.Fairy.micro)
                            .foregroundStyle(Color.Fairy.mist)
                        Button {
                            let i: Int = index
                            withAnimation(.fairySnappy) {
                                viewModel.inputURLs.remove(at: i)
                            }
                        } label: {
                            Image(systemName: "xmark.circle.fill")
                                .foregroundStyle(Color.Fairy.mist)
                                .font(.system(size: 18))
                        }
                    }
                    .padding(Spacing.sm)
                    .background(Color.Fairy.cream, in: RoundedRectangle.fairyMedium)
                }
            }
            .padding(.horizontal, Spacing.md)
        }
    }

    private var addButton: some View {
        let dashStyle = StrokeStyle(lineWidth: 2, dash: [8, 6])
        let label = viewModel.inputURLs.isEmpty ? "Select PDFs" : "Add More PDFs"
        return Button { showFilePicker = true } label: {
            HStack(spacing: Spacing.sm) {
                Image(systemName: "plus.circle.fill")
                    .font(.system(size: 20))
                Text(label)
                    .font(.Fairy.body)
            }
            .foregroundStyle(Color.Fairy.green)
            .frame(maxWidth: .infinity)
            .frame(height: 56)
            .background(Color.Fairy.green.opacity(0.1), in: RoundedRectangle.fairyLarge)
            .overlay {
                RoundedRectangle(cornerRadius: CornerRadius.lg, style: .continuous)
                    .strokeBorder(Color.Fairy.green.opacity(0.3), style: dashStyle)
            }
        }
        .buttonStyle(.plain)
        .pressScale(0.98)
        .padding(.horizontal, Spacing.md)
    }

    @ViewBuilder
    private var mergeButton: some View {
        if viewModel.inputURLs.count >= 2 && !viewModel.isComplete {
            FairyButton("Merge PDFs", style: .primary, color: Color.Fairy.green, isLoading: viewModel.isProcessing) {
                Task { await viewModel.convert() }
            }
            .disabled(viewModel.isProcessing)
            .padding(.horizontal, Spacing.md)
        }
    }

    @ViewBuilder
    private var progressView: some View {
        if viewModel.isProcessing {
            ConversionProgressView(progress: viewModel.progress, type: .pdfMerge)
                .padding(.horizontal, Spacing.md)
        }
    }

    @ViewBuilder
    private var errorView: some View {
        if let error = viewModel.errorMessage {
            FairyErrorView(message: error) { viewModel.reset() }
                .padding(.horizontal, Spacing.md)
        }
    }

    @ViewBuilder
    private var resultView: some View {
        if viewModel.isComplete, let url = viewModel.outputURL {
            ConversionResultView(
                outputURL: url,
                conversionType: .pdfMerge,
                onPreview: { previewURL = url },
                onReset: { viewModel.reset() }
            )
            .padding(.horizontal, Spacing.md)
        }
    }
}
