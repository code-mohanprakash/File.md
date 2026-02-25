// ConversionJobViewModel.swift
// FileFairy

import SwiftUI
import SwiftData
import Observation
import UniformTypeIdentifiers

@Observable
final class ConversionJobViewModel {

    // MARK: - State

    let conversionType: ConversionType
    var inputURLs: [URL] = []
    var outputURL: URL?
    var isProcessing = false
    var progress: Double = 0
    var errorMessage: String?
    var isComplete = false

    // Image conversion options
    var imageQuality: CGFloat = 0.9

    // PDF split options
    var splitStart: Int = 1
    var splitEnd: Int = 1
    var totalPages: Int = 0

    // PDF compression options
    var compressionQuality: PDFCompressionService.Quality = .medium

    // Image resize options
    var resizeWidth: Int = 1024
    var resizeHeight: Int = 1024
    var resizeScale: CGFloat = 0.5
    var usePercentage: Bool = true

    // MARK: - Private

    private let imageService = ImageConversionService()
    private let pdfMergeService = PDFMergeService()
    private let pdfSplitService = PDFSplitService()
    private let pdfCompressionService = PDFCompressionService()
    private let imageResizeService = ImageResizeService()
    private let zipService = ZIPService()
    private let textService = TextViewerService()
    private var modelContext: ModelContext?

    // Text viewer data
    var csvData: TextViewerService.CSVData?
    var jsonText: String?
    var textData: TextViewerService.TextData?

    // MARK: - Init

    init(conversionType: ConversionType) {
        self.conversionType = conversionType
    }

    func setContext(_ context: ModelContext) {
        self.modelContext = context
    }

    // MARK: - File Input

    var allowedContentTypes: [UTType] {
        switch conversionType {
        case .heicToJpeg, .heicToPng:
            return [UTType(filenameExtension: "heic") ?? .image]
        case .webpToPng, .webpToJpeg:
            return [UTType.webP]
        case .pngToJpeg:
            return [.png]
        case .imageToPdf, .imageCompress, .imageResize:
            return [.image]
        case .pdfMerge, .pdfSplit, .pdfCompress:
            return [.pdf]
        case .zipExtract:
            return [.zip]
        case .csvView:
            return [.commaSeparatedText]
        case .jsonView:
            return [.json]
        case .textView:
            return [.plainText, .utf8PlainText]
        }
    }

    var allowsMultipleSelection: Bool {
        switch conversionType {
        case .pdfMerge, .imageToPdf:
            return true
        default:
            return false
        }
    }

    var inputDescription: String {
        if inputURLs.isEmpty {
            return "No files selected"
        } else if inputURLs.count == 1 {
            return inputURLs[0].lastPathComponent
        } else {
            return "\(inputURLs.count) files selected"
        }
    }

    // MARK: - Conversion

    @MainActor
    func convert() async {
        guard !inputURLs.isEmpty else { return }

        isProcessing = true
        progress = 0
        errorMessage = nil
        isComplete = false

        let inputSize = inputURLs.compactMap { try? FileManager.default.attributesOfItem(atPath: $0.path)[.size] as? Int64 }.reduce(0, +)

        let job = ConversionJob(
            inputFileName: inputDescription,
            conversionType: conversionType,
            inputSize: inputSize
        )
        modelContext?.insert(job)
        job.status = "processing"

        do {
            let result: URL

            switch conversionType {
            case .heicToJpeg:
                progress = 0.3
                result = try await imageService.convert(from: inputURLs[0], to: .jpeg, quality: imageQuality)

            case .heicToPng:
                progress = 0.3
                result = try await imageService.convert(from: inputURLs[0], to: .png)

            case .webpToPng:
                progress = 0.3
                result = try await imageService.convert(from: inputURLs[0], to: .png)

            case .webpToJpeg:
                progress = 0.3
                result = try await imageService.convert(from: inputURLs[0], to: .jpeg, quality: imageQuality)

            case .pngToJpeg:
                progress = 0.3
                result = try await imageService.convert(from: inputURLs[0], to: .jpeg, quality: imageQuality)

            case .imageToPdf:
                progress = 0.3
                result = try await imageService.imagesToPDF(from: inputURLs)

            case .pdfMerge:
                progress = 0.3
                result = try await pdfMergeService.merge(pdfs: inputURLs)

            case .pdfSplit:
                progress = 0.3
                let range = PDFSplitService.PageRange(start: splitStart, end: splitEnd)
                result = try await pdfSplitService.split(pdfURL: inputURLs[0], range: range)

            case .pdfCompress:
                progress = 0.3
                result = try await pdfCompressionService.compress(pdfURL: inputURLs[0], quality: compressionQuality)

            case .imageCompress:
                progress = 0.3
                result = try await imageService.convert(from: inputURLs[0], to: .jpeg, quality: imageQuality)

            case .imageResize:
                progress = 0.3
                let options: ImageResizeService.ResizeOptions
                if usePercentage {
                    options = .percentage(resizeScale)
                } else {
                    options = .dimensions(width: resizeWidth, height: resizeHeight)
                }
                result = try await imageResizeService.resize(imageURL: inputURLs[0], options: options)

            case .zipExtract:
                progress = 0.3
                let extraction = try await zipService.extract(zipURL: inputURLs[0])
                result = extraction.outputDirectory

            case .csvView:
                csvData = try await textService.parseCSV(url: inputURLs[0])
                progress = 1.0
                isProcessing = false
                isComplete = true
                job.status = "complete"
                return

            case .jsonView:
                jsonText = try await textService.prettyPrintJSON(url: inputURLs[0])
                progress = 1.0
                isProcessing = false
                isComplete = true
                job.status = "complete"
                return

            case .textView:
                textData = try await textService.readText(url: inputURLs[0])
                progress = 1.0
                isProcessing = false
                isComplete = true
                job.status = "complete"
                return
            }

            progress = 1.0
            outputURL = result
            isComplete = true

            // Update job
            job.status = "complete"
            job.outputFileName = result.lastPathComponent
            job.outputPath = result.path
            if let attrs = try? FileManager.default.attributesOfItem(atPath: result.path),
               let size = attrs[.size] as? Int64 {
                job.outputSize = size
            }

        } catch {
            let appError = AppError.wrap(error)
            errorMessage = appError.errorDescription
            job.status = "failed"
        }

        isProcessing = false
    }

    // MARK: - PDF Page Count

    @MainActor
    func loadPDFPageCount() async {
        guard let url = inputURLs.first else { return }
        do {
            totalPages = try await pdfSplitService.pageCount(of: url)
            splitEnd = totalPages
        } catch {
            totalPages = 0
        }
    }

    // MARK: - Reset

    func reset() {
        inputURLs = []
        outputURL = nil
        isProcessing = false
        progress = 0
        errorMessage = nil
        isComplete = false
        csvData = nil
        jsonText = nil
        textData = nil
    }
}
