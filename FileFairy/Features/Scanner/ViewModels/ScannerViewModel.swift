// ScannerViewModel.swift
// FileFairy
//
// Main ViewModel for document scanning flow.
// State machine: idle -> previewing -> detecting -> capturing -> reviewing

import SwiftUI
import SwiftData
import Vision

@Observable
final class ScannerViewModel {

    // MARK: - State

    enum CaptureState: Equatable {
        case idle
        case requestingPermission
        case permissionDenied
        case previewing
        case capturing
        case processing
        case reviewing
    }

    var captureState: CaptureState = .idle
    var capturedPages: [UIImage] = []
    var currentFilter: ImageFilterService.FilterPreset = .colour
    var detectedQuad: VNRectangleObservation?
    var isFlashOn: Bool = false
    var errorMessage: String?

    // Review state
    var currentReviewIndex: Int = 0
    var sessionTitle: String = ""

    var pageCount: Int { capturedPages.count }
    var hasPages: Bool { !capturedPages.isEmpty }

    // MARK: - Dependencies

    let cameraManager = CameraSessionManager()
    private let edgeDetection = EdgeDetectionService()
    private let imageFilter = ImageFilterService()
    private let ocrService = OCRService()
    private let exportService = ScanExportService()

    // MARK: - Persistence

    private var modelContext: ModelContext?

    func setContext(_ context: ModelContext) {
        self.modelContext = context
    }

    // MARK: - Lifecycle

    @MainActor
    func startScanner() async {
        captureState = .requestingPermission

        let granted = await CameraSessionManager.requestPermission()
        guard granted else {
            captureState = .permissionDenied
            return
        }

        cameraManager.setupSession()
        cameraManager.startRunning()
        captureState = .previewing
    }

    @MainActor
    func stopScanner() {
        cameraManager.stopRunning()
        captureState = .idle
    }

    // MARK: - Capture

    @MainActor
    func capturePhoto() async {
        guard captureState == .previewing else { return }
        captureState = .capturing

        do {
            var image = try await cameraManager.capturePhoto()

            // Apply perspective correction if edges detected
            if let detectedObservation = detectedQuad {
                nonisolated(unsafe) let quad = detectedObservation
                if let corrected = await imageFilter.perspectiveCorrect(image: image, observation: quad) {
                    image = corrected
                }
            }

            // Apply current filter
            if let filtered = await imageFilter.applyFilter(currentFilter, to: image) {
                image = filtered
            }

            capturedPages.append(image)
            captureState = .previewing

            // Haptic feedback
            HapticEngine.shared.scanCapture()
            SoundPlayer.shared.play(.capture)

        } catch {
            errorMessage = error.localizedDescription
            captureState = .previewing
        }
    }

    // MARK: - Review

    @MainActor
    func enterReview() {
        guard hasPages else { return }
        cameraManager.stopRunning()
        captureState = .reviewing
        currentReviewIndex = capturedPages.count - 1
    }

    @MainActor
    func addMorePages() {
        cameraManager.startRunning()
        captureState = .previewing
    }

    @MainActor
    func deletePage(at index: Int) {
        guard capturedPages.indices.contains(index) else { return }
        capturedPages.remove(at: index)
        if capturedPages.isEmpty {
            captureState = .previewing
            cameraManager.startRunning()
        } else {
            currentReviewIndex = min(currentReviewIndex, capturedPages.count - 1)
        }
    }

    @MainActor
    func reorderPages(from source: IndexSet, to destination: Int) {
        capturedPages.move(fromOffsets: source, toOffset: destination)
    }

    // MARK: - Filter

    @MainActor
    func applyFilter(_ preset: ImageFilterService.FilterPreset, toPage index: Int) async {
        guard capturedPages.indices.contains(index) else { return }
        currentFilter = preset
        if let filtered = await imageFilter.applyFilter(preset, to: capturedPages[index]) {
            capturedPages[index] = filtered
        }
    }

    // MARK: - Export

    @MainActor
    func exportAsPDF() async throws -> URL {
        captureState = .processing
        let title = sessionTitle.isEmpty
            ? "Scan \(Date().formatted(date: .abbreviated, time: .shortened))"
            : sessionTitle

        let url = try await exportService.exportAsPDF(pages: capturedPages, title: title)
        let savedURL = try await exportService.saveToDocuments(from: url)

        saveScanSession(title: title, format: "pdf")
        HapticEngine.shared.success()
        SoundPlayer.shared.play(.conversionDone)
        captureState = .reviewing

        return savedURL
    }

    @MainActor
    func exportAsJPEG() async throws -> [URL] {
        captureState = .processing
        let title = sessionTitle.isEmpty
            ? "Scan \(Date().formatted(date: .abbreviated, time: .shortened))"
            : sessionTitle

        let urls = try await exportService.exportAsJPEGs(pages: capturedPages, title: title)

        saveScanSession(title: title, format: "jpeg")
        HapticEngine.shared.success()
        SoundPlayer.shared.play(.conversionDone)
        captureState = .reviewing

        return urls
    }

    // MARK: - Save Session to SwiftData

    @MainActor
    private func saveScanSession(title: String, format: String) {
        guard let context = modelContext else { return }
        let session = ScanSession(title: title, exportFormat: format)
        session.pageCount = capturedPages.count
        session.isExported = true
        context.insert(session)
        try? context.save()
    }

    // MARK: - OCR

    @MainActor
    func performOCR(on index: Int) async throws -> String {
        guard capturedPages.indices.contains(index) else {
            throw AppError.corruptFile("Page not found")
        }
        return try await ocrService.recognizeText(in: capturedPages[index])
    }

    // MARK: - Reset

    @MainActor
    func reset() {
        capturedPages.removeAll()
        detectedQuad = nil
        currentFilter = .colour
        currentReviewIndex = 0
        sessionTitle = ""
        errorMessage = nil
        captureState = .idle
    }
}
