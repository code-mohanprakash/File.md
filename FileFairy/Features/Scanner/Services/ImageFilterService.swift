// ImageFilterService.swift
// FileFairy
//
// Core Image filter pipeline for scanned documents.
// From PRD: 4 filter modes - Colour, Greyscale, B&W, Photo.
// Also handles perspective correction and shadow removal.

import CoreImage
import CoreImage.CIFilterBuiltins
import UIKit
import Vision

actor ImageFilterService {

    private let context = CIContext(options: [.useSoftwareRenderer: false])

    // MARK: - Filter Presets

    enum FilterPreset: String, CaseIterable, Identifiable {
        case colour     = "Colour"
        case greyscale  = "Greyscale"
        case bw         = "B&W"
        case photo      = "Photo"

        var id: String { rawValue }
    }

    // MARK: - Apply Filter

    func applyFilter(_ preset: FilterPreset, to image: UIImage) -> UIImage? {
        guard let ciImage = CIImage(image: image) else { return nil }
        let filtered = applyFilter(preset, to: ciImage)
        return renderToUIImage(filtered)
    }

    func applyFilter(_ preset: FilterPreset, to ciImage: CIImage) -> CIImage {
        switch preset {
        case .colour:
            return enhanceColour(ciImage)
        case .greyscale:
            return applyGreyscale(ciImage)
        case .bw:
            return applyBlackAndWhite(ciImage)
        case .photo:
            return ciImage  // Original, no processing
        }
    }

    // MARK: - Colour Enhancement

    private func enhanceColour(_ image: CIImage) -> CIImage {
        // Boost contrast and remove shadows for document clarity
        let colorControls = CIFilter.colorControls()
        colorControls.inputImage = image
        colorControls.contrast = 1.15
        colorControls.brightness = 0.02
        colorControls.saturation = 1.1

        guard let output = colorControls.outputImage else { return image }
        return removeShadows(output)
    }

    // MARK: - Greyscale

    private func applyGreyscale(_ image: CIImage) -> CIImage {
        let mono = CIFilter.photoEffectMono()
        mono.inputImage = image

        guard let output = mono.outputImage else { return image }

        // Boost contrast for readability
        let controls = CIFilter.colorControls()
        controls.inputImage = output
        controls.contrast = 1.3

        return controls.outputImage ?? output
    }

    // MARK: - Black & White (High Contrast Threshold)

    private func applyBlackAndWhite(_ image: CIImage) -> CIImage {
        // Convert to greyscale first
        let mono = CIFilter.photoEffectMono()
        mono.inputImage = image

        guard let grey = mono.outputImage else { return image }

        // Apply adaptive threshold for clean B&W
        let controls = CIFilter.colorControls()
        controls.inputImage = grey
        controls.contrast = 3.0
        controls.brightness = 0.1

        return controls.outputImage ?? grey
    }

    // MARK: - Shadow Removal

    private func removeShadows(_ image: CIImage) -> CIImage {
        let highlights = CIFilter.highlightShadowAdjust()
        highlights.inputImage = image
        highlights.shadowAmount = 1.5
        highlights.highlightAmount = 0.8

        return highlights.outputImage ?? image
    }

    // MARK: - Perspective Correction

    func perspectiveCorrect(
        image: UIImage,
        observation: VNRectangleObservation
    ) -> UIImage? {
        guard let ciImage = CIImage(image: image) else { return nil }
        let corrected = perspectiveCorrect(ciImage: ciImage, observation: observation)
        return renderToUIImage(corrected)
    }

    func perspectiveCorrect(
        ciImage: CIImage,
        observation: VNRectangleObservation
    ) -> CIImage {
        let w = ciImage.extent.width
        let h = ciImage.extent.height

        let filter = CIFilter.perspectiveCorrection()
        filter.inputImage = ciImage
        filter.topLeft = CGPoint(x: observation.topLeft.x * w, y: observation.topLeft.y * h)
        filter.topRight = CGPoint(x: observation.topRight.x * w, y: observation.topRight.y * h)
        filter.bottomLeft = CGPoint(x: observation.bottomLeft.x * w, y: observation.bottomLeft.y * h)
        filter.bottomRight = CGPoint(x: observation.bottomRight.x * w, y: observation.bottomRight.y * h)

        return filter.outputImage ?? ciImage
    }

    // MARK: - Crop

    func crop(image: UIImage, to rect: CGRect) -> UIImage? {
        guard let ciImage = CIImage(image: image) else { return nil }
        let cropped = ciImage.cropped(to: rect)
        return renderToUIImage(cropped)
    }

    // MARK: - Rotate

    func rotate(image: UIImage, degrees: CGFloat) -> UIImage? {
        guard let ciImage = CIImage(image: image) else { return nil }
        let radians = degrees * .pi / 180
        let rotated = ciImage.transformed(by: CGAffineTransform(rotationAngle: radians))
        return renderToUIImage(rotated)
    }

    // MARK: - Render

    func renderToJPEG(_ image: CIImage, quality: CGFloat = 0.9) -> Data? {
        context.jpegRepresentation(of: image, colorSpace: CGColorSpaceCreateDeviceRGB(), options: [:])
    }

    private func renderToUIImage(_ ciImage: CIImage) -> UIImage? {
        guard let cgImage = context.createCGImage(ciImage, from: ciImage.extent) else { return nil }
        return UIImage(cgImage: cgImage)
    }

    /// Generate a thumbnail at the specified size
    func generateThumbnail(from image: UIImage, size: CGFloat = 72) -> Data? {
        let renderer = UIGraphicsImageRenderer(size: CGSize(width: size, height: size))
        let thumbnail = renderer.image { _ in
            let aspectRatio = image.size.width / image.size.height
            let targetSize: CGSize
            if aspectRatio > 1 {
                targetSize = CGSize(width: size, height: size / aspectRatio)
            } else {
                targetSize = CGSize(width: size * aspectRatio, height: size)
            }
            let origin = CGPoint(
                x: (size - targetSize.width) / 2,
                y: (size - targetSize.height) / 2
            )
            image.draw(in: CGRect(origin: origin, size: targetSize))
        }
        return thumbnail.jpegData(compressionQuality: 0.7)
    }
}
