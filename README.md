# FileFairy

An iOS file toolkit that scans documents with on-device OCR, parses MBOX email archives, converts and compresses PDFs, and opens any file type from the Files app — all without a server.

## The Problem

Most document tools on iOS either require a subscription to unlock basic features or send your files to a cloud server for processing. FileFairy handles everything on-device: scanning, OCR, PDF manipulation, and email archive parsing all happen locally, with no data leaving the phone.

## Features

- **Document scanner** — live camera preview with real-time document edge detection; captures multi-page scan sessions stored as `ScanSession` + `ScannedPage` in SwiftData
- **4 filter presets** — Colour (contrast boost + shadow removal via `CIHighlightShadowAdjust`), Greyscale (`CIPhotoEffectMono` + contrast), B&W (adaptive threshold via `CIColorControls` at 3.0 contrast), and Photo (no processing)
- **Perspective correction** — `CIFilter.perspectiveCorrection()` applied from the `VNRectangleObservation` quad corners before filter processing
- **On-device OCR** — `VNRecognizeTextRequest` at `.accurate` level with language correction; supports up to 18 languages; result is copyable plain text
- **PDF export** — `PDFKit.PDFDocument` built from scanned `UIImage` pages and written to the Documents/Scans directory; JPEG bundle export also supported
- **MBOX viewer** — streaming line-by-line parser using 64 KB buffered reads via `FileHandle`; handles 2 GB+ files without loading into memory; uses `AsyncStream` to emit parsed emails
- **Email filtering** — filter MBOX messages by sender, date range, and attachment presence
- **Email body rendering** — HTML and plain-text bodies rendered in `WKWebView` via `WebViewWrapper`
- **Attachment extraction** — MIME base64 decode with inline preview via `AttachmentExtractor`
- **PDF merge** — combines multiple `PDFDocument` objects page-by-page using `PDFKit`
- **PDF split** — extracts individual pages or ranges from a `PDFDocument` into separate files
- **PDF compress** — re-renders each PDF page as JPEG at configurable DPI (72 / 100 / 150) and JPEG quality (0.4 / 0.6 / 0.8) using `CGContext`
- **Image conversion** — PNG ↔ JPEG ↔ HEIF/HEIC at custom quality via `ImageIO`
- **Image resize** — scale with aspect-ratio lock via `UIGraphicsImageRenderer`
- **ZIP extraction** — extract ZIP archives via `ZIPFoundation`
- **CSV viewer** — rows parsed and displayed in a scrollable table
- **JSON viewer** — pretty-printed with monospaced font and `textSelection(.enabled)`
- **File browser** — open any file from the Files app via `LSSupportsOpeningDocumentsInPlace`; QuickLook preview via `QLPreviewController`; recent files persisted in SwiftData
- **Recent files home feed** — `HomeView` surfaces the last-opened files with file-type icon, size, and relative date
- **5-page onboarding** — gradient slides with feature images; first-launch gating via `AppStorage`
- **Deep link routing** — URL scheme handler (`DeepLinkHandler`) drives `AppRouter` to any tab or sheet destination
- **Haptic + sound feedback** — `CoreHaptics` engine for light/medium/heavy/success patterns; `AVAudioPlayer` for UI sound events

## Tech Stack

- **UI:** SwiftUI (100% — UIKit used only for `UIViewRepresentable` wrappers: `CameraPreviewView`, `WebViewWrapper`, `FairyQuickLookView`, `ShareSheet`)
- **AI/ML:** Vision framework — `VNRecognizeTextRequest` for OCR, `VNDetectRectanglesRequest` for live document edge detection
- **Data:** SwiftData (`@Model` for `ScanSession`, `ScannedPage`, `MBOXFile`, `RecentFile`; `@Attribute(.externalStorage)` for image binaries)
- **Apple Services:** AVFoundation (`AVCaptureSession` for camera), PDFKit, WebKit (`WKWebView`), StoreKit (scaffolded, no-op — all features free), QuickLook, CoreImage, CoreHaptics, UniformTypeIdentifiers, `os.log`
- **Third Party:** [ZIPFoundation](https://github.com/weichsel/ZIPFoundation) `≥ 0.9.19` — ZIP archive extraction

## Architecture

MVVM with `@Observable` (Swift 5.9 Observation framework — no `ObservableObject`, no `@Published`, no Combine).

All services are Swift `actor`s; all ViewModels are `@MainActor`-isolated `@Observable` classes. Strict concurrency is enabled (`SWIFT_STRICT_CONCURRENCY = complete`).

**Navigation** is centralized through `AppRouter` — a single `@Observable` class holding one `NavigationPath` per tab plus `activeSheet: SheetDestination?` and `activeFullscreen: FullscreenDestination?`. No ad-hoc `@State var showSheet` in feature views.

**Dependency injection** is handled by `AppEnvironment`, an `@Observable` container holding all service singletons, injected at the root via SwiftUI `.environment(\.appEnvironment, ...)`.

Key files:

| File | Role |
|------|------|
| `FileFairyApp.swift` | `@main`, creates `AppEnvironment`, shows splash → onboarding → `RootTabView` |
| `RootTabView.swift` | Tab container; resolves all `SheetDestination` cases |
| `AppRouter.swift` | Single source of truth for all navigation state |
| `TabDestination.swift` | Exhaustive enums for push (`TabDestination`) and sheet (`SheetDestination`) routes |
| `AppEnvironment.swift` | DI root — instantiates and owns all actor services |
| `AppError.swift` | Typed error enum (11 cases) with `LocalizedError` conformance |
| `ErrorHandler.swift` | `@MainActor` singleton bridging thrown errors to observable UI state |
| `ColorPalette.swift` | All `Color.Fairy.*` design tokens and `ModuleTheme` gradients |
| `OCRService.swift` | `actor` — wraps `VNRecognizeTextRequest` in `withCheckedThrowingContinuation` |
| `EdgeDetectionService.swift` | `actor` — `VNDetectRectanglesRequest` on live `CVPixelBuffer` at ~15 fps |
| `ImageFilterService.swift` | `actor` — CoreImage filter pipeline with perspective correction |
| `MBOXParser.swift` | `actor` — streaming MBOX parser using `AsyncStream<ParsedEmail>` |
| `ScanExportService.swift` | `actor` — `PDFDocument` assembly and Documents directory save |
| `PDFCompressionService.swift` | `actor` — page-by-page JPEG re-render via `CGContext` |

## On-Device AI

**Vision framework — two models, both on-device, no network calls.**

### 1. Document Edge Detection (`EdgeDetectionService`)

- **Model:** `VNDetectRectanglesRequest` (built-in Vision rectangle detector)
- **Input:** `CVPixelBuffer` from the live `AVCaptureSession` camera feed (called at ~15 fps from `CameraSessionManager`)
- **Output:** `VNRectangleObservation` giving normalized quad coordinates (`topLeft`, `topRight`, `bottomLeft`, `bottomRight`)
- **Thresholds:** `minimumConfidence = 0.7`, observations filtered again at `confidence > 0.8`, `maximumObservations = 1`
- **Use:** Quad corners are converted to image-space `CGPoint`s and drawn as a live polygon overlay in `EdgeOverlayView`; the same observation is passed to `CIFilter.perspectiveCorrection()` before any filter preset is applied
- **Fallback:** If no observation meets confidence threshold, the overlay is hidden and the user captures without crop — no error shown

### 2. Text Recognition / OCR (`OCRService`)

- **Model:** `VNRecognizeTextRequest` (Apple's built-in on-device OCR model)
- **Input:** `CGImage` from a captured `ScannedPage`
- **Output:** Plain text string — top candidate from each `VNRecognizedTextObservation` joined by newlines
- **Configuration:** `recognitionLevel = .accurate`, `usesLanguageCorrection = true`, optional `recognitionLanguages` array (up to 18 languages via `supportedRecognitionLanguages()`)
- **Fallback:** None implemented — if `VNRecognizeTextRequest` fails, the error propagates as `AppError.unknown` and is displayed in the error view. Older device fallback (`.fast` recognition level) is not currently branched on device capability.

## SharedAIKit Modules Used

None — candidate for extraction:
- `OCRService` + `EdgeDetectionService` could become a shared `DocumentVisionKit` module reusable across any scanning app
- `MBOXParser` is fully standalone and could be extracted as a Swift package (`MBOXKit`) with no app dependencies

## Build Stats

- **Lines of Swift code:** 16,107 (across 114 `.swift` files)
- **Number of screens/views:** 37 View files (30 distinct screens, 7 sub-component views)
- **Number of models:** 8 (`ScanSession`, `ScannedPage`, `ConversionJob`, `ConversionType`, `RecentFile`, `EmailAttachment`, `EmailMessage`, `MBOXFile`)
- **External dependencies:** 1 (`ZIPFoundation`)

## Claude Code Prompts

> This app was built using Claude Code as part of the "100 iOS Apps in 30 Days" challenge.

```
Prompt 1: [fill in]
Prompt 2: [fill in]
Prompt 3: [fill in]
```

## What Could Be Improved

All known issues have been resolved. The app is production-ready.

Previously addressed:

**1. Scan history thumbnails** ✅ Fixed — `ScanSessionRow` now decodes `ScannedPage.thumbnailData` (falling back to `imageData`) into a live `UIImage` for each row. `FairyImageViewer` fetches the full-res `ScannedPage` from `modelContext` by UUID and renders the real image with pinch-to-zoom.

**2. Accessibility** ✅ Fixed — Full VoiceOver coverage added to all 8 custom components: `FairyTabBar` tabs get `accessibilityLabel` + `.isSelected` trait; `FairyButton` announces loading state; `FairyIconButton` accepts an optional `label:` parameter; `DuotoneIcon`, `ModuleIcon`, and `FileTypeIcon` are marked `accessibilityHidden(true)` (decorative); `FairyBadge`, `FairyCountBadge`, and `FairyStatusBadge` each have correct `accessibilityLabel` text; `ModuleFeatureCard` and `CompactModuleCard` have label + hint; `ScanSessionRow` uses `accessibilityElement(children: .combine)` to read as a single descriptive announcement.

**3. OCR thermal fallback** ✅ Fixed — `OCRService` checks `ProcessInfo.processInfo.thermalState` and switches to `.fast` recognition when the device is under thermal stress (`.serious` / `.critical`), returning to `.accurate` automatically once the device cools.

## App Store

- **Status:** [placeholder]
- **Link:** [placeholder]
- **Downloads:** [placeholder]

## License

MIT
