// ConversionType.swift
// FileFairy

import SwiftUI

enum ConversionCategory: String, CaseIterable {
    case imageConvert = "Image Convert"
    case pdfTools = "PDF Tools"
    case fileTools = "File Tools"
}

enum ConversionType: String, CaseIterable, Identifiable {
    case heicToJpeg, heicToPng, webpToPng, webpToJpeg, pngToJpeg, imageToPdf
    case pdfMerge, pdfSplit, pdfCompress
    case imageCompress, imageResize
    case zipExtract, csvView, jsonView, textView

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .heicToJpeg:    return "HEIC → JPEG"
        case .heicToPng:     return "HEIC → PNG"
        case .webpToPng:     return "WebP → PNG"
        case .webpToJpeg:    return "WebP → JPEG"
        case .pngToJpeg:     return "PNG → JPEG"
        case .imageToPdf:    return "Image → PDF"
        case .pdfMerge:      return "PDF Merge"
        case .pdfSplit:      return "PDF Split"
        case .pdfCompress:   return "PDF Compress"
        case .imageCompress: return "Image Compress"
        case .imageResize:   return "Image Resize"
        case .zipExtract:    return "ZIP Extract"
        case .csvView:       return "CSV Viewer"
        case .jsonView:      return "JSON Viewer"
        case .textView:      return "Text Viewer"
        }
    }

    var icon: String {
        switch self {
        case .heicToJpeg, .heicToPng, .webpToPng, .webpToJpeg, .pngToJpeg:
            return "arrow.triangle.2.circlepath"
        case .imageToPdf:      return "doc.richtext.fill"
        case .pdfMerge:        return "arrow.triangle.merge"
        case .pdfSplit:        return "scissors"
        case .pdfCompress:     return "arrow.down.doc.fill"
        case .imageCompress:   return "photo.fill"
        case .imageResize:     return "arrow.up.left.and.arrow.down.right"
        case .zipExtract:      return "archivebox.fill"
        case .csvView:         return "tablecells.fill"
        case .jsonView:        return "curlybraces"
        case .textView:        return "doc.text.fill"
        }
    }

    var featureColor: Color {
        switch self {
        case .heicToJpeg, .heicToPng, .webpToPng, .webpToJpeg, .pngToJpeg,
             .imageCompress, .imageResize, .imageToPdf:
            return .Fairy.amber
        case .pdfMerge, .pdfSplit, .pdfCompress:
            return .Fairy.green
        case .zipExtract, .csvView, .jsonView, .textView:
            return .Fairy.violet
        }
    }

    var category: ConversionCategory {
        switch self {
        case .heicToJpeg, .heicToPng, .webpToPng, .webpToJpeg, .pngToJpeg,
             .imageCompress, .imageResize, .imageToPdf:
            return .imageConvert
        case .pdfMerge, .pdfSplit, .pdfCompress:
            return .pdfTools
        case .zipExtract, .csvView, .jsonView, .textView:
            return .fileTools
        }
    }

    var requiresPremium: Bool {
        switch self {
        case .pdfSplit, .pdfCompress, .imageResize: return true
        default: return false
        }
    }

    var subtitle: String {
        switch self {
        case .heicToJpeg:    return "Apple format to JPEG"
        case .heicToPng:     return "Apple format to PNG"
        case .webpToPng:     return "Web images to PNG"
        case .webpToJpeg:    return "Web images to JPEG"
        case .pngToJpeg:     return "Lossless to compressed"
        case .imageToPdf:    return "One or more images"
        case .pdfMerge:      return "Combine PDFs"
        case .pdfSplit:      return "Split by page range"
        case .pdfCompress:   return "Reduce file size"
        case .imageCompress: return "Reduce quality & size"
        case .imageResize:   return "Custom dimensions"
        case .zipExtract:    return "Unzip files"
        case .csvView:       return "View spreadsheet data"
        case .jsonView:      return "Browse JSON tree"
        case .textView:      return "Read text files"
        }
    }
}
