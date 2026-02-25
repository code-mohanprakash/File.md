// ImageConverterView.swift
// FileFairy
//
// Generic conversion view for image formats, image-to-PDF,
// ZIP extract, CSV/JSON/text viewing, and image resize/compress.

import SwiftUI
import QuickLook

struct ImageConverterView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(AppEnvironment.self) private var appEnv
    @State private var viewModel: ConversionJobViewModel
    @State private var showFilePicker = false
    @State private var previewURL: URL?

    init(conversionType: ConversionType) {
        _viewModel = State(initialValue: ConversionJobViewModel(conversionType: conversionType))
    }

    var body: some View {
        ScrollView {
            VStack(spacing: Spacing.lg) {
                // Header
                headerSection

                // File picker
                filePickerSection

                // Options (if applicable)
                optionsSection

                // Convert button
                if !viewModel.inputURLs.isEmpty && !viewModel.isComplete {
                    convertButton
                }

                // Progress
                if viewModel.isProcessing {
                    ConversionProgressView(progress: viewModel.progress, type: viewModel.conversionType)
                }

                // Error
                if let error = viewModel.errorMessage {
                    FairyErrorView(message: error) {
                        viewModel.reset()
                    }
                }

                // Result
                if viewModel.isComplete {
                    resultSection
                }

                Spacer().frame(height: 100)
            }
            .padding(.horizontal, Spacing.md)
            .padding(.top, Spacing.md)
        }
        .background(Color.Fairy.dust)
        .navigationTitle(viewModel.conversionType.displayName)
        .toolbarTitleDisplayMode(.inline)
        .fileImporter(
            isPresented: $showFilePicker,
            allowedContentTypes: viewModel.allowedContentTypes,
            allowsMultipleSelection: viewModel.allowsMultipleSelection
        ) { result in
            handleFileSelection(result)
        }
        .quickLookPreview($previewURL)
        .onAppear { viewModel.setContext(modelContext) }
    }

    // MARK: - Header

    private var headerSection: some View {
        VStack(spacing: Spacing.sm) {
            DuotoneIcon(
                systemName: viewModel.conversionType.icon,
                color: viewModel.conversionType.featureColor,
                size: 56
            )

            Text(viewModel.conversionType.subtitle)
                .font(.Fairy.subtext)
                .foregroundStyle(Color.Fairy.mist)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, Spacing.lg)
    }

    // MARK: - File Picker

    private var filePickerSection: some View {
        Button { showFilePicker = true } label: {
            VStack(spacing: Spacing.sm) {
                Image(systemName: viewModel.inputURLs.isEmpty ? "doc.badge.plus" : "checkmark.circle.fill")
                    .font(.system(size: 32))
                    .foregroundStyle(viewModel.inputURLs.isEmpty ? Color.Fairy.amber : Color.Fairy.green)

                Text(viewModel.inputURLs.isEmpty ? "Select File" : viewModel.inputDescription)
                    .font(.Fairy.body)
                    .foregroundStyle(Color.Fairy.ink)

                if viewModel.inputURLs.isEmpty {
                    Text("Tap to browse")
                        .font(.Fairy.caption)
                        .foregroundStyle(Color.Fairy.mist)
                }
            }
            .frame(maxWidth: .infinity)
            .frame(height: 120)
            .background(Color.Fairy.cream, in: RoundedRectangle.fairyXL)
            .overlay(
                RoundedRectangle(cornerRadius: CornerRadius.xl, style: .continuous)
                    .strokeBorder(
                        viewModel.inputURLs.isEmpty
                            ? Color.Fairy.amber.opacity(0.3)
                            : Color.Fairy.green.opacity(0.3),
                        style: StrokeStyle(lineWidth: 2, dash: [8, 6])
                    )
            )
        }
        .buttonStyle(.plain)
        .pressScale(0.98)
    }

    // MARK: - Options

    @ViewBuilder
    private var optionsSection: some View {
        if !viewModel.inputURLs.isEmpty {
            switch viewModel.conversionType {
            case .heicToJpeg, .webpToJpeg, .pngToJpeg, .imageCompress:
                qualitySlider

            case .imageResize:
                resizeOptions

            default:
                EmptyView()
            }
        }
    }

    private var qualitySlider: some View {
        VStack(alignment: .leading, spacing: Spacing.sm) {
            HStack {
                Text("Quality")
                    .font(.Fairy.body)
                    .foregroundStyle(Color.Fairy.ink)
                Spacer()
                Text("\(Int(viewModel.imageQuality * 100))%")
                    .font(.Fairy.caption)
                    .foregroundStyle(Color.Fairy.amber)
                    .fontWeight(.semibold)
            }

            Slider(value: $viewModel.imageQuality, in: 0.1...1.0, step: 0.05)
                .tint(Color.Fairy.amber)

            HStack {
                Text("Smaller file")
                    .font(.Fairy.micro)
                    .foregroundStyle(Color.Fairy.mist)
                Spacer()
                Text("Better quality")
                    .font(.Fairy.micro)
                    .foregroundStyle(Color.Fairy.mist)
            }
        }
        .padding(Spacing.md)
        .background(Color.Fairy.cream, in: RoundedRectangle.fairyLarge)
    }

    private var resizeOptions: some View {
        VStack(alignment: .leading, spacing: Spacing.md) {
            Picker("Resize Method", selection: $viewModel.usePercentage) {
                Text("Percentage").tag(true)
                Text("Dimensions").tag(false)
            }
            .pickerStyle(.segmented)

            if viewModel.usePercentage {
                VStack(alignment: .leading, spacing: Spacing.sm) {
                    HStack {
                        Text("Scale")
                            .font(.Fairy.body)
                            .foregroundStyle(Color.Fairy.ink)
                        Spacer()
                        Text("\(Int(viewModel.resizeScale * 100))%")
                            .font(.Fairy.caption)
                            .foregroundStyle(Color.Fairy.amber)
                            .fontWeight(.semibold)
                    }
                    Slider(value: $viewModel.resizeScale, in: 0.1...1.0, step: 0.05)
                        .tint(Color.Fairy.amber)
                }
            } else {
                HStack(spacing: Spacing.md) {
                    VStack(alignment: .leading) {
                        Text("Width")
                            .font(.Fairy.caption)
                            .foregroundStyle(Color.Fairy.mist)
                        TextField("Width", value: $viewModel.resizeWidth, format: .number)
                            .textFieldStyle(.roundedBorder)
                            .keyboardType(.numberPad)
                    }
                    VStack(alignment: .leading) {
                        Text("Height")
                            .font(.Fairy.caption)
                            .foregroundStyle(Color.Fairy.mist)
                        TextField("Height", value: $viewModel.resizeHeight, format: .number)
                            .textFieldStyle(.roundedBorder)
                            .keyboardType(.numberPad)
                    }
                }
            }
        }
        .padding(Spacing.md)
        .background(Color.Fairy.cream, in: RoundedRectangle.fairyLarge)
    }

    // MARK: - Convert Button

    private var convertButton: some View {
        FairyButton(
            viewModel.conversionType.category == .fileTools ? "Open" : "Convert",
            style: .primary,
            color: viewModel.conversionType.featureColor,
            isLoading: viewModel.isProcessing
        ) {
            Task { await viewModel.convert() }
        }
        .disabled(viewModel.isProcessing)
    }

    // MARK: - Result

    @ViewBuilder
    private var resultSection: some View {
        if let url = viewModel.outputURL {
            ConversionResultView(
                outputURL: url,
                conversionType: viewModel.conversionType,
                onPreview: { previewURL = url },
                onReset: { viewModel.reset() }
            )
        } else if let csv = viewModel.csvData {
            csvResultView(csv)
        } else if let json = viewModel.jsonText {
            jsonResultView(json)
        } else if let text = viewModel.textData {
            textResultView(text)
        }
    }

    private func csvResultView(_ csv: TextViewerService.CSVData) -> some View {
        VStack(alignment: .leading, spacing: Spacing.sm) {
            HStack {
                Text("\(csv.rowCount) rows, \(csv.columnCount) columns")
                    .font(.Fairy.caption)
                    .foregroundStyle(Color.Fairy.mist)
                Spacer()
                Button("Done") { viewModel.reset() }
                    .font(.Fairy.caption)
                    .foregroundStyle(Color.Fairy.amber)
            }

            ScrollView(.horizontal, showsIndicators: true) {
                VStack(alignment: .leading, spacing: 1) {
                    // Headers
                    HStack(spacing: 1) {
                        ForEach(csv.headers, id: \.self) { header in
                            Text(header)
                                .font(.Fairy.caption)
                                .fontWeight(.semibold)
                                .foregroundStyle(Color.Fairy.ink)
                                .frame(width: 120, alignment: .leading)
                                .padding(Spacing.xs)
                                .background(Color.Fairy.amber.opacity(0.1))
                        }
                    }

                    // Rows
                    ForEach(Array(csv.rows.prefix(100).enumerated()), id: \.offset) { _, row in
                        HStack(spacing: 1) {
                            ForEach(Array(row.enumerated()), id: \.offset) { _, cell in
                                Text(cell)
                                    .font(.Fairy.micro)
                                    .foregroundStyle(Color.Fairy.slate)
                                    .frame(width: 120, alignment: .leading)
                                    .padding(Spacing.xs)
                                    .lineLimit(2)
                            }
                        }
                    }
                }
            }
            .background(Color.Fairy.cream, in: RoundedRectangle.fairyLarge)
        }
    }

    private func jsonResultView(_ json: String) -> some View {
        VStack(alignment: .leading, spacing: Spacing.sm) {
            HStack {
                Text("JSON")
                    .font(.Fairy.caption)
                    .foregroundStyle(Color.Fairy.mist)
                Spacer()
                Button("Copy") {
                    UIPasteboard.general.string = json
                }
                .font(.Fairy.caption)
                .foregroundStyle(Color.Fairy.amber)

                Button("Done") { viewModel.reset() }
                    .font(.Fairy.caption)
                    .foregroundStyle(Color.Fairy.amber)
            }

            ScrollView {
                Text(json)
                    .font(.system(.caption, design: .monospaced))
                    .foregroundStyle(Color.Fairy.ink)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(Spacing.sm)
            }
            .frame(maxHeight: 400)
            .background(Color.Fairy.cream, in: RoundedRectangle.fairyLarge)
        }
    }

    private func textResultView(_ text: TextViewerService.TextData) -> some View {
        VStack(alignment: .leading, spacing: Spacing.sm) {
            HStack {
                Text("\(text.lineCount) lines • \(text.encoding)")
                    .font(.Fairy.caption)
                    .foregroundStyle(Color.Fairy.mist)
                Spacer()
                Button("Copy") {
                    UIPasteboard.general.string = text.content
                }
                .font(.Fairy.caption)
                .foregroundStyle(Color.Fairy.amber)

                Button("Done") { viewModel.reset() }
                    .font(.Fairy.caption)
                    .foregroundStyle(Color.Fairy.amber)
            }

            ScrollView {
                Text(text.content)
                    .font(.system(.caption, design: .monospaced))
                    .foregroundStyle(Color.Fairy.ink)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(Spacing.sm)
            }
            .frame(maxHeight: 400)
            .background(Color.Fairy.cream, in: RoundedRectangle.fairyLarge)
        }
    }

    // MARK: - Helpers

    private func handleFileSelection(_ result: Result<[URL], Error>) {
        switch result {
        case .success(let urls):
            viewModel.inputURLs = urls
            if viewModel.conversionType == .pdfSplit {
                Task { await viewModel.loadPDFPageCount() }
            }
        case .failure:
            viewModel.errorMessage = "Could not access the selected file"
        }
    }
}
