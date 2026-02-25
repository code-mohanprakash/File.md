// EmailListView.swift
// FileFairy

import SwiftUI
import SwiftData

struct EmailListView: View {
    let mboxFile: MBOXFile

    @Query private var emails: [EmailMessage]
    @State private var viewModel = EmailListViewModel()
    @State private var showFilterSheet = false

    init(mboxFile: MBOXFile) {
        self.mboxFile = mboxFile
        let fileId = mboxFile.id
        _emails = Query(
            filter: #Predicate<EmailMessage> { $0.mboxFile?.id == fileId },
            sort: \.date,
            order: .reverse
        )
    }

    private var filteredEmails: [EmailMessage] {
        var result = emails
        if !viewModel.searchText.isEmpty {
            let query = viewModel.searchText.lowercased()
            result = result.filter {
                $0.subject.lowercased().contains(query) ||
                $0.from.lowercased().contains(query) ||
                $0.bodyPreview.lowercased().contains(query)
            }
        }
        if viewModel.filterHasAttachments {
            result = result.filter { $0.hasAttachments }
        }
        return result
    }

    var body: some View {
        List {
            ForEach(filteredEmails) { email in
                NavigationLink {
                    EmailDetailView(email: email, mboxPath: mboxFile.filePath)
                } label: {
                    EmailRowView(email: email)
                }
                .listRowBackground(Color.Fairy.dust)
                .listRowSeparatorTint(Color.Fairy.softEdge)
            }
        }
        .listStyle(.plain)
        .scrollContentBackground(.hidden)
        .background(Color.Fairy.dust)
        .searchable(text: $viewModel.searchText, prompt: "Search emails...")
        .navigationTitle(mboxFile.name)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button(action: { showFilterSheet = true }) {
                    Image(systemName: "line.3.horizontal.decrease.circle")
                        .foregroundStyle(Color.Fairy.teal)
                }
            }
        }
        .sheet(isPresented: $showFilterSheet) {
            EmailFilterSheet(viewModel: $viewModel)
                .presentationDetents([.medium])
        }
    }
}
