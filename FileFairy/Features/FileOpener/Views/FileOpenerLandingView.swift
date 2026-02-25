// FileOpenerLandingView.swift
// FileFairy

import SwiftUI
import SwiftData
import UniformTypeIdentifiers
import QuickLook

struct FileOpenerLandingView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \RecentFile.openedAt, order: .reverse) private var recentFiles: [RecentFile]
    @State private var viewModel = FileOpenerViewModel()

    var body: some View {
        ScrollView {
            VStack(spacing: Spacing.lg) {
                // Drop zone
                Button(action: { viewModel.showFilePicker = true }) {
                    VStack(spacing: Spacing.md) {
                        Image(systemName: "folder.badge.plus")
                            .font(.system(size: 40))
                            .foregroundStyle(Color.Fairy.violet)
                        Text("Open a File")
                            .font(.Fairy.headline)
                            .foregroundStyle(Color.Fairy.ink)
                        Text("Tap to browse or drop a file here")
                            .font(.Fairy.subtext)
                            .foregroundStyle(Color.Fairy.mist)
                    }
                    .frame(maxWidth: .infinity)
                    .frame(height: 180)
                    .background(Color.Fairy.dust, in: RoundedRectangle.fairyXL)
                    .overlay(
                        RoundedRectangle(cornerRadius: CornerRadius.xl, style: .continuous)
                            .strokeBorder(Color.Fairy.violet.opacity(0.3), style: StrokeStyle(lineWidth: 2, dash: [8, 6]))
                    )
                }
                .buttonStyle(.plain)
                .pressScale(0.98)
                .padding(.horizontal, Spacing.md)

                // Recent files
                if !recentFiles.isEmpty {
                    VStack(alignment: .leading, spacing: Spacing.sm) {
                        HStack {
                            Text("Recent")
                                .font(.Fairy.headline)
                                .foregroundStyle(Color.Fairy.ink)
                            Spacer()
                            Button("Clear") { viewModel.clearHistory() }
                                .font(.Fairy.caption)
                                .foregroundStyle(Color.Fairy.mist)
                        }
                        .padding(.horizontal, Spacing.md)

                        LazyVGrid(columns: [GridItem(.adaptive(minimum: 100))], spacing: Spacing.sm) {
                            ForEach(recentFiles.prefix(12)) { file in
                                RecentFileCard(file: file) {
                                    let url = URL(fileURLWithPath: file.filePath)
                                    viewModel.openFile(url: url)
                                }
                            }
                        }
                        .padding(.horizontal, Spacing.md)
                    }
                }

                Spacer().frame(height: 100)
            }
            .padding(.top, Spacing.md)
        }
        .background(Color.Fairy.dust)
        .fileImporter(
            isPresented: $viewModel.showFilePicker,
            allowedContentTypes: [.item],
            allowsMultipleSelection: false
        ) { result in
            if case .success(let urls) = result, let url = urls.first {
                viewModel.openFile(url: url)
            }
        }
        .quickLookPreview($viewModel.selectedFileURL)
        .onAppear { viewModel.setContext(modelContext) }
    }
}

struct RecentFileCard: View {
    let file: RecentFile
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            let info = FileTypeResolver.resolve(URL(fileURLWithPath: file.filePath))
            VStack(spacing: Spacing.xs) {
                ZStack {
                    RoundedRectangle(cornerRadius: CornerRadius.md, style: .continuous)
                        .fill(info.color.opacity(0.1))
                        .frame(width: 56, height: 56)
                    Image(systemName: info.icon)
                        .font(.system(size: 22))
                        .foregroundStyle(info.color)
                }
                Text(file.displayName)
                    .font(.Fairy.caption)
                    .foregroundStyle(Color.Fairy.ink)
                    .lineLimit(2)
                    .multilineTextAlignment(.center)
                Text(info.label)
                    .font(.Fairy.micro)
                    .foregroundStyle(Color.Fairy.mist)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, Spacing.sm)
        }
        .buttonStyle(.plain)
    }
}
