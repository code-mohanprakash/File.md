// ScanHistoryView.swift
// FileFairy
//
// Past scans list with thumbnails, dates, page counts.
// Empty state shows Fae mascot.

import SwiftUI
import SwiftData

struct ScanHistoryView: View {

    @Query(sort: \ScanSession.createdAt, order: .reverse)
    private var sessions: [ScanSession]

    @Environment(\.modelContext) private var modelContext
    @State private var viewModel = ScanHistoryViewModel()

    let onNewScan: () -> Void

    var body: some View {
        Group {
            if sessions.isEmpty {
                // Empty state with Fae
                VStack(spacing: Spacing.lg) {
                    Spacer()

                    MascotView(mood: .idle, size: 120)

                    Text("Ready to scan your first doc?")
                        .font(.Fairy.headline)
                        .foregroundStyle(Color.Fairy.ink)

                    Text("Tap the button below to capture, crop & save documents.")
                        .font(.Fairy.body)
                        .foregroundStyle(Color.Fairy.slate)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, Spacing.xl)

                    Button(action: onNewScan) {
                        Label("New Scan", systemImage: "camera.fill")
                            .font(.Fairy.button)
                            .foregroundStyle(.white)
                            .padding(.horizontal, Spacing.xl)
                            .padding(.vertical, Spacing.sm)
                            .background(Color.Fairy.rose, in: .capsule)
                    }
                    .pressScale()
                    .padding(.top, Spacing.sm)

                    Spacer()
                }
                .frame(maxWidth: .infinity)
                .background(Color.Fairy.dust)
            } else {
                List {
                    ForEach(sessions) { session in
                        ScanSessionRow(session: session)
                    }
                    .onDelete { offsets in
                        viewModel.deleteScans(at: offsets, from: sessions)
                    }
                }
                .listStyle(.plain)
                .background(Color.Fairy.dust)
                .scrollContentBackground(.hidden)
            }
        }
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button(action: onNewScan) {
                    Image(systemName: "camera.fill")
                        .foregroundStyle(Color.Fairy.rose)
                }
            }
        }
        .onAppear {
            viewModel.setContext(modelContext)
        }
    }
}

// MARK: - Session Row

struct ScanSessionRow: View {
    let session: ScanSession

    var body: some View {
        HStack(spacing: Spacing.sm) {
            // Thumbnail placeholder
            ZStack {
                RoundedRectangle(cornerRadius: CornerRadius.sm, style: .continuous)
                    .fill(Color.Fairy.blush)
                    .frame(width: 56, height: 56)

                Image(systemName: "doc.text.fill")
                    .font(.system(size: 22))
                    .foregroundStyle(Color.Fairy.rose)
            }

            VStack(alignment: .leading, spacing: Spacing.xxs) {
                Text(session.title)
                    .font(.Fairy.headline)
                    .foregroundStyle(Color.Fairy.ink)
                    .lineLimit(1)

                HStack(spacing: Spacing.xs) {
                    Text("\(session.pageCount) page\(session.pageCount == 1 ? "" : "s")")
                        .font(.Fairy.caption)
                        .foregroundStyle(Color.Fairy.mist)

                    Text(".")
                        .foregroundStyle(Color.Fairy.mist)

                    Text(session.createdAt.formatted(date: .abbreviated, time: .shortened))
                        .font(.Fairy.caption)
                        .foregroundStyle(Color.Fairy.mist)
                }

                Text(session.exportFormat.uppercased())
                    .font(.Fairy.micro)
                    .foregroundStyle(Color.Fairy.rose)
                    .padding(.horizontal, Spacing.xs)
                    .padding(.vertical, Spacing.xxxs)
                    .background(Color.Fairy.blush, in: .capsule)
            }

            Spacer()

            Image(systemName: "chevron.right")
                .font(.system(size: 12, weight: .semibold))
                .foregroundStyle(Color.Fairy.mist)
        }
        .padding(.vertical, Spacing.xs)
        .listRowBackground(Color.Fairy.dust)
    }
}
