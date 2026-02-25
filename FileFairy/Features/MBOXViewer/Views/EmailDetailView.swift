// EmailDetailView.swift
// FileFairy

import SwiftUI

struct EmailDetailView: View {
    let email: EmailMessage
    let mboxPath: String
    @State private var viewModel = EmailDetailViewModel()

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 0) {
                // Sender bar
                HStack(spacing: Spacing.sm) {
                    ZStack {
                        Circle()
                            .fill(Color.Fairy.teal.opacity(0.15))
                            .frame(width: 44, height: 44)
                        Text(email.senderInitials)
                            .font(.system(size: 16, weight: .bold, design: .rounded))
                            .foregroundStyle(Color.Fairy.teal)
                    }
                    VStack(alignment: .leading, spacing: Spacing.xxxs) {
                        Text(email.from)
                            .font(.Fairy.subtext)
                            .fontWeight(.semibold)
                            .foregroundStyle(Color.Fairy.ink)
                        Text("To: \(email.to)")
                            .font(.Fairy.caption)
                            .foregroundStyle(Color.Fairy.mist)
                            .lineLimit(1)
                    }
                    Spacer()
                    Text(email.date.formatted(date: .abbreviated, time: .shortened))
                        .font(.Fairy.caption)
                        .foregroundStyle(Color.Fairy.mist)
                }
                .padding(Spacing.md)
                .background(Color.Fairy.cream)

                // Subject
                Text(email.subject)
                    .font(.Fairy.title)
                    .foregroundStyle(Color.Fairy.ink)
                    .padding(.horizontal, Spacing.md)
                    .padding(.vertical, Spacing.sm)

                // Email body
                if viewModel.isLoading {
                    ProgressView()
                        .tint(Color.Fairy.teal)
                        .frame(maxWidth: .infinity, minHeight: 200)
                } else {
                    WebViewWrapper(htmlContent: viewModel.htmlContent)
                        .frame(minHeight: 300)
                }

                // Attachments
                if !viewModel.attachments.isEmpty {
                    VStack(alignment: .leading, spacing: Spacing.xs) {
                        Text("Attachments")
                            .font(.Fairy.subtext)
                            .fontWeight(.semibold)
                            .foregroundStyle(Color.Fairy.ink)
                        ForEach(viewModel.attachments) { attachment in
                            AttachmentRowView(attachment: attachment)
                        }
                    }
                    .padding(Spacing.md)
                }
            }
        }
        .background(Color.Fairy.dust)
        .navigationBarTitleDisplayMode(.inline)
        .task {
            await viewModel.loadEmail(email, mboxPath: mboxPath)
        }
    }
}
