// EmailMessage.swift
// FileFairy
//
// SwiftData model for a parsed email message.
// Stores only summary data in the model; full body loaded on-demand via byte offset.

import SwiftData
import Foundation

@Model
final class EmailMessage {
    var id: UUID
    var messageId: String
    var from: String
    var to: String
    var subject: String
    var date: Date
    var bodyPreview: String      // First 200 chars of body text
    var bodyOffset: Int64        // Byte offset in source MBOX file for on-demand loading
    var bodyLength: Int          // Byte length of the full message
    var hasAttachments: Bool
    var isRead: Bool

    var mboxFile: MBOXFile?

    /// Sender's display initials for avatar
    var senderInitials: String {
        let parts = from.split(separator: " ")
        if parts.count >= 2 {
            return String(parts[0].prefix(1) + parts[1].prefix(1)).uppercased()
        }
        return String(from.prefix(2)).uppercased()
    }

    /// Clean subject without Re:/Fwd: prefixes (for thread grouping)
    var normalizedSubject: String {
        var s = subject
        let prefixes = ["Re:", "RE:", "Fwd:", "FWD:", "Fw:", "FW:"]
        for prefix in prefixes {
            while s.hasPrefix(prefix) {
                s = String(s.dropFirst(prefix.count)).trimmingCharacters(in: .whitespaces)
            }
        }
        return s
    }

    init(
        messageId: String = "",
        from: String,
        to: String = "",
        subject: String,
        date: Date,
        bodyPreview: String = "",
        bodyOffset: Int64 = 0,
        bodyLength: Int = 0,
        hasAttachments: Bool = false
    ) {
        self.id = UUID()
        self.messageId = messageId
        self.from = from
        self.to = to
        self.subject = subject
        self.date = date
        self.bodyPreview = bodyPreview
        self.bodyOffset = bodyOffset
        self.bodyLength = bodyLength
        self.hasAttachments = hasAttachments
        self.isRead = false
    }
}
