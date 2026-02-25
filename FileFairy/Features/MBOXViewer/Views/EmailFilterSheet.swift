// EmailFilterSheet.swift
// FileFairy

import SwiftUI

struct EmailFilterSheet: View {
    @Binding var viewModel: EmailListViewModel
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            Form {
                Section("Sort") {
                    Picker("Sort by", selection: $viewModel.sortOrder) {
                        ForEach(EmailListViewModel.SortOrder.allCases, id: \.self) { order in
                            Text(order.rawValue).tag(order)
                        }
                    }
                }
                Section("Filter") {
                    Toggle("Has Attachments Only", isOn: $viewModel.filterHasAttachments)
                        .tint(Color.Fairy.teal)
                }
            }
            .navigationTitle("Sort & Filter")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { dismiss() }
                }
            }
        }
    }
}
