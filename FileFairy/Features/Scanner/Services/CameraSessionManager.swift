// CameraSessionManager.swift
// FileFairy
//
// Manages AVCaptureSession for document scanning.
// Runs all AVFoundation work on a dedicated serial queue (not actors)
// per Apple's guidance for AVFoundation + Swift concurrency.

import AVFoundation
import UIKit

final class CameraSessionManager: NSObject, @unchecked Sendable {

    let session = AVCaptureSession()

    private let sessionQueue = DispatchQueue(label: "com.filefairy.camera.session")
    private let photoOutput = AVCapturePhotoOutput()
    private var captureDevice: AVCaptureDevice?

    // Async continuation for bridging delegate callback to async/await
    private var photoContinuation: CheckedContinuation<UIImage, Error>?

    // MARK: - Permission

    static func requestPermission() async -> Bool {
        let status = AVCaptureDevice.authorizationStatus(for: .video)
        switch status {
        case .authorized:
            return true
        case .notDetermined:
            return await AVCaptureDevice.requestAccess(for: .video)
        default:
            return false
        }
    }

    // MARK: - Session Setup

    func setupSession() {
        sessionQueue.async { [weak self] in
            guard let self else { return }
            self.session.beginConfiguration()
            self.session.sessionPreset = .photo

            // Add camera input
            guard let camera = AVCaptureDevice.default(
                .builtInWideAngleCamera,
                for: .video,
                position: .back
            ) else {
                self.session.commitConfiguration()
                return
            }

            self.captureDevice = camera

            // Enable auto-focus for document scanning
            if camera.isFocusModeSupported(.continuousAutoFocus) {
                try? camera.lockForConfiguration()
                camera.focusMode = .continuousAutoFocus
                camera.unlockForConfiguration()
            }

            guard let input = try? AVCaptureDeviceInput(device: camera),
                  self.session.canAddInput(input) else {
                self.session.commitConfiguration()
                return
            }
            self.session.addInput(input)

            // Add photo output
            if self.session.canAddOutput(self.photoOutput) {
                self.session.addOutput(self.photoOutput)
                self.photoOutput.isHighResolutionCaptureEnabled = true
                self.photoOutput.maxPhotoQualityPrioritization = .quality
            }

            self.session.commitConfiguration()
        }
    }

    // MARK: - Session Lifecycle

    func startRunning() {
        sessionQueue.async { [weak self] in
            guard let self, !self.session.isRunning else { return }
            self.session.startRunning()
        }
    }

    func stopRunning() {
        sessionQueue.async { [weak self] in
            guard let self, self.session.isRunning else { return }
            self.session.stopRunning()
        }
    }

    // MARK: - Capture Photo

    func capturePhoto() async throws -> UIImage {
        try await withCheckedThrowingContinuation { continuation in
            sessionQueue.async { [weak self] in
                guard let self else {
                    continuation.resume(throwing: AppError.cameraUnavailable)
                    return
                }
                self.photoContinuation = continuation

                let settings = AVCapturePhotoSettings()
                settings.flashMode = self.isFlashAvailable ? .auto : .off
                self.photoOutput.capturePhoto(with: settings, delegate: self)
            }
        }
    }

    // MARK: - Flash Control

    var isFlashAvailable: Bool {
        captureDevice?.hasFlash ?? false
    }

    var isFlashOn: Bool {
        captureDevice?.flashMode == .on
    }

    func toggleFlash() {
        guard let device = captureDevice, device.hasFlash else { return }
        sessionQueue.async {
            try? device.lockForConfiguration()
            // Flash is controlled per-capture via AVCapturePhotoSettings
            device.unlockForConfiguration()
        }
    }
}

// MARK: - AVCapturePhotoCaptureDelegate

extension CameraSessionManager: AVCapturePhotoCaptureDelegate {

    func photoOutput(
        _ output: AVCapturePhotoOutput,
        didFinishProcessingPhoto photo: AVCapturePhoto,
        error: Error?
    ) {
        if let error {
            photoContinuation?.resume(throwing: error)
            photoContinuation = nil
            return
        }

        guard let data = photo.fileDataRepresentation(),
              let image = UIImage(data: data) else {
            photoContinuation?.resume(throwing: AppError.cameraUnavailable)
            photoContinuation = nil
            return
        }

        photoContinuation?.resume(returning: image)
        photoContinuation = nil
    }
}
