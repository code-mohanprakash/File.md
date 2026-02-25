// ErrorHandler.swift
// FileFairy
//
// Central error handling service. Feature code calls handle(_:context:) so
// that all errors are logged consistently in one place. UI-level presentation
// (alerts, banners) is a separate concern handled by feature view models.

import Foundation
import os.log

// MARK: - ErrorHandler

/// Processes, logs, and optionally reports errors from across the app.
/// Callers pass any Error — the handler normalizes it to AppError internally.
@MainActor
final class ErrorHandler {

    // MARK: - Singleton

    static let shared = ErrorHandler()

    // MARK: - Logging

    private let logger = Logger(
        subsystem: Bundle.main.bundleIdentifier ?? "com.filefairy",
        category: "ErrorHandler"
    )

    // MARK: - State

    /// The most recently handled error. Views can observe this for passive
    /// error banners (e.g., a toast at the bottom of the screen).
    private(set) var lastError: AppError?

    /// Indicates whether an error is currently being presented to the user.
    private(set) var isShowingError: Bool = false

    // MARK: - Initializer

    private init() {}

    // MARK: - Public API

    /// Normalize, log, and optionally record an error.
    ///
    /// - Parameters:
    ///   - error: Any thrown error from app code or Apple frameworks.
    ///   - context: A human-readable string describing what operation failed
    ///     (e.g., "ScanSession export", "MBOX import"). Used in log output only.
    /// - Returns: The normalized AppError, so callers can surface it in UI.
    @discardableResult
    func handle(_ error: Error, context: String) -> AppError {
        let appError = AppError.wrap(error)
        lastError = appError
        log(appError, context: context)
        return appError
    }

    /// Handle an error that has already been typed as AppError.
    @discardableResult
    func handle(_ appError: AppError, context: String) -> AppError {
        lastError = appError
        log(appError, context: context)
        return appError
    }

    // MARK: - Logging Implementation

    private func log(_ error: AppError, context: String) {
        let description = error.errorDescription ?? "Unknown error"
        let suggestion  = error.recoverySuggestion ?? ""

        switch error {
        case .diskFull, .permissionDenied, .cameraUnavailable, .purchaseFailed:
            // User-actionable: info level because these are expected states.
            logger.info(
                "[\(context, privacy: .public)] \(description, privacy: .public) — \(suggestion, privacy: .public)"
            )

        case .unknown(let underlying):
            // Unexpected error — log at fault level with full detail.
            logger.fault(
                "[\(context, privacy: .public)] Unexpected error: \(underlying.localizedDescription, privacy: .public)"
            )

        default:
            // Operational errors: log at error level.
            logger.error(
                "[\(context, privacy: .public)] \(description, privacy: .public)"
            )
        }
    }
}

// MARK: - Result Extension

extension Result where Failure == Error {
    /// Runs the handle closure if the result is a failure, then re-throws
    /// after normalizing the error to AppError.
    ///
    /// Usage:
    /// ```swift
    /// let result = Result { try someOperation() }
    /// let appError = result.handleError(context: "PDF export")
    /// ```
    @MainActor
    @discardableResult
    func handleError(context: String) -> AppError? {
        if case .failure(let error) = self {
            return ErrorHandler.shared.handle(error, context: context)
        }
        return nil
    }
}

// MARK: - Throwing Extension

/// Convenience global function for one-liner error handling in async contexts.
///
/// Usage:
/// ```swift
/// do {
///     try await exportPDF()
/// } catch {
///     let appError = handleError(error, context: "PDF Export")
///     // present appError in UI
/// }
/// ```
@MainActor
@discardableResult
func handleError(_ error: Error, context: String) -> AppError {
    ErrorHandler.shared.handle(error, context: context)
}
