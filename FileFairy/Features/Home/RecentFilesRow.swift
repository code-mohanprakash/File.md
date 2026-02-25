// RecentFilesRow.swift
// FileFairy
//
// Horizontal scroll of recent file thumbnails.
// From PRD Section 6.1: 48pt circles, max 10 shown.

import SwiftUI
import SwiftData

struct RecentFilesRow: View {

    @Query(
        sort: \RecentFile.openedAt,
        order: .reverse
    ) private var recentFiles: [RecentFile]

    var body: some View {
        if !recentFiles.isEmpty {
            VStack(alignment: .leading, spacing: Spacing.sm) {
                Text("Recent Files")
                    .font(.Fairy.headline)
                    .foregroundStyle(Color.Fairy.ink)
                    .padding(.horizontal, Spacing.md)

                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: Spacing.sm) {
                        ForEach(recentFiles.prefix(10)) { file in
                            RecentFileThumbnail(file: file)
                        }
                    }
                    .padding(.horizontal, Spacing.md)
                }
            }
        }
    }
}

struct RecentFileThumbnail: View {
    let file: RecentFile

    private var fileColor: Color {
        switch file.fileType.lowercased() {
        case "pdf":                   return .Fairy.green
        case "mbox":                  return .Fairy.teal
        case "heic", "jpeg", "png", "webp": return .Fairy.amber
        case "zip":                   return .Fairy.violet
        default:                      return .Fairy.mist
        }
    }

    private var fileIcon: String {
        switch file.fileType.lowercased() {
        case "pdf":                   return "doc.fill"
        case "mbox":                  return "envelope.fill"
        case "heic", "jpeg", "png", "webp": return "photo.fill"
        case "zip":                   return "archivebox.fill"
        case "csv":                   return "tablecells.fill"
        case "json":                  return "curlybraces"
        case "txt", "md", "log":     return "doc.text.fill"
        default:                      return "doc.fill"
        }
    }

    var body: some View {
        VStack(spacing: Spacing.xxs) {
            ZStack {
                Circle()
                    .fill(fileColor.opacity(0.15))
                    .frame(width: 48, height: 48)

                Image(systemName: fileIcon)
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundStyle(fileColor)
            }

            Text(file.displayName)
                .font(.Fairy.micro)
                .foregroundStyle(Color.Fairy.slate)
                .lineLimit(1)
                .frame(width: 56)
        }
    }
}
