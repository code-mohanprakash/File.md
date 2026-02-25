// ConverterRootView.swift
// FileFairy

import SwiftUI

struct ConverterRootView: View {
    @Environment(AppEnvironment.self) private var appEnv

    var body: some View {
        NavigationStack(path: Binding(
            get: { appEnv.router.converterPath },
            set: { appEnv.router.converterPath = $0 }
        )) {
            ConverterHubView()
                .navigationTitle("Convert")
                .toolbarTitleDisplayMode(.large)
                .navigationDestination(for: ConversionType.self) { type in
                    conversionView(for: type)
                }
        }
        .tint(Color.Fairy.amber)
    }

    @ViewBuilder
    private func conversionView(for type: ConversionType) -> some View {
        Group {
            switch type {
            case .heicToJpeg, .heicToPng, .webpToPng, .webpToJpeg, .pngToJpeg, .imageCompress:
                ImageConverterView(conversionType: type)
            case .imageToPdf:
                ImageConverterView(conversionType: type)
            case .pdfMerge:
                PDFMergeView()
            case .pdfSplit:
                PDFSplitView()
            case .pdfCompress:
                PDFCompressView()
            case .imageResize:
                ImageConverterView(conversionType: type)
            case .zipExtract, .csvView, .jsonView, .textView:
                ImageConverterView(conversionType: type)
            }
        }
        .requiresPremium(type.requiresPremium)
    }
}
