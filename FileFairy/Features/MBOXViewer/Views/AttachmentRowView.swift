// AttachmentRowView.swift
// FileFairy - Tappable attachment pill with icon + filename + size

import SwiftUI

struct AttachmentRowView: View {
    let attachment: EmailAttachment

    var body: some View {
        HStack(spacing: Spacing.xs) {
            Image(systemName: attachment.fileIcon)
                .font(.system(size: 14))
                .foregroundStyle(Color.Fairy.teal)
            Text(attachment.filename)
                .font(.Fairy.caption)
                .foregroundStyle(Color.Fairy.ink)
                .lineLimit(1)
            Text(attachment.displaySize)
                .font(.Fairy.caption)
                .foregroundStyle(Color.Fairy.mist)
        }
        .padding(.horizontal, Spacing.sm)
        .padding(.vertical, Spacing.xs)
        .background(Color.Fairy.iceBlue, in: .capsule)
        .overlay(Capsule().stroke(Color.Fairy.teal.opacity(0.3), lineWidth: 1))
    }
}
