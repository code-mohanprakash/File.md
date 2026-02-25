// ScannerRootView.swift
// FileFairy
//
// NavigationStack root for Scanner tab.
// Landing shows scan history; tapping "New Scan" opens camera.

import SwiftUI

struct ScannerRootView: View {

    @Environment(AppEnvironment.self) private var appEnv
    @Environment(\.modelContext) private var modelContext
    @State private var showCamera = false
    @State private var viewModel = ScannerViewModel()

    var body: some View {
        NavigationStack(path: Binding(
            get: { appEnv.router.scannerPath },
            set: { appEnv.router.scannerPath = $0 }
        )) {
            ScanHistoryView(onNewScan: {
                viewModel.setContext(modelContext)
                showCamera = true
            })
            .navigationTitle("Scanner")
            .toolbarTitleDisplayMode(.large)
        }
        .fullScreenCover(isPresented: $showCamera) {
            ScannerCameraView(viewModel: viewModel) {
                showCamera = false
                viewModel.reset()
            }
        }
        .tint(Color.Fairy.rose)
    }
}

#Preview {
    ScannerRootView()
        .environment(AppEnvironment())
}
