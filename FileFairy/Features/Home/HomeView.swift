// HomeView.swift
// FileFairy
//
// The heart of FileFairy — a launcher for capabilities.
// From PRD Section 6.1: Each module is a large, tappable card with its own
// colour identity. Intentionally spacious with generous padding.

import SwiftUI

struct HomeView: View {

    @Environment(AppEnvironment.self) private var appEnv
    @State private var showQuickActions = false

    var body: some View {
        NavigationStack(path: Binding(
            get: { appEnv.router.homePath },
            set: { appEnv.router.homePath = $0 }
        )) {
            ScrollView {
                VStack(spacing: Spacing.base) {

                    // MARK: - Greeting
                    GreetingHeader()

                    // MARK: - Hero Cards
                    VStack(spacing: Spacing.sm) {

                        // Scanner Card - Rose Pink, 120pt tall
                        ModuleCard(
                            module: .scanner,
                            icon: "camera.fill",
                            title: "Scan Document",
                            subtitle: "Capture, crop & save",
                            layout: .hero(height: 120)
                        ) {
                            appEnv.router.switchTab(.scanner)
                        }

                        // MBOX Card - Teal, 100pt tall
                        ModuleCard(
                            module: .mbox,
                            icon: "envelope.fill",
                            title: "Email Archives",
                            subtitle: "Open .mbox files",
                            layout: .secondary(height: 100)
                        ) {
                            appEnv.router.switchTab(.mbox)
                        }
                    }
                    .padding(.horizontal, Spacing.md)

                    // MARK: - Tools Grid (2 columns)
                    LazyVGrid(
                        columns: [
                            GridItem(.flexible(), spacing: Spacing.md),
                            GridItem(.flexible(), spacing: Spacing.md)
                        ],
                        spacing: Spacing.md
                    ) {
                        // PDF Tools - Green
                        ToolGridCard(
                            title: "PDF Tools",
                            systemIcon: "doc.fill",
                            theme: .pdf
                        ) {
                            appEnv.router.switchTab(.converter)
                        }

                        // Image Convert - Amber
                        ToolGridCard(
                            title: "Convert",
                            systemIcon: "arrow.triangle.2.circlepath",
                            theme: .converter
                        ) {
                            appEnv.router.switchTab(.converter)
                        }

                        // File Opener - Indigo
                        ToolGridCard(
                            title: "Open File",
                            systemIcon: "folder.fill",
                            theme: .fileOpener
                        ) {
                            appEnv.router.switchTab(.fileOpener)
                        }

                        // Quick Actions - shows bottom sheet
                        ToolGridCard(
                            title: "Quick Actions",
                            systemIcon: "bolt.fill",
                            theme: nil
                        ) {
                            showQuickActions = true
                        }
                    }
                    .padding(.horizontal, Spacing.md)

                    // MARK: - Recent Files
                    RecentFilesRow()
                        .padding(.top, Spacing.xs)

                    // Bottom padding for floating tab bar
                    Spacer()
                        .frame(height: 100)
                }
            }
            .background(Color.Fairy.dust)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        appEnv.router.presentSheet(.settings)
                    } label: {
                        Image(systemName: "gearshape.circle")
                            .font(.system(size: 22))
                            .foregroundStyle(Color.Fairy.violet)
                    }
                    .frame(width: 44, height: 44)
                }
            }
        }
        .sheet(isPresented: $showQuickActions) {
            QuickActionsSheet()
                .withAppEnvironment(appEnv)
        }
    }
}

// MARK: - Quick Action Model (file-private, shared by sheet + card)

struct QuickActionItem {
    let title: String
    let subtitle: String
    let icon: String
    let color: Color
    let perform: (AppEnvironment) -> Void
}

// MARK: - QuickActionsSheet

struct QuickActionsSheet: View {

    @Environment(AppEnvironment.self) private var appEnv
    @Environment(\.dismiss) private var dismiss

    private var actions: [QuickActionItem] {
        [
            QuickActionItem(
                title: "Scan Document",
                subtitle: "Open camera scanner",
                icon: "camera.viewfinder",
                color: .Fairy.rose,
                perform: { env in env.router.presentFullScreen(.cameraScanner) }
            ),
            QuickActionItem(
                title: "Import MBOX",
                subtitle: "Open email archive viewer",
                icon: "envelope.badge",
                color: .Fairy.teal,
                perform: { env in env.router.switchTab(.mbox) }
            ),
            QuickActionItem(
                title: "Convert Image",
                subtitle: "HEIC, PNG, JPEG & more",
                icon: "photo.on.rectangle.angled",
                color: .Fairy.amber,
                perform: { env in env.router.switchTab(.converter) }
            ),
            QuickActionItem(
                title: "Open File",
                subtitle: "Browse and preview any file",
                icon: "folder.badge.plus",
                color: .Fairy.indigo,
                perform: { env in env.router.switchTab(.fileOpener) }
            )
        ]
    }

    var body: some View {
        NavigationStack {
            LazyVGrid(
                columns: [
                    GridItem(.flexible(), spacing: Spacing.md),
                    GridItem(.flexible(), spacing: Spacing.md)
                ],
                spacing: Spacing.md
            ) {
                ForEach(Array(actions.enumerated()), id: \.offset) { _, item in
                    QuickActionCard(item: item) {
                        dismiss()
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.35) {
                            item.perform(appEnv)
                        }
                    }
                }
            }
            .padding(Spacing.md)
            .navigationTitle("Quick Actions")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Done") { dismiss() }
                }
            }
            .background(Color.Fairy.dust)
        }
        .presentationDetents([.medium])
        .presentationCornerRadius(24)
    }
}

// MARK: - QuickActionCard

private struct QuickActionCard: View {

    let item: QuickActionItem
    let onTap: () -> Void

    var body: some View {
        Button(action: {
            HapticEngine.shared.light()
            onTap()
        }) {
            VStack(alignment: .leading, spacing: Spacing.sm) {
                ZStack {
                    RoundedRectangle(cornerRadius: CornerRadius.md, style: .continuous)
                        .fill(item.color.opacity(0.12))
                        .frame(width: 48, height: 48)

                    Image(systemName: item.icon)
                        .font(.system(size: 22, weight: .semibold))
                        .foregroundStyle(item.color)
                }

                VStack(alignment: .leading, spacing: Spacing.xxxs) {
                    Text(item.title)
                        .font(.Fairy.subtext)
                        .foregroundStyle(Color.Fairy.ink)
                        .multilineTextAlignment(.leading)

                    Text(item.subtitle)
                        .font(.Fairy.micro)
                        .foregroundStyle(Color.Fairy.mist)
                        .multilineTextAlignment(.leading)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(Spacing.md)
            .background(Color.white, in: RoundedRectangle.fairyLarge)
            .fairyShadow(.soft)
        }
        .buttonStyle(.plain)
        .pressScale()
    }
}

// MARK: - Tool Grid Card (Square)

struct ToolGridCard: View {
    let title: String
    let systemIcon: String
    let theme: ModuleTheme?
    let action: () -> Void

    private var iconColor: Color {
        theme?.primary ?? Color.Fairy.mist
    }

    private var bgColor: Color {
        theme?.light ?? Color.Fairy.softEdge.opacity(0.5)
    }

    var body: some View {
        Button(action: {
            HapticEngine.shared.light()
            action()
        }) {
            VStack(spacing: Spacing.sm) {
                ZStack {
                    RoundedRectangle(cornerRadius: CornerRadius.md, style: .continuous)
                        .fill(iconColor.opacity(0.12))
                        .frame(width: 48, height: 48)

                    Image(systemName: systemIcon)
                        .font(.system(size: 22, weight: .semibold))
                        .foregroundStyle(iconColor)
                }

                Text(title)
                    .font(.Fairy.subtext)
                    .foregroundStyle(Color.Fairy.ink)
            }
            .frame(maxWidth: .infinity)
            .frame(height: 120)
            .background(bgColor, in: RoundedRectangle.fairyLarge)
            .fairyShadow(.soft)
        }
        .buttonStyle(.plain)
        .pressScale()
    }
}

#Preview {
    HomeView()
        .environment(AppEnvironment())
}
