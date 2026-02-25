// DeepLinkHandler.swift
// FileFairy
//
// Parses incoming filefairy:// URLs and routes them via AppRouter.
//
// URL Scheme: filefairy://<route>?<params>
//
// Supported routes:
//   filefairy://scan                     → Switch to Scanner tab
//   filefairy://scan?sessionId=<uuid>    → Open a specific scan session
//   filefairy://open?path=<encoded-path> → Open a file in the File Opener tab
//   filefairy://convert?input=<encoded>  → Pre-fill Converter with a file
//   filefairy://mbox?path=<encoded-path> → Open an MBOX file
//   filefairy://settings                 → Present settings sheet
//   filefairy://paywall                  → Present paywall sheet

import Foundation

enum DeepLinkHandler {

    // MARK: - Route Constants

    private enum Route {
        static let scan      = "scan"
        static let open      = "open"
        static let convert   = "convert"
        static let mbox      = "mbox"
        static let settings  = "settings"
        static let paywall   = "paywall"
    }

    private enum QueryKey {
        static let sessionId = "sessionId"
        static let path      = "path"
        static let input     = "input"
    }

    // MARK: - Public Entry Point

    /// Parse a URL and drive the router accordingly.
    /// Call from `onOpenURL` in FileFairyApp.
    @MainActor
    static func handle(_ url: URL, router: AppRouter) {
        guard url.scheme?.lowercased() == "filefairy" else {
            return
        }

        let host = url.host?.lowercased() ?? ""
        let queryItems = URLComponents(url: url, resolvingAgainstBaseURL: false)?
            .queryItems ?? []

        switch host {
        case Route.scan:
            handleScan(queryItems: queryItems, router: router)

        case Route.open:
            handleOpen(queryItems: queryItems, router: router)

        case Route.convert:
            handleConvert(queryItems: queryItems, router: router)

        case Route.mbox:
            handleMbox(queryItems: queryItems, router: router)

        case Route.settings:
            router.presentSheet(.settings)

        case Route.paywall:
            router.presentSheet(.paywall)

        default:
            // Unknown route — navigate home gracefully
            router.switchTab(.home)
        }
    }

    // MARK: - Route Handlers

    @MainActor
    private static func handleScan(queryItems: [URLQueryItem], router: AppRouter) {
        router.switchTab(.scanner)

        if let sessionIdString = value(for: QueryKey.sessionId, in: queryItems),
           let sessionId = UUID(uuidString: sessionIdString) {
            // Push the export sheet for a specific session
            router.presentSheet(.scanExport(sessionID: sessionId))
        }
    }

    @MainActor
    private static func handleOpen(queryItems: [URLQueryItem], router: AppRouter) {
        router.switchTab(.fileOpener)

        if let encodedPath = value(for: QueryKey.path, in: queryItems),
           let decodedPath = encodedPath.removingPercentEncoding {
            let url = URL(fileURLWithPath: decodedPath)
            router.presentFullScreen(.documentPreview(url: url))
        }
    }

    @MainActor
    private static func handleConvert(queryItems: [URLQueryItem], router: AppRouter) {
        router.switchTab(.converter)

        if let encodedInput = value(for: QueryKey.input, in: queryItems),
           let decodedPath = encodedInput.removingPercentEncoding {
            let ext = URL(fileURLWithPath: decodedPath).pathExtension
            if !ext.isEmpty {
                router.presentSheet(.formatPicker(inputExtension: ext))
            }
        }
    }

    @MainActor
    private static func handleMbox(queryItems: [URLQueryItem], router: AppRouter) {
        router.switchTab(.mbox)

        if let encodedPath = value(for: QueryKey.path, in: queryItems),
           let decodedPath = encodedPath.removingPercentEncoding {
            let url = URL(fileURLWithPath: decodedPath)
            router.presentFullScreen(.documentPreview(url: url))
        }
    }

    // MARK: - Helpers

    private static func value(for key: String, in items: [URLQueryItem]) -> String? {
        items.first(where: { $0.name == key })?.value
    }
}
