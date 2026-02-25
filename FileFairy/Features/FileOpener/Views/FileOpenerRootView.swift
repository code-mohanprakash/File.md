// FileOpenerRootView.swift
// FileFairy

import SwiftUI

struct FileOpenerRootView: View {
    @Environment(AppEnvironment.self) private var appEnv

    var body: some View {
        NavigationStack(path: Binding(
            get: { appEnv.router.fileOpenerPath },
            set: { appEnv.router.fileOpenerPath = $0 }
        )) {
            FileOpenerLandingView()
                .navigationTitle("Open File")
                .toolbarTitleDisplayMode(.large)
        }
        .tint(Color.Fairy.violet)
    }
}
