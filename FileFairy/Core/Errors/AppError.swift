// AppError.swift
// FileFairy
//
// Typed error domain for all FileFairy operations.
// Every error surfaces a human-readable description and an actionable
// recovery suggestion — both localizable and ready for Alert presentation.

import Foundation

// MARK: - AppError

/// The unified error type for FileFairy. Feature code should map internal
/// errors to AppError before they cross a module boundary.
enum AppError: LocalizedError {

    // MARK: - Cases

    /// A required file could not be found at the given path or identifier.
    case fileNotFound(String)

    /// The user denied a required permission (camera, photo library, Files access).
    case permissionDenied

    /// The device does not have sufficient disk space to complete the operation.
    case diskFull

    /// The file exists but its contents are invalid, truncated, or corrupted.
    case corruptFile(String)

    /// The file format is not supported by the requested operation.
    case unsupportedFormat(String)

    /// A format conversion failed, with an optional reason from the converter.
    case conversionFailed(String)

    /// A data parsing step failed (e.g., MBOX parsing, PDF text extraction).
    case parsingError(String)

    /// The device does not have a usable camera (simulator or restricted device).
    case cameraUnavailable

    /// An in-app purchase or subscription could not be completed.
    case purchaseFailed(String)

    /// A catch-all wrapper for unexpected errors from Apple frameworks.
    case unknown(Error)

    // MARK: - LocalizedError

    var errorDescription: String? {
        switch self {
        case .fileNotFound(let name):
            return "\"\(name)\" couldn't be found"

        case .permissionDenied:
            return "Permission required"

        case .diskFull:
            return "Not enough storage"

        case .corruptFile(let name):
            return "\"\(name)\" appears to be damaged"

        case .unsupportedFormat(let format):
            return "\"\(format)\" files aren't supported"

        case .conversionFailed(let reason):
            return "Conversion failed\(reason.isEmpty ? "" : ": \(reason)")"

        case .parsingError(let detail):
            return "Couldn't read the file\(detail.isEmpty ? "" : ": \(detail)")"

        case .cameraUnavailable:
            return "Camera is unavailable"

        case .purchaseFailed(let reason):
            return "Purchase couldn't be completed\(reason.isEmpty ? "" : ": \(reason)")"

        case .unknown(let error):
            return error.localizedDescription
        }
    }

    var recoverySuggestion: String? {
        switch self {
        case .fileNotFound:
            return "The file may have been moved or deleted. Try importing it again from the Files app."

        case .permissionDenied:
            return "Open Settings, find FileFairy, and grant the required permission."

        case .diskFull:
            return "Free up space on your device by deleting unused apps or files, then try again."

        case .corruptFile(let name):
            return "\"\(name)\" may have been damaged during transfer. Try re-downloading or re-exporting the original."

        case .unsupportedFormat(let format):
            return "FileFairy can't process \(format) files yet. Check the App Store for updates."

        case .conversionFailed:
            return "The file may be password-protected or contain unsupported content. Try a different file."

        case .parsingError:
            return "The file may be empty, corrupted, or in an unexpected encoding. Try re-exporting from the source app."

        case .cameraUnavailable:
            return "Make sure no other app is using the camera, or try restarting your device."

        case .purchaseFailed:
            return "Check your payment method in the App Store, then try again. Your account has not been charged."

        case .unknown:
            return "An unexpected error occurred. Please try again or contact support if the problem continues."
        }
    }

    // MARK: - Convenience

    /// A short, context-free title suitable for use as an Alert title.
    var alertTitle: String {
        switch self {
        case .fileNotFound:       return "File Not Found"
        case .permissionDenied:   return "Permission Required"
        case .diskFull:           return "Storage Full"
        case .corruptFile:        return "Damaged File"
        case .unsupportedFormat:  return "Unsupported Format"
        case .conversionFailed:   return "Conversion Failed"
        case .parsingError:       return "Couldn't Read File"
        case .cameraUnavailable:  return "Camera Unavailable"
        case .purchaseFailed:     return "Purchase Failed"
        case .unknown:            return "Something Went Wrong"
        }
    }

    /// Wraps any Error in AppError, passing through if it's already an AppError.
    static func wrap(_ error: Error) -> AppError {
        if let appError = error as? AppError {
            return appError
        }
        return .unknown(error)
    }
}

// MARK: - Equatable

extension AppError: Equatable {
    static func == (lhs: AppError, rhs: AppError) -> Bool {
        lhs.errorDescription == rhs.errorDescription
    }
}
