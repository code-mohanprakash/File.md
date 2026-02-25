// OCRService.swift
// FileFairy
//
// Vision framework OCR text recognition.
// From PRD: VNRecognizeTextRequest (on-device, 18 languages).
// Premium feature: OCR text extraction.

import Vision
import UIKit

actor OCRService {

    /// Recognize text in a UIImage
    func recognizeText(
        in image: UIImage,
        languages: [String]? = nil
    ) async throws -> String {
        guard let cgImage = image.cgImage else {
            throw AppError.corruptFile("Cannot extract image data for OCR")
        }
        return try await recognizeText(in: cgImage, languages: languages)
    }

    /// Recognize text in a CGImage
    func recognizeText(
        in cgImage: CGImage,
        languages: [String]? = nil
    ) async throws -> String {
        try await withCheckedThrowingContinuation { continuation in
            let request = VNRecognizeTextRequest { request, error in
                if let error {
                    continuation.resume(throwing: error)
                    return
                }

                let textRequest = request as? VNRecognizeTextRequest
                let observations = textRequest?.results ?? []
                let text = observations
                    .compactMap { $0.topCandidates(1).first?.string }
                    .joined(separator: "\n")

                continuation.resume(returning: text)
            }

            // Configure for accurate recognition
            request.recognitionLevel = .accurate
            request.usesLanguageCorrection = true

            // Set supported languages if specified
            if let languages {
                request.recognitionLanguages = languages
            }

            let handler = VNImageRequestHandler(cgImage: cgImage, options: [:])
            do {
                try handler.perform([request])
            } catch {
                continuation.resume(throwing: error)
            }
        }
    }

    /// Get list of supported languages
    func supportedLanguages() -> [String] {
        let request = VNRecognizeTextRequest()
        request.recognitionLevel = .accurate
        return (try? request.supportedRecognitionLanguages()) ?? ["en-US"]
    }
}
