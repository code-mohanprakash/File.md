// FileFairyApp.swift
// FileFairy
//
// Your Magical File Helper
// Scan . View . Convert . Open Anything

import SwiftUI
import SwiftData

@main
struct FileFairyApp: App {

    @State private var appEnvironment = AppEnvironment()
    @State private var showSplash = true

    var body: some Scene {
        WindowGroup {
            ZStack {
                if showSplash {
                    SplashView {
                        withAnimation(.easeInOut(duration: 0.4)) {
                            showSplash = false
                        }
                    }
                    .transition(.opacity)
                } else {
                    RootTabView()
                        .environment(appEnvironment)
                        .transition(.opacity)
                        .onOpenURL { url in
                            DeepLinkHandler.handle(url, router: appEnvironment.router)
                        }
                        .onAppear {
                            if !appEnvironment.hasCompletedOnboarding {
                                appEnvironment.router.presentFullScreen(.onboarding)
                            }
                        }
                }
            }
            .environment(appEnvironment)
            .animation(.easeInOut(duration: 0.4), value: showSplash)
        }
        .modelContainer(AppSchema.container)
    }
}
