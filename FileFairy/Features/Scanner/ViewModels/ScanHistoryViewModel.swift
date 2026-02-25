// ScanHistoryViewModel.swift
// FileFairy
//
// ViewModel for browsing past scan sessions from SwiftData.

import SwiftUI
import SwiftData

@Observable
final class ScanHistoryViewModel {

    var searchText: String = ""
    var sortNewestFirst: Bool = true

    private var modelContext: ModelContext?

    func setContext(_ context: ModelContext) {
        self.modelContext = context
    }

    func deleteScan(_ session: ScanSession) {
        guard let context = modelContext else { return }
        context.delete(session)
        try? context.save()
    }

    func deleteScans(at offsets: IndexSet, from sessions: [ScanSession]) {
        guard let context = modelContext else { return }
        for index in offsets {
            context.delete(sessions[index])
        }
        try? context.save()
    }
}
