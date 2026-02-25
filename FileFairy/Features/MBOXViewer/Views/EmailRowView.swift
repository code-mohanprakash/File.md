// EmailRowView.swift
// FileFairy
// PRD: 40pt avatar, subject bold, sender, date, 2-line preview, 80pt row

import SwiftUI

struct EmailRowView: View {
    let email: EmailMessage

    private var avatarColor: Color {
        let colors: [Color] = [.Fairy.teal, .Fairy.violet, .Fairy.rose, .Fairy.amber, .Fairy.green]
        let hash = abs(email.from.hashValue)
        return colors[hash % colors.count]
    }

    var body: some View {
        HStack(alignment: .top, spacing: Spacing.sm) {
            // Avatar
            ZStack {
                Circle()
                    .fill(avatarColor.opacity(0.15))
                    .frame(width: 40, height: 40)
                Text(email.senderInitials)
                    .font(.system(size: 14, weight: .bold, design: .rounded))
                    .foregroundStyle(avatarColor)
            }

            VStack(alignment: .leading, spacing: Spacing.xxxs) {
                HStack {
                    Text(email.subject)
                        .font(.Fairy.subtext)
                        .fontWeight(.semibold)
                        .foregroundStyle(Color.Fairy.ink)
                        .lineLimit(1)
                    Spacer()
                    if email.hasAttachments {
                        Image(systemName: "paperclip")
                            .font(.system(size: 12))
                            .foregroundStyle(Color.Fairy.teal)
                    }
                }

                Text(email.from)
                    .font(.Fairy.caption)
                    .foregroundStyle(Color.Fairy.slate)
                    .lineLimit(1)

                Text(email.bodyPreview)
                    .font(.Fairy.caption)
                    .foregroundStyle(Color.Fairy.mist)
                    .lineLimit(2)
            }

            Text(email.date.formatted(.dateTime.month(.abbreviated).day()))
                .font(.Fairy.caption)
                .foregroundStyle(Color.Fairy.mist)
        }
        .padding(.vertical, Spacing.xxs)
        .frame(minHeight: 70)
    }
}
