// FileTypeResolver.swift
// FileFairy
//
// Resolves file types, icons, and colors for any file URL.

import UniformTypeIdentifiers
import SwiftUI

struct FileTypeResolver {

    /// Determine the file type category for a URL
    static func resolve(_ url: URL) -> FileTypeInfo {
        let ext = url.pathExtension.lowercased()
        let utType = UTType(filenameExtension: ext)

        switch ext {
        case "pdf":
            return FileTypeInfo(type: "pdf", icon: "doc.fill", color: .Fairy.green, label: "PDF")
        case "mbox":
            return FileTypeInfo(type: "mbox", icon: "envelope.fill", color: .Fairy.teal, label: "MBOX")
        case "heic", "heif":
            return FileTypeInfo(type: ext, icon: "photo.fill", color: .Fairy.amber, label: ext.uppercased())
        case "jpeg", "jpg":
            return FileTypeInfo(type: "jpeg", icon: "photo.fill", color: .Fairy.amber, label: "JPEG")
        case "png":
            return FileTypeInfo(type: "png", icon: "photo.fill", color: .Fairy.amber, label: "PNG")
        case "webp":
            return FileTypeInfo(type: "webp", icon: "photo.fill", color: .Fairy.amber, label: "WebP")
        case "gif":
            return FileTypeInfo(type: "gif", icon: "photo.fill", color: .Fairy.amber, label: "GIF")
        case "zip", "gz", "tar":
            return FileTypeInfo(type: ext, icon: "archivebox.fill", color: .Fairy.violet, label: ext.uppercased())
        case "csv":
            return FileTypeInfo(type: "csv", icon: "tablecells.fill", color: .Fairy.teal, label: "CSV")
        case "json":
            return FileTypeInfo(type: "json", icon: "curlybraces", color: .Fairy.green, label: "JSON")
        case "txt", "md", "log", "rtf":
            return FileTypeInfo(type: ext, icon: "doc.text.fill", color: .Fairy.slate, label: ext.uppercased())
        case "doc", "docx":
            return FileTypeInfo(type: ext, icon: "doc.richtext.fill", color: .Fairy.violet, label: "Word")
        case "xls", "xlsx":
            return FileTypeInfo(type: ext, icon: "tablecells.fill", color: .Fairy.green, label: "Excel")
        case "ppt", "pptx":
            return FileTypeInfo(type: ext, icon: "rectangle.fill.on.rectangle.fill", color: .Fairy.coral, label: "PowerPoint")
        case "mp4", "mov", "avi":
            return FileTypeInfo(type: ext, icon: "video.fill", color: .Fairy.rose, label: ext.uppercased())
        case "mp3", "wav", "m4a":
            return FileTypeInfo(type: ext, icon: "waveform", color: .Fairy.violet, label: ext.uppercased())
        default:
            if utType?.conforms(to: .image) == true {
                return FileTypeInfo(type: ext, icon: "photo.fill", color: .Fairy.amber, label: ext.uppercased())
            } else if utType?.conforms(to: .audiovisualContent) == true {
                return FileTypeInfo(type: ext, icon: "play.fill", color: .Fairy.rose, label: ext.uppercased())
            }
            return FileTypeInfo(type: ext, icon: "doc.fill", color: .Fairy.mist, label: ext.uppercased())
        }
    }
}

struct FileTypeInfo {
    let type: String
    let icon: String
    let color: Color
    let label: String
}
