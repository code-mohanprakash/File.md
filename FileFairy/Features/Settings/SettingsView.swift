// SettingsView.swift
// FileFairy

import SwiftUI

struct SettingsView: View {
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            List {
                // Premium section — all features are free
                Section {
                    HStack(spacing: Spacing.md) {
                        Image(systemName: "crown.fill")
                            .foregroundStyle(Color.Fairy.amber)
                        VStack(alignment: .leading) {
                            Text("All Features Unlocked")
                                .font(.Fairy.body)
                                .foregroundStyle(Color.Fairy.ink)
                            Text("Everything is free")
                                .font(.Fairy.micro)
                                .foregroundStyle(Color.Fairy.mist)
                        }
                    }
                } header: {
                    Text("Access")
                }

                // App section
                Section {
                    HStack {
                        Text("Version")
                            .font(.Fairy.body)
                            .foregroundStyle(Color.Fairy.ink)
                        Spacer()
                        Text(Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0")
                            .font(.Fairy.caption)
                            .foregroundStyle(Color.Fairy.mist)
                    }

                    NavigationLink {
                        privacyView
                    } label: {
                        Label("Privacy", systemImage: "hand.raised.fill")
                            .font(.Fairy.body)
                            .foregroundStyle(Color.Fairy.ink)
                    }
                } header: {
                    Text("About")
                }

                // Data section
                Section {
                    Button(role: .destructive) {
                        TempDirectory.shared.removeAll()
                    } label: {
                        Label("Clear Temp Files", systemImage: "trash")
                            .font(.Fairy.body)
                    }
                } header: {
                    Text("Storage")
                }

                // Credits
                Section {
                    VStack(spacing: Spacing.sm) {
                        MascotView(mood: .happy, size: 64)
                        Text("Made with love by Mo")
                            .font(.Fairy.caption)
                            .foregroundStyle(Color.Fairy.mist)
                    }
                    .frame(maxWidth: .infinity)
                    .listRowBackground(Color.clear)
                }
            }
            .listStyle(.insetGrouped)
            .scrollContentBackground(.hidden)
            .background(Color.Fairy.dust)
            .navigationTitle("Settings")
            .toolbarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") { dismiss() }
                        .font(.Fairy.body)
                        .foregroundStyle(Color.Fairy.violet)
                }
            }
        }
    }

    private var privacyView: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: Spacing.md) {
                Text("Your Privacy Matters")
                    .font(.Fairy.title)
                    .foregroundStyle(Color.Fairy.ink)

                Text("FileFairy processes all files 100% on your device. We never upload your documents, emails, or scans to any server.")
                    .font(.Fairy.body)
                    .foregroundStyle(Color.Fairy.slate)

                VStack(alignment: .leading, spacing: Spacing.sm) {
                    privacyRow(icon: "iphone", text: "All processing happens on-device")
                    privacyRow(icon: "wifi.slash", text: "No internet required for any feature")
                    privacyRow(icon: "eye.slash.fill", text: "No tracking or analytics")
                    privacyRow(icon: "server.rack", text: "No third-party SDKs")
                }
                .padding(.top, Spacing.sm)
            }
            .padding(Spacing.md)
        }
        .background(Color.Fairy.dust)
        .navigationTitle("Privacy")
    }

    private func privacyRow(icon: String, text: String) -> some View {
        HStack(spacing: Spacing.md) {
            Image(systemName: icon)
                .foregroundStyle(Color.Fairy.green)
                .frame(width: 24)
            Text(text)
                .font(.Fairy.body)
                .foregroundStyle(Color.Fairy.ink)
        }
    }
}
