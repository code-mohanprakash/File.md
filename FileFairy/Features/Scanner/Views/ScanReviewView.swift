// ScanReviewView.swift
// FileFairy
//
// Paged review of captured scan images.
// From PRD: Review screen with crop handles, filter controls,
// Add Page / Done actions, name scan, choose PDF or JPEG.

import SwiftUI

struct ScanReviewView: View {

    @Bindable var viewModel: ScannerViewModel
    @State private var showExportSheet = false
    @State private var showOCRResult = false
    @State private var ocrText = ""

    var body: some View {
        VStack(spacing: 0) {

            // MARK: - Top Bar
            HStack {
                Button("Add Page") {
                    viewModel.addMorePages()
                }
                .font(.Fairy.button)
                .foregroundStyle(Color.Fairy.rose)

                Spacer()

                Text("Page \(viewModel.currentReviewIndex + 1) of \(viewModel.pageCount)")
                    .font(.Fairy.subtext)
                    .foregroundStyle(Color.Fairy.slate)

                Spacer()

                Button("Export") {
                    showExportSheet = true
                }
                .font(.Fairy.button)
                .foregroundStyle(Color.Fairy.violet)
            }
            .padding(.horizontal, Spacing.md)
            .padding(.vertical, Spacing.sm)
            .background(Color.Fairy.cream)

            // MARK: - Page Viewer
            TabView(selection: $viewModel.currentReviewIndex) {
                ForEach(Array(viewModel.capturedPages.enumerated()), id: \.offset) { index, image in
                    Image(uiImage: image)
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .padding(Spacing.md)
                        .tag(index)
                }
            }
            .tabViewStyle(.page(indexDisplayMode: .automatic))
            .background(Color.Fairy.dust)

            // MARK: - Bottom Actions
            VStack(spacing: Spacing.sm) {
                // Filter selector
                FilterPickerView(selectedFilter: $viewModel.currentFilter)

                // Action buttons
                HStack(spacing: Spacing.md) {
                    // Rotate
                    ActionIconButton(
                        icon: "rotate.right.fill",
                        label: "Rotate"
                    ) {
                        // Rotation handled by ImageFilterService
                    }

                    // OCR
                    ActionIconButton(
                        icon: "text.viewfinder",
                        label: "OCR"
                    ) {
                        Task {
                            if let text = try? await viewModel.performOCR(on: viewModel.currentReviewIndex) {
                                ocrText = text
                                showOCRResult = true
                            }
                        }
                    }

                    // Delete page
                    ActionIconButton(
                        icon: "trash.fill",
                        label: "Delete",
                        color: .Fairy.softRed
                    ) {
                        withAnimation(.fairyDismiss) {
                            viewModel.deletePage(at: viewModel.currentReviewIndex)
                        }
                        HapticEngine.shared.warning()
                    }
                }
                .padding(.horizontal, Spacing.md)
            }
            .padding(.vertical, Spacing.sm)
            .background(Color.Fairy.cream)
        }
        .sheet(isPresented: $showExportSheet) {
            ScanExportSheet(viewModel: viewModel)
                .presentationDetents([.medium])
        }
        .sheet(isPresented: $showOCRResult) {
            OCRResultView(text: ocrText)
                .presentationDetents([.medium, .large])
        }
    }
}

// MARK: - Action Icon Button

struct ActionIconButton: View {
    let icon: String
    let label: String
    var color: Color = .Fairy.slate
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: Spacing.xxs) {
                Image(systemName: icon)
                    .font(.system(size: 20))
                    .foregroundStyle(color)
                Text(label)
                    .font(.Fairy.caption)
                    .foregroundStyle(color)
            }
            .frame(maxWidth: .infinity)
        }
        .buttonStyle(.plain)
        .pressScale()
    }
}
