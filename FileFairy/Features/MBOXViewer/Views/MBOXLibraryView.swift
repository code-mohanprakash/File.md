// MBOXLibraryView.swift
// FileFairy

import SwiftUI
import SwiftData
import UniformTypeIdentifiers

struct MBOXLibraryView: View {
    @Query(sort: \MBOXFile.importedAt, order: .reverse) private var files: [MBOXFile]
    @Environment(\.modelContext) private var modelContext
    @State private var viewModel = MBOXLibraryViewModel()

    var body: some View {
        Group {
            if files.isEmpty && !viewModel.isImporting {
                // Empty state
                VStack(spacing: Spacing.lg) {
                    Spacer()
                    MascotView(mood: .thinking, size: 120)
                    Text("Import an .mbox to get started!")
                        .font(.Fairy.headline)
                        .foregroundStyle(Color.Fairy.ink)
                    Text("Open Gmail Takeout archives and browse emails beautifully, entirely on-device.")
                        .font(.Fairy.body)
                        .foregroundStyle(Color.Fairy.slate)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, Spacing.xl)
                    Button(action: { viewModel.showFilePicker = true }) {
                        Label("Import .mbox File", systemImage: "envelope.badge.arrow.down")
                            .font(.Fairy.button)
                            .foregroundStyle(.white)
                            .padding(.horizontal, Spacing.xl)
                            .padding(.vertical, Spacing.sm)
                            .background(Color.Fairy.teal, in: .capsule)
                    }
                    .pressScale()
                    Spacer()
                }
            } else {
                List {
                    ForEach(files) { file in
                        NavigationLink(value: file.id) {
                            MBOXFileRow(file: file)
                        }
                        .listRowBackground(Color.Fairy.dust)
                    }
                    .onDelete { offsets in
                        for i in offsets { viewModel.deleteMBOXFile(files[i]) }
                    }
                }
                .listStyle(.plain)
                .scrollContentBackground(.hidden)
            }
        }
        .background(Color.Fairy.dust)
        .overlay {
            if viewModel.isImporting {
                MBOXImportProgressView(
                    progress: viewModel.importProgress,
                    emailCount: viewModel.importedEmailCount,
                    onCancel: { viewModel.cancelImport() }
                )
            }
        }
        .navigationDestination(for: UUID.self) { fileId in
            if let file = files.first(where: { $0.id == fileId }) {
                EmailListView(mboxFile: file)
            }
        }
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button(action: { viewModel.showFilePicker = true }) {
                    Image(systemName: "plus.circle.fill")
                        .foregroundStyle(Color.Fairy.teal)
                }
            }
        }
        .fileImporter(
            isPresented: $viewModel.showFilePicker,
            allowedContentTypes: [UTType(filenameExtension: "mbox") ?? .data],
            allowsMultipleSelection: false
        ) { result in
            if case .success(let urls) = result, let url = urls.first {
                viewModel.importFile(url: url)
            }
        }
        .onAppear { viewModel.setContext(modelContext) }
    }
}

struct MBOXFileRow: View {
    let file: MBOXFile

    var body: some View {
        HStack(spacing: Spacing.sm) {
            ZStack {
                RoundedRectangle(cornerRadius: CornerRadius.sm, style: .continuous)
                    .fill(Color.Fairy.iceBlue)
                    .frame(width: 48, height: 48)
                Image(systemName: "envelope.fill")
                    .font(.system(size: 20))
                    .foregroundStyle(Color.Fairy.teal)
            }
            VStack(alignment: .leading, spacing: Spacing.xxs) {
                Text(file.name)
                    .font(.Fairy.headline)
                    .foregroundStyle(Color.Fairy.ink)
                    .lineLimit(1)
                HStack(spacing: Spacing.xs) {
                    Text("\(file.emailCount) emails")
                    Text("·")
                    Text(ByteCountFormatter.string(fromByteCount: file.sizeBytes, countStyle: .file))
                }
                .font(.Fairy.caption)
                .foregroundStyle(Color.Fairy.mist)
            }
            Spacer()
        }
        .padding(.vertical, Spacing.xxs)
    }
}
