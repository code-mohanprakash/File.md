// ConversionResultView.swift
// FileFairy

import SwiftUI

struct ConversionResultView: View {
    let outputURL: URL
    let conversionType: ConversionType
    let onPreview: () -> Void
    let onReset: () -> Void

    @State private var appeared = false

    private var fileSize: String {
        guard let attrs = try? FileManager.default.attributesOfItem(atPath: outputURL.path),
              let size = attrs[.size] as? Int64 else { return "—" }
        return ByteCountFormatter.string(fromByteCount: size, countStyle: .file)
    }

    var body: some View {
        VStack(spacing: Spacing.md) {
            // Success icon
            ZStack {
                Circle()
                    .fill(Color.Fairy.green.opacity(0.1))
                    .frame(width: 64, height: 64)

                Image(systemName: "checkmark.circle.fill")
                    .font(.system(size: 32))
                    .foregroundStyle(Color.Fairy.green)
                    .scaleEffect(appeared ? 1 : 0.3)
                    .opacity(appeared ? 1 : 0)
            }

            VStack(spacing: Spacing.xs) {
                Text("Conversion Complete")
                    .font(.Fairy.headline)
                    .foregroundStyle(Color.Fairy.ink)

                Text(outputURL.lastPathComponent)
                    .font(.Fairy.caption)
                    .foregroundStyle(Color.Fairy.mist)
                    .lineLimit(1)

                Text(fileSize)
                    .font(.Fairy.micro)
                    .foregroundStyle(Color.Fairy.mist)
            }

            // Actions
            HStack(spacing: Spacing.md) {
                // Preview
                Button(action: onPreview) {
                    Label("Preview", systemImage: "eye.fill")
                        .font(.Fairy.caption)
                        .foregroundStyle(conversionType.featureColor)
                        .padding(.horizontal, Spacing.md)
                        .padding(.vertical, Spacing.sm)
                        .background(conversionType.featureColor.opacity(0.1), in: Capsule())
                }
                .buttonStyle(.plain)

                // Share
                ShareLink(item: outputURL) {
                    Label("Share", systemImage: "square.and.arrow.up")
                        .font(.Fairy.caption)
                        .foregroundStyle(Color.Fairy.violet)
                        .padding(.horizontal, Spacing.md)
                        .padding(.vertical, Spacing.sm)
                        .background(Color.Fairy.violet.opacity(0.1), in: Capsule())
                }

                // Save
                Button {
                    saveToFiles()
                } label: {
                    Label("Save", systemImage: "folder.fill")
                        .font(.Fairy.caption)
                        .foregroundStyle(Color.Fairy.green)
                        .padding(.horizontal, Spacing.md)
                        .padding(.vertical, Spacing.sm)
                        .background(Color.Fairy.green.opacity(0.1), in: Capsule())
                }
                .buttonStyle(.plain)
            }

            // Convert another
            Button(action: onReset) {
                Text("Convert Another")
                    .font(.Fairy.caption)
                    .foregroundStyle(Color.Fairy.mist)
            }
            .padding(.top, Spacing.xs)
        }
        .frame(maxWidth: .infinity)
        .padding(Spacing.lg)
        .background(Color.Fairy.cream, in: RoundedRectangle.fairyXL)
        .fairyShadow(.soft)
        .onAppear {
            withAnimation(.fairyCelebrate) {
                appeared = true
            }
        }
    }

    private func saveToFiles() {
        guard let docs = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first else { return }
        let dest = docs.appendingPathComponent(outputURL.lastPathComponent)
        // Remove existing file at destination before copying
        try? FileManager.default.removeItem(at: dest)
        try? FileManager.default.copyItem(at: outputURL, to: dest)
    }
}
