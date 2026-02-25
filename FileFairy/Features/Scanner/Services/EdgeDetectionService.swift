// EdgeDetectionService.swift
// FileFairy
//
// Vision framework document edge detection.
// From PRD: VNDetectRectangleRequest with confidence > 0.8.
// Runs on background actor, throttled to ~15fps.

import Vision
import UIKit
import CoreImage

actor EdgeDetectionService {

    /// Detect document edges in an image
    func detectEdges(in image: UIImage) async -> VNRectangleObservation? {
        guard let cgImage = image.cgImage else { return nil }
        return await detectEdges(in: cgImage)
    }

    /// Detect document edges in a CGImage
    func detectEdges(in cgImage: CGImage) async -> VNRectangleObservation? {
        await withCheckedContinuation { (continuation: CheckedContinuation<VNRectangleObservation?, Never>) in
            let request = VNDetectRectanglesRequest { request, error in
                guard error == nil else {
                    continuation.resume(returning: nil)
                    return
                }
                let observation: VNRectangleObservation? = request.results?
                    .compactMap { $0 as? VNRectangleObservation }
                    .filter { $0.confidence > 0.8 }
                    .max(by: { $0.confidence < $1.confidence })
                // Move observation across the boundary explicitly
                nonisolated(unsafe) let result = observation
                continuation.resume(returning: result)
            }

            request.minimumConfidence = 0.7
            request.minimumAspectRatio = 0.2
            request.maximumAspectRatio = 1.0
            request.maximumObservations = 1

            let handler = VNImageRequestHandler(cgImage: cgImage, options: [:])
            try? handler.perform([request])
        }
    }

    /// Detect edges in a CMSampleBuffer (for real-time camera feed)
    func detectEdges(in pixelBuffer: CVPixelBuffer) async -> VNRectangleObservation? {
        await withCheckedContinuation { (continuation: CheckedContinuation<VNRectangleObservation?, Never>) in
            let request = VNDetectRectanglesRequest { request, error in
                guard error == nil else {
                    continuation.resume(returning: nil)
                    return
                }
                let observation: VNRectangleObservation? = request.results?
                    .compactMap { $0 as? VNRectangleObservation }
                    .filter { $0.confidence > 0.8 }
                    .max(by: { $0.confidence < $1.confidence })
                // Move observation across the boundary explicitly
                nonisolated(unsafe) let result = observation
                continuation.resume(returning: result)
            }

            request.minimumConfidence = 0.7
            request.minimumAspectRatio = 0.2
            request.maximumObservations = 1

            let handler = VNImageRequestHandler(cvPixelBuffer: pixelBuffer, options: [:])
            try? handler.perform([request])
        }
    }

    /// Convert VNRectangleObservation to CGPoint corners in image coordinates
    func quadCorners(
        from observation: VNRectangleObservation,
        imageSize: CGSize
    ) -> (topLeft: CGPoint, topRight: CGPoint, bottomLeft: CGPoint, bottomRight: CGPoint) {
        let w = imageSize.width
        let h = imageSize.height
        return (
            topLeft: CGPoint(x: observation.topLeft.x * w, y: (1 - observation.topLeft.y) * h),
            topRight: CGPoint(x: observation.topRight.x * w, y: (1 - observation.topRight.y) * h),
            bottomLeft: CGPoint(x: observation.bottomLeft.x * w, y: (1 - observation.bottomLeft.y) * h),
            bottomRight: CGPoint(x: observation.bottomRight.x * w, y: (1 - observation.bottomRight.y) * h)
        )
    }
}
