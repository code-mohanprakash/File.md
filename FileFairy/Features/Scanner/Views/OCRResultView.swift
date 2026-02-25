// OCRResultView.swift
// FileFairy
//
// Scrollable OCR text with copy button.

import SwiftUI

struct OCRResultView: View {

    let text: String
    @State private var copied = false

    var body: some View {
        NavigationStack {
            ScrollView {
                if text.isEmpty {
                    VStack(spacing: Spacing.md) {
                        Image(systemName: "text.magnifyingglass")
                            .font(.system(size: 40))
                            .foregroundStyle(Color.Fairy.mist)

                        Text("No text detected")
                            .font(.Fairy.headline)
                            .foregroundStyle(Color.Fairy.ink)

                        Text("Try scanning a document with clearer text.")
                            .font(.Fairy.body)
                            .foregroundStyle(Color.Fairy.slate)
                            .multilineTextAlignment(.center)
                    }
                    .padding(.top, Spacing.xxl)
                } else {
                    Text(text)
                        .font(.Fairy.body)
                        .foregroundStyle(Color.Fairy.ink)
                        .textSelection(.enabled)
                        .padding(Spacing.md)
                }
            }
            .background(Color.Fairy.dust)
            .navigationTitle("Recognized Text")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        UIPasteboard.general.string = text
                        copied = true
                        HapticEngine.shared.success()
                        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                            copied = false
                        }
                    } label: {
                        Label(
                            copied ? "Copied!" : "Copy",
                            systemImage: copied ? "checkmark" : "doc.on.doc"
                        )
                    }
                    .disabled(text.isEmpty)
                }
            }
        }
    }
}
