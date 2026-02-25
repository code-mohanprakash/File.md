// EmailDetailViewModel.swift
// FileFairy

import SwiftUI

@Observable
final class EmailDetailViewModel {

    var htmlContent: String = ""
    var attachments: [EmailAttachment] = []
    var isLoading = false
    var errorMessage: String?

    private let parser = MBOXParser()
    private let renderer = EmailBodyRenderer()
    private let extractor = AttachmentExtractor()

    @MainActor
    func loadEmail(_ email: EmailMessage, mboxPath: String) async {
        isLoading = true

        let url = URL(fileURLWithPath: mboxPath)
        guard let rawBody = await parser.loadFullBody(
            from: url,
            offset: email.bodyOffset,
            length: email.bodyLength
        ) else {
            errorMessage = "Could not load email body"
            isLoading = false
            return
        }

        htmlContent = await renderer.renderHTML(from: rawBody)
        attachments = await extractor.extractAttachments(from: rawBody)
        isLoading = false
    }
}
