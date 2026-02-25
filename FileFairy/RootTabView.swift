// RootTabView.swift
// FileFairy
//
// The top-level container view that hosts all five feature tabs.
// The system TabView bar is hidden — FairyTabBar provides the custom chrome.
// The tab bar floats above content via .safeAreaInset(edge: .bottom).

import SwiftUI
import QuickLook

// MARK: - RootTabView

struct RootTabView: View {

    @Environment(AppEnvironment.self) private var env
    @State private var emailFilterViewModel = EmailListViewModel()
    @State private var quickLookURL: URL? = nil

    var body: some View {
        @Bindable var router = env.router

        TabView(selection: $router.selectedTab) {
            HomeView()
                .tag(TabDestination.home)

            ScannerRootView()
                .tag(TabDestination.scanner)

            MBOXRootView()
                .tag(TabDestination.mbox)

            ConverterRootView()
                .tag(TabDestination.converter)

            FileOpenerRootView()
                .tag(TabDestination.fileOpener)
        }
        .toolbar(.hidden, for: .tabBar)
        .background(Color.Fairy.dust)
        // Floating glassmorphic tab bar — adds bottom safe area so content
        // scrolls above the bar without being obscured.
        .safeAreaInset(edge: .bottom, spacing: 0) {
            FairyTabBar()
                .background(Color.clear)
        }
        // MARK: Sheet Presentation
        .sheet(item: $router.presentedSheet) { destination in
            sheetView(for: destination)
                .withAppEnvironment(env)
        }
        // MARK: Full-Screen Cover Presentation
        .fullScreenCover(item: $router.presentedFullScreen) { destination in
            fullScreenView(for: destination)
                .withAppEnvironment(env)
        }
    }

    // MARK: - Sheet Factory

    @ViewBuilder
    private func sheetView(for destination: SheetDestination) -> some View {
        switch destination {
        case .paywall:
            PaywallView()

        case .settings:
            SettingsView()

        case .scanExport(let sessionID):
            ScanExportSheetWrapper(sessionID: sessionID)

        case .emailFilter:
            EmailFilterSheet(viewModel: $emailFilterViewModel)

        case .ocrText(let text):
            OCRTextSheet(text: text)

        case .renameFile(let currentName):
            FairyComingSoonSheet(
                icon: "pencil.line",
                message: "Rename \"\(currentName)\"",
                note: "Coming in a future update"
            )

        case .shareFiles(let urls):
            ShareSheet(items: urls)

        case .sortFilter:
            FairyComingSoonSheet(
                icon: "line.3.horizontal.decrease.circle",
                message: "Sort & Filter",
                note: "Coming in a future update"
            )

        case .formatPicker(let ext):
            FairyComingSoonSheet(
                icon: "doc.badge.gearshape",
                message: "Format options for .\(ext) files",
                note: "Coming in a future update"
            )
        }
    }

    // MARK: - Full-Screen Factory

    @ViewBuilder
    private func fullScreenView(for destination: FullScreenDestination) -> some View {
        switch destination {
        case .cameraScanner:
            ScannerCameraWrapper()

        case .onboarding:
            OnboardingView()

        case .documentPreview(let url):
            FairyQuickLookView(url: url)

        case .imageViewer(let pageID):
            FairyImageViewer(pageID: pageID)
        }
    }
}

// MARK: - ScanExportSheetWrapper

/// Bridges the sheet destination (which carries only a sessionID) to
/// ScanExportSheet which requires a ScannerViewModel.
private struct ScanExportSheetWrapper: View {
    let sessionID: UUID
    @State private var viewModel = ScannerViewModel()
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        ScanExportSheet(viewModel: viewModel)
    }
}

// MARK: - ScannerCameraWrapper

private struct ScannerCameraWrapper: View {
    @State private var viewModel = ScannerViewModel()
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        ScannerCameraView(viewModel: viewModel) {
            dismiss()
        }
    }
}

// MARK: - OCRTextSheet

private struct OCRTextSheet: View {
    let text: String
    @Environment(\.dismiss) private var dismiss
    @State private var copied = false

    var body: some View {
        NavigationStack {
            ScrollView {
                Text(text)
                    .font(.system(.body, design: .monospaced))
                    .foregroundStyle(Color.Fairy.ink)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(Spacing.md)
                    .textSelection(.enabled)
            }
            .background(Color.Fairy.dust)
            .navigationTitle("OCR Text")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Done") { dismiss() }
                }
                ToolbarItem(placement: .primaryAction) {
                    Button {
                        UIPasteboard.general.string = text
                        copied = true
                        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                            copied = false
                        }
                    } label: {
                        Label(copied ? "Copied!" : "Copy", systemImage: copied ? "checkmark" : "doc.on.doc")
                    }
                }
            }
        }
    }
}

// MARK: - FairyQuickLookView

private struct FairyQuickLookView: UIViewControllerRepresentable {
    let url: URL
    @Environment(\.dismiss) private var dismiss

    func makeUIViewController(context: Context) -> QLPreviewController {
        let controller = QLPreviewController()
        controller.dataSource = context.coordinator
        controller.delegate = context.coordinator
        return controller
    }

    func updateUIViewController(_ uiViewController: QLPreviewController, context: Context) {}

    func makeCoordinator() -> Coordinator { Coordinator(url: url, dismiss: dismiss) }

    final class Coordinator: NSObject, QLPreviewControllerDataSource, QLPreviewControllerDelegate {
        let url: URL
        let dismiss: DismissAction

        init(url: URL, dismiss: DismissAction) {
            self.url = url
            self.dismiss = dismiss
        }

        func numberOfPreviewItems(in controller: QLPreviewController) -> Int { 1 }
        func previewController(_ controller: QLPreviewController, previewItemAt index: Int) -> any QLPreviewItem {
            url as NSURL
        }
        func previewControllerDidDismiss(_ controller: QLPreviewController) {
            dismiss()
        }
    }
}

// MARK: - FairyImageViewer

private struct FairyImageViewer: View {
    let pageID: UUID
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @State private var image: UIImage? = nil
    @State private var scale: CGFloat = 1.0
    @State private var lastScale: CGFloat = 1.0

    var body: some View {
        NavigationStack {
            GeometryReader { _ in
                ZStack {
                    Color.black.ignoresSafeArea()

                    if let image {
                        Image(uiImage: image)
                            .resizable()
                            .scaledToFit()
                            .frame(maxWidth: .infinity, maxHeight: .infinity)
                            .scaleEffect(scale)
                            .gesture(
                                MagnificationGesture()
                                    .onChanged { value in
                                        scale = max(1.0, min(5.0, lastScale * value))
                                    }
                                    .onEnded { _ in
                                        lastScale = scale
                                        if scale < 1.05 {
                                            withAnimation(.fairySnappy) { scale = 1.0; lastScale = 1.0 }
                                        }
                                    }
                            )
                            .accessibilityLabel("Scanned page")
                            .accessibilityHint("Pinch to zoom")
                    } else {
                        ProgressView()
                            .tint(.white)
                            .accessibilityLabel("Loading image")
                    }
                }
            }
            .navigationTitle("Image")
            .navigationBarTitleDisplayMode(.inline)
            .toolbarBackground(.black, for: .navigationBar)
            .toolbarColorScheme(.dark, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Done") { dismiss() }
                        .foregroundStyle(.white)
                }
            }
        }
        .task { loadImage() }
    }

    @MainActor
    private func loadImage() {
        var descriptor = FetchDescriptor<ScannedPage>(
            predicate: #Predicate { $0.id == pageID }
        )
        descriptor.fetchLimit = 1
        guard let page = try? modelContext.fetch(descriptor).first else { return }
        if let data = page.imageData ?? page.thumbnailData {
            image = UIImage(data: data)
        }
    }
}

// MARK: - FairyComingSoonSheet

/// Shown for features that are planned but not yet implemented.
private struct FairyComingSoonSheet: View {
    let icon: String
    let message: String
    let note: String
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            FairyEmptyState(
                config: EmptyStateConfig(
                    systemImage: icon,
                    imageColor: .Fairy.violet,
                    title: message,
                    subtitle: note
                )
            )
            .background(Color.Fairy.dust)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Done") { dismiss() }
                }
            }
        }
    }
}

// MARK: - Preview

#Preview {
    RootTabView()
        .environment(AppEnvironment())
        .modelContainer(.preview)
}
