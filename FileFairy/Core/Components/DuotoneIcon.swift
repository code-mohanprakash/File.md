// DuotoneIcon.swift
// FileFairy
//
// Two-layer SF Symbol icon following PRD spec:
//   "3pt weight rounded strokes, soft fills, primary violet accent tone."
//
// Layer 1: Soft translucent background shape (circle or rounded rect)
// Layer 2: Foreground SF Symbol in the primary color
//
// Supports circle and rounded-rect background shapes.
// Accepts a custom size, primary color, and optional secondary background tint.

import SwiftUI

// MARK: - Background Shape

enum DuotoneIconShape {
    case circle
    case roundedRect(radius: CGFloat)
    case squircle    // 32pt radius — large module icon standard

    var cornerRadius: CGFloat? {
        switch self {
        case .circle:                return nil
        case .roundedRect(let r):    return r
        case .squircle:              return CornerRadius.xl
        }
    }
}

// MARK: - DuotoneIcon

/// Two-layer icon: soft filled background + crisp SF Symbol foreground.
///
/// Usage:
/// ```swift
/// DuotoneIcon(systemName: "camera.viewfinder", color: .Fairy.rose)
/// DuotoneIcon(systemName: "tray.2.fill", color: .Fairy.teal, size: 56, shape: .squircle)
/// DuotoneIcon(systemName: "doc.richtext", color: .Fairy.green, size: 32)
/// ```
struct DuotoneIcon: View {

    let systemName: String
    let color: Color
    let size: CGFloat
    let shape: DuotoneIconShape
    var backgroundOpacity: Double

    init(
        systemName: String,
        color: Color = .Fairy.violet,
        size: CGFloat = 44,
        shape: DuotoneIconShape = .circle,
        backgroundOpacity: Double = 0.15
    ) {
        self.systemName = systemName
        self.color = color
        self.size = size
        self.shape = shape
        self.backgroundOpacity = backgroundOpacity
    }

    var body: some View {
        ZStack {
            backgroundLayer
            foregroundIcon
        }
        .frame(width: size, height: size)
        .accessibilityHidden(true)
    }

    // MARK: - Layers

    @ViewBuilder
    private var backgroundLayer: some View {
        switch shape {
        case .circle:
            Circle()
                .fill(
                    LinearGradient(
                        colors: [
                            color.opacity(backgroundOpacity + 0.06),
                            color.opacity(backgroundOpacity)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )

        case .roundedRect(let radius):
            RoundedRectangle(cornerRadius: radius, style: .continuous)
                .fill(
                    LinearGradient(
                        colors: [
                            color.opacity(backgroundOpacity + 0.06),
                            color.opacity(backgroundOpacity)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )

        case .squircle:
            RoundedRectangle(cornerRadius: CornerRadius.xl, style: .continuous)
                .fill(
                    LinearGradient(
                        colors: [
                            color.opacity(backgroundOpacity + 0.06),
                            color.opacity(backgroundOpacity)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
        }
    }

    private var foregroundIcon: some View {
        Image(systemName: systemName)
            .font(.system(size: symbolSize, weight: .semibold, design: .rounded))
            .foregroundStyle(
                LinearGradient(
                    colors: [color, color.opacity(0.8)],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            )
            .symbolRenderingMode(.hierarchical)
    }

    private var symbolSize: CGFloat {
        // Symbol occupies ~46% of the container, matching Apple HIG guidelines
        size * 0.46
    }
}

// MARK: - ModuleIcon

/// Pre-configured duotone icon sized and colored for a module theme.
/// Matches the large module card icon spec (squircle background).
struct ModuleIcon: View {

    let theme: ModuleTheme
    let systemName: String
    var size: CGFloat

    init(theme: ModuleTheme, systemName: String, size: CGFloat = 56) {
        self.theme = theme
        self.systemName = systemName
        self.size = size
    }

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: size * 0.33, style: .continuous)
                .fill(theme.gradient)

            Image(systemName: systemName)
                .font(.system(size: size * 0.44, weight: .semibold, design: .rounded))
                .foregroundStyle(Color.white)
                .symbolRenderingMode(.hierarchical)
        }
        .frame(width: size, height: size)
        .fairyShadow(FairyShadow.moduleGlow(theme.primary))
        .accessibilityHidden(true)
    }
}

// MARK: - FileTypeIcon

/// Duotone icon for specific file types.
struct FileTypeIcon: View {

    enum FileType {
        case pdf, docx, xlsx, pptx, image, audio, video, zip, generic

        var systemName: String {
            switch self {
            case .pdf:     return "doc.richtext"
            case .docx:    return "doc.text"
            case .xlsx:    return "tablecells"
            case .pptx:    return "rectangle.on.rectangle"
            case .image:   return "photo"
            case .audio:   return "waveform"
            case .video:   return "film"
            case .zip:     return "archivebox"
            case .generic: return "doc"
            }
        }

        var color: Color {
            switch self {
            case .pdf:     return .Fairy.green
            case .docx:    return .Fairy.teal
            case .xlsx:    return .Fairy.mint
            case .pptx:    return .Fairy.coral
            case .image:   return .Fairy.rose
            case .audio:   return .Fairy.violet
            case .video:   return .Fairy.amber
            case .zip:     return .Fairy.slate
            case .generic: return .Fairy.mist
            }
        }

        /// Infer from file extension
        static func from(extension ext: String) -> FileType {
            switch ext.lowercased() {
            case "pdf":                   return .pdf
            case "doc", "docx":           return .docx
            case "xls", "xlsx":           return .xlsx
            case "ppt", "pptx":           return .pptx
            case "jpg", "jpeg", "png", "heic", "webp", "gif": return .image
            case "mp3", "m4a", "aac", "wav": return .audio
            case "mp4", "mov", "avi":     return .video
            case "zip", "tar", "gz":      return .zip
            default:                      return .generic
            }
        }
    }

    let fileType: FileType
    var size: CGFloat

    init(fileType: FileType = .generic, size: CGFloat = 44) {
        self.fileType = fileType
        self.size = size
    }

    /// Convenience: initialise from a filename or extension string
    init(fileName: String, size: CGFloat = 44) {
        let ext = (fileName as NSString).pathExtension
        self.fileType = FileType.from(extension: ext)
        self.size = size
    }

    var body: some View {
        DuotoneIcon(
            systemName: fileType.systemName,
            color: fileType.color,
            size: size,
            shape: .roundedRect(radius: size * 0.28),
            backgroundOpacity: 0.14
        )
        .accessibilityHidden(true)
    }
}

// MARK: - Preview

#Preview("DuotoneIcon") {
    ScrollView {
        VStack(spacing: Spacing.xl) {

            // Core DuotoneIcon variants
            HStack(spacing: Spacing.md) {
                DuotoneIcon(systemName: "camera.viewfinder", color: .Fairy.rose, size: 56)
                DuotoneIcon(systemName: "tray.2.fill", color: .Fairy.teal, size: 56)
                DuotoneIcon(systemName: "arrow.2.circlepath", color: .Fairy.amber, size: 56)
                DuotoneIcon(systemName: "doc.richtext", color: .Fairy.green, size: 56)
            }

            // Squircle shape
            HStack(spacing: Spacing.md) {
                DuotoneIcon(systemName: "camera.viewfinder", color: .Fairy.rose, size: 56, shape: .squircle)
                DuotoneIcon(systemName: "tray.2.fill", color: .Fairy.teal, size: 56, shape: .squircle)
                DuotoneIcon(systemName: "arrow.2.circlepath", color: .Fairy.amber, size: 56, shape: .squircle)
            }

            // Module icons with gradient fill
            HStack(spacing: Spacing.md) {
                ModuleIcon(theme: .scanner, systemName: "camera.viewfinder")
                ModuleIcon(theme: .mbox, systemName: "tray.2.fill")
                ModuleIcon(theme: .converter, systemName: "arrow.2.circlepath")
                ModuleIcon(theme: .pdf, systemName: "doc.richtext")
                ModuleIcon(theme: .fileOpener, systemName: "folder.fill")
            }

            // File type icons
            VStack(alignment: .leading, spacing: Spacing.xs) {
                Text("File Type Icons").fairyText(.caption)
                LazyVGrid(columns: [GridItem(.adaptive(minimum: 52))], spacing: Spacing.sm) {
                    ForEach([
                        "report.pdf",
                        "document.docx",
                        "spreadsheet.xlsx",
                        "presentation.pptx",
                        "photo.jpg",
                        "song.mp3",
                        "movie.mp4",
                        "archive.zip",
                        "unknown.bin"
                    ], id: \.self) { name in
                        VStack(spacing: Spacing.xxxs) {
                            FileTypeIcon(fileName: name, size: 44)
                            Text((name as NSString).pathExtension.uppercased())
                                .font(.Fairy.micro)
                                .foregroundStyle(Color.Fairy.mist)
                        }
                    }
                }
            }

            // Size scale
            HStack(alignment: .bottom, spacing: Spacing.md) {
                ForEach([24, 32, 44, 56, 72] as [CGFloat], id: \.self) { s in
                    DuotoneIcon(systemName: "sparkles", color: .Fairy.violet, size: s)
                }
            }
        }
        .padding(Spacing.md)
    }
    .background(Color.Fairy.dust)
}
