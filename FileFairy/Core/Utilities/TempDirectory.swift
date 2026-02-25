// TempDirectory.swift
// FileFairy
//
// Manages the app's temporary working directory.
// All module code that creates transient files should go through this class
// so temp files are tracked and cleaned up correctly.
//
// Lifecycle:
//   - Files are written to <NSTemporaryDirectory>/FileFairy/<uuid>/
//   - On app backgrounding, files older than the configured TTL are deleted.
//   - Callers can explicitly release individual files or entire sessions.

import Foundation
import UIKit
import os.log

// MARK: - TempDirectory

final class TempDirectory {

    // MARK: - Singleton

    static let shared = TempDirectory()

    // MARK: - Configuration

    /// Files older than this interval are eligible for cleanup.
    /// Default: 1 hour. Override in unit tests by setting directly.
    var maxAge: TimeInterval = 3600

    // MARK: - Private Properties

    private let logger = Logger(
        subsystem: Bundle.main.bundleIdentifier ?? "com.filefairy",
        category: "TempDirectory"
    )

    /// Root temp directory: <NSTemporaryDirectory>/FileFairy/
    private let rootURL: URL = {
        let tmp = URL(fileURLWithPath: NSTemporaryDirectory())
            .appendingPathComponent("FileFairy", isDirectory: true)
        try? FileManager.default.createDirectory(at: tmp, withIntermediateDirectories: true)
        return tmp
    }()

    /// Maps session tokens to their directory URLs for bulk cleanup.
    private var sessionDirectories: [String: URL] = [:]

    // MARK: - Initializer

    private init() {
        registerForBackgroundNotification()
    }

    // MARK: - Public API

    /// Returns a URL inside the root temp directory for a given file name.
    /// The file is NOT created — the caller writes to this URL.
    ///
    /// - Parameter fileName: The desired file name (including extension).
    /// - Returns: A URL guaranteed to be in the app's temp directory.
    func url(for fileName: String) -> URL {
        rootURL.appendingPathComponent(fileName)
    }

    /// Creates a unique session sub-directory and returns its URL.
    /// Use sessions when a single operation produces multiple temp files
    /// that should be cleaned up together.
    ///
    /// - Parameter token: An optional stable identifier (e.g., scan session UUID string).
    ///   Pass nil to generate a random token.
    /// - Returns: A directory URL inside the root temp directory.
    @discardableResult
    func createSession(token: String? = nil) throws -> URL {
        let sessionToken = token ?? UUID().uuidString
        let sessionURL = rootURL.appendingPathComponent(sessionToken, isDirectory: true)
        try FileManager.default.createDirectory(at: sessionURL, withIntermediateDirectories: true)
        sessionDirectories[sessionToken] = sessionURL
        return sessionURL
    }

    /// Returns the session directory URL for an existing token, if it exists.
    func sessionURL(for token: String) -> URL? {
        sessionDirectories[token]
    }

    /// Writes data to a new temp file, returning its URL.
    ///
    /// - Parameters:
    ///   - data: The bytes to write.
    ///   - fileName: The desired file name (including extension).
    ///   - sessionToken: Optional session to place the file inside.
    @discardableResult
    func write(_ data: Data, fileName: String, sessionToken: String? = nil) throws -> URL {
        let directory: URL
        if let token = sessionToken, let sessionDir = sessionDirectories[token] {
            directory = sessionDir
        } else {
            directory = rootURL
        }

        let dest = directory.appendingPathComponent(fileName)
        try data.write(to: dest, options: .atomic)
        return dest
    }

    // MARK: - Cleanup

    /// Deletes a specific file or directory.
    func remove(_ url: URL) {
        do {
            try FileManager.default.removeItem(at: url)
        } catch {
            logger.warning("TempDirectory: Failed to remove \(url.lastPathComponent): \(error.localizedDescription)")
        }
    }

    /// Deletes all files in a named session directory, then removes the directory.
    func removeSession(token: String) {
        guard let sessionURL = sessionDirectories[token] else { return }
        remove(sessionURL)
        sessionDirectories.removeValue(forKey: token)
    }

    /// Removes all temp files and session directories unconditionally.
    func removeAll() {
        guard let contents = try? FileManager.default.contentsOfDirectory(
            at: rootURL,
            includingPropertiesForKeys: nil
        ) else { return }

        for item in contents {
            remove(item)
        }
        sessionDirectories.removeAll()
        logger.info("TempDirectory: Removed all temp files.")
    }

    /// Removes only temp files older than `maxAge` seconds.
    /// Called automatically on app background, can also be called manually.
    func removeStaleFiles() {
        let cutoff = Date().addingTimeInterval(-maxAge)
        let keys: [URLResourceKey] = [.creationDateKey, .isDirectoryKey]

        guard let contents = try? FileManager.default.contentsOfDirectory(
            at: rootURL,
            includingPropertiesForKeys: keys
        ) else { return }

        var removedCount = 0
        for itemURL in contents {
            guard
                let values = try? itemURL.resourceValues(forKeys: Set(keys)),
                let created = values.creationDate,
                created < cutoff
            else { continue }

            remove(itemURL)
            removedCount += 1
        }

        if removedCount > 0 {
            logger.info("TempDirectory: Removed \(removedCount) stale temp file(s).")
        }
    }

    // MARK: - App Lifecycle

    private func registerForBackgroundNotification() {
        NotificationCenter.default.addObserver(
            forName: UIApplication.didEnterBackgroundNotification,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            self?.removeStaleFiles()
        }
    }

    deinit {
        NotificationCenter.default.removeObserver(self)
    }
}

// MARK: - Convenience Extension on URL

extension URL {
    /// True if this URL lives inside FileFairy's temp directory.
    var isInFairyTemp: Bool {
        path.hasPrefix(TempDirectory.shared.url(for: "").deletingLastPathComponent().path)
    }
}
