// EmailListViewModel.swift
// FileFairy

import SwiftUI
import SwiftData

@Observable
final class EmailListViewModel {

    var searchText = ""
    var sortOrder: SortOrder = .dateDesc
    var filterHasAttachments = false
    var errorMessage: String?

    enum SortOrder: String, CaseIterable {
        case dateDesc = "Newest First"
        case dateAsc = "Oldest First"
        case senderAZ = "Sender A-Z"
        case subjectAZ = "Subject A-Z"
    }

    func sortDescriptor() -> SortDescriptor<EmailMessage> {
        switch sortOrder {
        case .dateDesc:   return SortDescriptor(\.date, order: .reverse)
        case .dateAsc:    return SortDescriptor(\.date, order: .forward)
        case .senderAZ:   return SortDescriptor(\.from, order: .forward)
        case .subjectAZ:  return SortDescriptor(\.subject, order: .forward)
        }
    }
}
