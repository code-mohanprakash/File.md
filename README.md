<div align="center">

# FileFairy

**A professional, open-source iOS document toolkit — built entirely in SwiftUI.**

Scan documents with OCR · Browse MBOX email archives · Convert and compress files · Smart file browser

[![Swift](https://img.shields.io/badge/Swift-5.10-orange.svg)](https://swift.org)
[![iOS](https://img.shields.io/badge/iOS-17%2B-blue.svg)](https://developer.apple.com/ios/)
[![Xcode](https://img.shields.io/badge/Xcode-16%2B-blue.svg)](https://developer.apple.com/xcode/)
[![License](https://img.shields.io/badge/License-MIT-green.svg)](LICENSE)
[![SwiftUI](https://img.shields.io/badge/SwiftUI-%40Observable-purple.svg)](https://developer.apple.com/xcode/swiftui/)

</div>

---

## What is FileFairy?

FileFairy is a full-featured iOS file management app with four powerful modules:

| Module | Description | Frameworks |
|--------|-------------|------------|
| **Document Scanner** | Camera scanning with real-time edge detection, image filters, and Vision OCR | AVFoundation · Vision · VisionKit · PDFKit |
| **MBOX Viewer** | Parse and browse `.mbox` email archives with full attachment extraction | WebKit · UniformTypeIdentifiers |
| **File Converter** | Merge, split, and compress PDFs · convert images · extract ZIPs · view JSON/CSV | PDFKit · ZIPFoundation |
| **File Browser** | Open any file from Files app with QuickLook and recent history | SwiftData · QuickLook |

FileFairy is **100% free** with no subscriptions, no ads, and no tracking.

---

## Screenshots

> _Add your screenshots here — drag images into this section on GitHub._

---

## Features

### Document Scanner
- Live camera preview with `AVCaptureSession`
- Real-time edge/corner detection overlay
- 5 image filter presets (B&W, sepia, vivid, enhanced, original)
- On-device OCR via Apple's `Vision` framework — zero cloud calls
- Export scans as PDF or JPEG bundle
- Full scan history with SwiftData persistence

### MBOX Email Viewer
- Stream-parse arbitrarily large `.mbox` files without loading into memory
- Full RFC-compliant email header/body rendering in `WKWebView`
- Extract and preview all attachment types
- Filter by sender, date, and attachment presence
- Thread-safe actor-isolated parsing

### File Converter
- **PDF Merge** — combine multiple PDFs into one
- **PDF Split** — extract individual pages or page ranges
- **PDF Compress** — reduce file size while preserving quality
- **Image Convert** — PNG ↔ JPEG ↔ HEIF/HEIC · custom quality and DPI
- **Image Resize** — scale with aspect-ratio lock
- **ZIP Extract** — browse and extract ZIP archives
- **CSV Viewer** — scrollable table view for spreadsheets
- **JSON Viewer** — pretty-printed with syntax-style monospaced display

### File Browser
- "Open in FileFairy" from any app via `LSSupportsOpeningDocumentsInPlace`
- Security-scoped bookmark management
- Recent files with icon, size, and date via `SwiftData`
- QuickLook preview for any system-supported format

---

## Architecture

FileFairy uses a modern, production-grade Swift architecture with zero third-party UI dependencies.

### Technology Stack

```
Language:      Swift 5.10 (strict concurrency)
UI:            SwiftUI — 100%, no UIKit views except UIViewRepresentable wrappers
Persistence:   SwiftData (@Model, @Query, externalStorage for binaries)
Concurrency:   Swift actors + async/await — no Combine, no callbacks
Navigation:    NavigationStack per tab + centralized AppRouter
DI:            AppEnvironment @Observable container via SwiftUI @Environment
Camera:        AVFoundation (AVCaptureSession, AVCaptureVideoPreviewLayer)
OCR:           Vision framework (VNRecognizeTextRequest)
PDF:           PDFKit (PDFDocument, PDFPage)
Email:         Custom RFC-compliant MBOX parser (no dependencies)
ZIP:           ZIPFoundation 0.9.19
```

### MVVM + @Observable

```
View  ─────────────►  ViewModel (@Observable)  ──────►  Service (actor)
 │                          │                              │
 │  reads @Observable        │  calls async throws          │  isolated, thread-safe
 │  properties              │  stores result               │  no shared mutable state
 └──────────────────────────┘──────────────────────────────┘
```

- **Views** are pure rendering — no business logic
- **ViewModels** are `@Observable` classes — no `@Published`, no `ObservableObject`
- **Services** are Swift `actor`s — all heavy work is thread-isolated
- **AppEnvironment** is the single DI root, injected via `.environment(\.appEnvironment, ...)`

---

## Project Structure

```
FileFairy/
│
├── FileFairyApp.swift          # @main entry point, DI setup, splash → onboarding → tabs
├── RootTabView.swift           # Tab container, global sheet routing
├── FairyTabBar.swift           # Custom glassmorphic tab bar
│
├── Core/
│   ├── DesignSystem/
│   │   ├── ColorPalette.swift  # All Color.Fairy.* tokens + ModuleTheme gradients
│   │   ├── Typography.swift    # .fairyText() modifier with semantic scale
│   │   ├── Spacing.swift       # Spacing.xs/sm/md/lg/xl — 4pt base unit
│   │   ├── CornerRadius.swift  # .fairySmall/.fairyMedium/.fairyLarge/.fairyPill
│   │   ├── Animation+Fairy.swift # .fairyBounce/.fairySnappy/.fairyMagic etc.
│   │   ├── Shadows.swift       # .fairyShadow() modifier — soft/medium/firm
│   │   ├── Haptics.swift       # HapticEngine.shared — light/medium/heavy/success
│   │   └── SoundEffect.swift   # SoundPlayer.shared — tab switch, done, etc.
│   │
│   ├── Components/             # 14 reusable UI components
│   │   ├── FairyButton.swift   # Primary/secondary/ghost/destructive variants
│   │   ├── FairyCard.swift     # Surface card with shadow and tap feedback
│   │   ├── FairySearchBar.swift
│   │   ├── FairyTextField.swift
│   │   ├── FairyToast.swift    # Queued, animated toast system
│   │   ├── FairyProgressView.swift # Ring, bar, and card progress variants
│   │   ├── FairyEmptyState.swift
│   │   ├── FairyErrorView.swift
│   │   ├── FairyLoadingOverlay.swift
│   │   ├── FairySheet.swift    # Styled bottom sheet wrapper
│   │   ├── FairyBadge.swift
│   │   ├── DuotoneIcon.swift   # Two-tone SF Symbol icon with module color
│   │   ├── ModuleCard.swift    # Feature module entry card
│   │   └── MascotView.swift    # Animated fairy mascot
│   │
│   ├── Navigation/
│   │   ├── AppRouter.swift     # Centralized NavigationPath + sheet/fullscreen routing
│   │   ├── TabDestination.swift # NavigationDestination + SheetDestination enums
│   │   └── DeepLinkHandler.swift # URL scheme deep link parsing
│   │
│   ├── Persistence/
│   │   ├── AppSchema.swift     # SwiftData @Model types: ScanSession, MBOXFile, RecentFile
│   │   └── ModelContainer+App.swift # ModelContainer factory
│   │
│   ├── DependencyInjection/
│   │   ├── AppEnvironment.swift # @Observable DI container for all services
│   │   └── EnvironmentKeys.swift # SwiftUI EnvironmentKey declarations
│   │
│   ├── Errors/
│   │   ├── AppError.swift      # 11-case typed error enum with user descriptions
│   │   └── ErrorHandler.swift  # @MainActor error logger + UI state bridge
│   │
│   ├── Extensions/
│   │   ├── View+FairyModifiers.swift # .fairyText(), .fairyShadow(), .fairyCard()
│   │   ├── Data+Formatting.swift     # Human-readable file sizes
│   │   ├── Date+Display.swift        # Relative and formatted date strings
│   │   └── URL+FileHelpers.swift     # Extension, icon, security scope helpers
│   │
│   └── Utilities/
│       ├── FileImporter.swift  # .fileImporter wrapper with UTType helpers
│       ├── ShareSheet.swift    # UIActivityViewController representable
│       └── TempDirectory.swift # Temp file lifecycle management
│
└── Features/
    │
    ├── Home/
    │   ├── HomeView.swift          # Dashboard with greeting + quick actions + recents
    │   ├── GreetingHeader.swift    # Time-of-day greeting with mascot
    │   └── RecentFilesRow.swift    # Horizontal recent files scroll
    │
    ├── Scanner/
    │   ├── Models/
    │   │   ├── ScannedPage.swift   # @Model: image data, filter, ocrText
    │   │   └── ScanSession.swift   # @Model: collection of pages with title/date
    │   ├── Services/
    │   │   ├── CameraSessionManager.swift  # actor: AVCaptureSession lifecycle
    │   │   ├── EdgeDetectionService.swift  # actor: VNDetectRectanglesRequest
    │   │   ├── ImageFilterService.swift    # actor: CIFilter pipeline
    │   │   ├── OCRService.swift            # actor: VNRecognizeTextRequest
    │   │   └── ScanExportService.swift     # actor: PDF/JPEG export + Documents save
    │   ├── ViewModels/
    │   │   ├── ScannerViewModel.swift      # @Observable: scan session state
    │   │   └── ScanHistoryViewModel.swift  # @Observable: SwiftData scan history
    │   └── Views/
    │       ├── ScannerRootView.swift       # Entry: history + new scan button
    │       ├── ScannerCameraView.swift     # Full-screen camera capture
    │       ├── CameraPreviewView.swift     # UIViewRepresentable AVPreviewLayer
    │       ├── EdgeOverlayView.swift       # Real-time polygon overlay
    │       ├── ScanCaptureControlsView.swift
    │       ├── ScanReviewView.swift        # Post-capture: filter, rotate, OCR, export
    │       ├── FilterPickerView.swift
    │       ├── ScanExportSheet.swift
    │       ├── ScanHistoryView.swift
    │       ├── OCRResultView.swift         # Copyable OCR text display
    │       └── ...
    │
    ├── MBOXViewer/
    │   ├── Models/
    │   │   ├── MBOXFile.swift      # @Model: parsed mailbox metadata
    │   │   ├── EmailMessage.swift  # Struct: headers, body, attachments
    │   │   └── EmailAttachment.swift
    │   ├── Services/
    │   │   ├── MBOXParser.swift         # actor: stream-parse RFC 4155 MBOX files
    │   │   ├── EmailBodyRenderer.swift  # actor: HTML/text body rendering pipeline
    │   │   └── AttachmentExtractor.swift # actor: MIME base64 attachment decode
    │   ├── ViewModels/
    │   │   ├── MBOXLibraryViewModel.swift
    │   │   ├── EmailListViewModel.swift
    │   │   └── EmailDetailViewModel.swift
    │   └── Views/
    │       ├── MBOXRootView.swift
    │       ├── MBOXLibraryView.swift
    │       ├── EmailListView.swift
    │       ├── EmailRowView.swift
    │       ├── EmailDetailView.swift
    │       ├── EmailFilterSheet.swift
    │       ├── AttachmentRowView.swift
    │       ├── MBOXImportProgressView.swift
    │       └── WebViewWrapper.swift    # WKWebView for HTML email bodies
    │
    ├── Converter/
    │   ├── Models/
    │   │   ├── ConversionJob.swift  # @Observable job with progress + state
    │   │   └── ConversionType.swift # Enum of all 9 conversion operations
    │   ├── Services/
    │   │   ├── PDFMergeService.swift
    │   │   ├── PDFSplitService.swift
    │   │   ├── PDFCompressionService.swift
    │   │   ├── ImageConversionService.swift
    │   │   ├── ImageResizeService.swift
    │   │   ├── ZIPService.swift
    │   │   └── TextViewerService.swift  # CSV + JSON parsing for viewer views
    │   ├── ViewModels/
    │   │   ├── ConverterHubViewModel.swift
    │   │   └── ConversionJobViewModel.swift
    │   └── Views/
    │       ├── ConverterRootView.swift
    │       ├── ConverterHubView.swift
    │       ├── PDFMergeView.swift
    │       ├── PDFSplitView.swift
    │       ├── PDFCompressView.swift
    │       ├── ImageConverterView.swift
    │       ├── ConversionProgressView.swift
    │       ├── ConversionResultView.swift
    │       ├── JSONViewerView.swift
    │       └── CSVViewerView.swift
    │
    ├── FileOpener/
    │   ├── Models/RecentFile.swift          # @Model: URL + metadata cache
    │   ├── Services/FileTypeResolver.swift  # UTType → icon/label mapping
    │   ├── ViewModels/FileOpenerViewModel.swift
    │   └── Views/
    │       ├── FileOpenerRootView.swift
    │       └── FileOpenerLandingView.swift
    │
    ├── Onboarding/
    │   ├── SplashView.swift       # Animated launch splash
    │   └── OnboardingView.swift   # 5-page feature introduction flow
    │
    ├── Settings/
    │   └── SettingsView.swift
    │
    └── Premium/                   # StoreKit scaffold (all features free)
        ├── Services/StoreKitService.swift
        ├── ViewModels/PremiumViewModel.swift
        └── Views/
            ├── PaywallView.swift
            └── SubscriptionCard.swift
```

---

## Design System

FileFairy ships a complete, token-based design system under the `Color.Fairy.*` namespace.

### Color Palette — "Moonlight Magic"

The palette uses a **barely-perceptible lavender background** that gives the app a cohesive magical feel without being garish. Module accent colors are deep and sophisticated, not neon.

```swift
// Background
Color.Fairy.dust          // #F7F6FF — whisper lavender (the "magic" tint)

// Primary Brand
Color.Fairy.violet        // #6D28D9 — deep violet
Color.Fairy.lavenderMist  // #CCBFF9 — soft amethyst for pressed/hover

// Module Accents
Color.Fairy.rose          // #BE185D — Scanner: deep rose
Color.Fairy.teal          // #0E7490 — MBOX: deep cerulean
Color.Fairy.amber         // #B45309 — Converter: old gold
Color.Fairy.green         // #047857 — PDF: forest green
Color.Fairy.indigo        // #4338CA — Files: midnight indigo

// Text
Color.Fairy.ink           // #1A1628 — plum-black headlines (harmonizes with violet)
Color.Fairy.slate         // #6B7280 — secondary text
Color.Fairy.mist          // #A1A1AA — disabled / placeholder

// Surfaces
Color.Fairy.cream         // #FFFFFF — card backgrounds (pop against lavender bg)
Color.Fairy.softEdge      // #E5E3F1 — lavender-tinted separators

// Semantic States
Color.Fairy.mint          // #22C587 — success
Color.Fairy.coral         // #F98833 — warning
Color.Fairy.softRed       // #F15E5E — error (warm, not harsh)
```

### Spacing — 4pt Base Grid

```swift
Spacing.xxxs  //  2pt
Spacing.xxs   //  4pt
Spacing.xs    //  8pt
Spacing.sm    // 12pt
Spacing.md    // 16pt  ← most common padding
Spacing.lg    // 24pt
Spacing.xl    // 32pt
Spacing.xxl   // 48pt
Spacing.xxxl  // 64pt
```

### Typography

Applied via `.fairyText(.headline)` — semantic, not literal:

```swift
.micro        // 10pt — labels, tags
.caption      // 12pt — metadata, timestamps
.body         // 15pt — general content
.headline     // 17pt semibold — section headers
.title2       // 22pt bold — screen titles
.title1       // 28pt bold — hero text
```

### Corner Radius

```swift
.fairySmall   //  8pt
.fairyMedium  // 12pt
.fairyLarge   // 16pt
.fairyXL      // 24pt
.fairyPill    // 999pt — fully rounded
```

### Animations

```swift
.fairyBounce      // spring(0.5, 0.6) — satisfying bouncy
.fairySnappy      // spring(0.35, 0.8) — quick and crisp
.fairyGentle      // easeInOut(0.4) — smooth transitions
.fairyMagic       // spring(0.6, 0.7) — hero entrances
.fairyCelebrate   // spring(0.8, 0.4) — completion moments
```

### Reusable Components

All components live in `Core/Components/` and are documented with `#Preview` macros.

| Component | Usage |
|-----------|-------|
| `FairyButton` | `FairyButton("Label", style: .primary) { }` |
| `FairyCard` | Surface container with shadow |
| `FairySearchBar` | `FairySearchBar("Placeholder", text: $binding)` |
| `FairyToast` | `.withToastQueue(queue)` modifier on any view |
| `FairyProgressView` | Ring, linear, or card with cancel action |
| `FairyEmptyState` | `FairyEmptyState(config: .noFiles) { }` |
| `FairyErrorView` | `FairyErrorView(title:, message:, onRetry:)` |
| `DuotoneIcon` | `DuotoneIcon("scanner", color: .Fairy.rose)` |
| `FairyBadge` | `FairyBadge("New")` |

---

## Getting Started

### Requirements

- **Xcode 16+**
- **iOS 17+** (device or simulator)
- **macOS 14+** (Sonoma) to build

### Clone and Build

```bash
git clone https://github.com/code-mohanprakash/File.md.git
cd File.md
open FileFairy.xcodeproj
```

Then in Xcode:
1. Select the `FileFairy` scheme
2. Choose your simulator or device
3. Press `Cmd+R` to build and run

> **Note**: The project uses [XcodeGen](https://github.com/yonaskolb/XcodeGen). If you need to regenerate the `.xcodeproj`:
> ```bash
> brew install xcodegen
> xcodegen generate
> ```

### Dependencies

FileFairy has **one** external Swift Package dependency:

| Package | Version | Purpose |
|---------|---------|---------|
| [ZIPFoundation](https://github.com/weichsel/ZIPFoundation) | ≥ 0.9.19 | ZIP archive extraction |

All other functionality uses Apple system frameworks only.

---

## Navigation Architecture

FileFairy uses a centralized `AppRouter` — no ad-hoc `@State var showSheet` scattered across views.

```
AppRouter (@Observable)
    ├── scannerPath:    NavigationPath
    ├── mboxPath:       NavigationPath
    ├── converterPath:  NavigationPath
    ├── fileOpenerPath: NavigationPath
    │
    ├── activeSheet:    SheetDestination?    ← covers ALL sheets app-wide
    └── activeFullscreen: FullscreenDestination?

// Navigate from anywhere:
router.navigate(to: .emailDetail(message))  // push
router.present(.ocrText(text: extractedText)) // sheet
router.dismiss()                             // back
```

`TabDestination` (push) and `SheetDestination` (sheet) are exhaustive enums — the compiler enforces every route is handled.

---

## Error Handling

All errors flow through a typed `AppError` enum with 11 cases:

```swift
enum AppError: LocalizedError {
    case fileNotFound(String)
    case permissionDenied
    case diskFull
    case corruptFile(String)
    case unsupportedFormat(String)
    case conversionFailed(String)
    case parsingError(String)
    case cameraUnavailable
    case purchaseFailed(String)
    case unknown(Error)
}
```

Every case has a `errorDescription`, `alertTitle`, and `recoverySuggestion` — errors are always surfaced with clear, user-friendly language.

The `@MainActor` `ErrorHandler` singleton bridges service errors to observable UI state, with structured logging.

---

## Concurrency Model

| Layer | Isolation | Why |
|-------|-----------|-----|
| Services | `actor` | All heavy I/O is thread-isolated, no data races |
| ViewModels | `@MainActor` | All UI state updates on main thread |
| Views | `@MainActor` (implicit) | SwiftUI requirement |
| Callbacks across boundaries | `@Sendable` | Prevents capture of mutable state |

Swift strict concurrency is enabled (`SWIFT_STRICT_CONCURRENCY = complete`) — the codebase compiles with zero data race warnings.

---

## Persistence

SwiftData is used for all persistence — no Core Data, no SQLite boilerplate.

```
ScanSession  (@Model)
  └── [ScannedPage]  (@Model, imageData @Attribute(.externalStorage))

MBOXFile  (@Model)
  └── metadata, path, message count

RecentFile  (@Model)
  └── url, filename, fileSize, lastOpened, fileExtension
```

Binary data (`UIImage` representations) uses `@Attribute(.externalStorage)` so SwiftData stores references to files rather than BLOBs in the SQLite store — keeping the database fast and lightweight.

---

## Contributing

Contributions are welcome. Please follow these guidelines:

1. **Fork** the repository and create a feature branch from `main`
2. **Match the architecture** — new features go in `Features/<FeatureName>/` with Models / Services / ViewModels / Views subfolders
3. **Use design system tokens** — never hardcode colors, spacing, or corner radii
4. **Actor-isolate all services** — no `DispatchQueue.main.async` in services
5. **No force unwraps** in production paths — use `guard let` or `throw`
6. **Add `#Preview` macros** to all new views
7. Open a pull request with a clear description of the change

### Good First Issues

- Add accessibility labels to custom components (`accessibilityLabel`, `accessibilityHint`)
- Add `Localizable.strings` for English baseline (enabling future localization)
- Write `XCTest` unit tests for the MBOX parser and file conversion services
- Add a Settings screen with app version, feedback link, and clear-cache option

---

## License

MIT License — free to use, modify, and distribute.

```
MIT License

Copyright (c) 2024 FileFairy Contributors

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.
```

---

<div align="center">
Built with Swift · SwiftUI · SwiftData · AVFoundation · Vision · PDFKit
</div>
