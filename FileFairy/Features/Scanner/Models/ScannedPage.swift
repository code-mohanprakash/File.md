// ScannedPage.swift
// FileFairy
//
// SwiftData model for a single scanned page.
// Image data stored externally via @Attribute(.externalStorage).

import SwiftData
import Foundation

@Model
final class ScannedPage {
    var id: UUID
    var pageIndex: Int
    var ocrText: String?
    var filterName: String  // "colour", "greyscale", "bw", "photo"

    /// Full resolution scan image - stored externally to keep SQLite lean
    @Attribute(.externalStorage)
    var imageData: Data?

    /// Thumbnail for list views (72pt) - stored externally
    @Attribute(.externalStorage)
    var thumbnailData: Data?

    var session: ScanSession?

    init(
        pageIndex: Int,
        imageData: Data? = nil,
        filterName: String = "colour"
    ) {
        self.id = UUID()
        self.pageIndex = pageIndex
        self.imageData = imageData
        self.filterName = filterName
    }
}
