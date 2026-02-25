// MBOXRootView.swift
// FileFairy

import SwiftUI

struct MBOXRootView: View {
    @Environment(AppEnvironment.self) private var appEnv

    var body: some View {
        NavigationStack(path: Binding(
            get: { appEnv.router.mboxPath },
            set: { appEnv.router.mboxPath = $0 }
        )) {
            MBOXLibraryView()
                .navigationTitle("Email Archives")
                .toolbarTitleDisplayMode(.large)
        }
        .tint(Color.Fairy.teal)
    }
}
