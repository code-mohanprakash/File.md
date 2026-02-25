// FairyToast.swift
// FileFairy
//
// Observable toast queue + overlay view for non-blocking feedback messages.
//
// Architecture:
//   - Toast: value type describing a single message (icon, color, duration)
//   - ToastQueue: @Observable class; holds the active toast, exposes show()
//   - ToastOverlayView: reads ToastQueue from Environment, renders the toast pill
//   - ToastEnvironmentKey / EnvironmentValues extension: injection
//   - View.toastOverlay() modifier: attaches ToastOverlayView to any root view
//
// Design spec:
//   - Pill shape, cream/cloud background, soft shadow
//   - SF Symbol icon (tinted), message text
//   - Slides up from bottom edge, auto-dismisses after duration
//   - Dismiss on tap
//   - Haptic on appear (soft)

import SwiftUI

// MARK: - Toast Model

struct Toast: Equatable, Identifiable {

    enum Style: Equatable {
        case info
        case success
        case warning
        case error
        case custom(Color)

        static func == (lhs: Style, rhs: Style) -> Bool {
            switch (lhs, rhs) {
            case (.info, .info), (.success, .success), (.warning, .warning), (.error, .error):
                return true
            case (.custom(let l), .custom(let r)):
                return l == r
            default:
                return false
            }
        }

        var color: Color {
            switch self {
            case .info:               return .Fairy.violet
            case .success:            return .Fairy.mint
            case .warning:            return .Fairy.coral
            case .error:              return .Fairy.softRed
            case .custom(let c):      return c
            }
        }

        var defaultIcon: String {
            switch self {
            case .info:    return "info.circle.fill"
            case .success: return "checkmark.circle.fill"
            case .warning: return "exclamationmark.triangle.fill"
            case .error:   return "xmark.circle.fill"
            case .custom:  return "sparkles"
            }
        }
    }

    let id: UUID
    let message: String
    let icon: String
    let style: Style
    let duration: Double   // seconds before auto-dismiss

    init(
        message: String,
        icon: String? = nil,
        style: Style = .info,
        duration: Double = 2.8
    ) {
        self.id = UUID()
        self.message = message
        self.icon = icon ?? style.defaultIcon
        self.style = style
        self.duration = duration
    }

    var color: Color { style.color }

    // MARK: Convenience factories

    static func success(_ message: String, icon: String? = nil) -> Toast {
        Toast(message: message, icon: icon, style: .success)
    }

    static func error(_ message: String, icon: String? = nil) -> Toast {
        Toast(message: message, icon: icon, style: .error, duration: 3.5)
    }

    static func warning(_ message: String, icon: String? = nil) -> Toast {
        Toast(message: message, icon: icon, style: .warning)
    }

    static func info(_ message: String, icon: String? = nil) -> Toast {
        Toast(message: message, icon: icon, style: .info)
    }
}

// MARK: - ToastQueue

@Observable
final class ToastQueue {

    private(set) var current: Toast?
    private var queue: [Toast] = []
    private var dismissTask: Task<Void, Never>?

    /// Enqueue a toast. If the queue is empty, shows immediately.
    func show(_ toast: Toast) {
        queue.append(toast)
        if current == nil {
            advance()
        }
    }

    /// Show a toast using convenience parameters.
    func show(
        _ message: String,
        icon: String? = nil,
        style: Toast.Style = .info,
        duration: Double = 2.8
    ) {
        show(Toast(message: message, icon: icon, style: style, duration: duration))
    }

    /// Dismiss the current toast immediately.
    func dismiss() {
        dismissTask?.cancel()
        withAnimation(.fairyDismiss) {
            current = nil
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.35) { [weak self] in
            self?.advance()
        }
    }

    // MARK: Private

    private func advance() {
        guard !queue.isEmpty else { return }
        let next = queue.removeFirst()
        withAnimation(.fairyMagic) {
            current = next
        }
        Task { @MainActor in HapticEngine.shared.soft() }

        // Schedule auto-dismiss
        dismissTask?.cancel()
        dismissTask = Task { @MainActor [weak self] in
            try? await Task.sleep(for: .seconds(next.duration))
            guard !Task.isCancelled else { return }
            self?.dismiss()
        }
    }
}

// MARK: - Toast Pill View

private struct ToastPill: View {

    let toast: Toast
    let onTap: () -> Void

    var body: some View {
        HStack(spacing: Spacing.xs) {
            Image(systemName: toast.icon)
                .font(.system(size: 15, weight: .semibold, design: .rounded))
                .foregroundStyle(toast.color)
                .symbolRenderingMode(.hierarchical)

            Text(toast.message)
                .font(.Fairy.subtext)
                .foregroundStyle(Color.Fairy.ink)
                .lineLimit(2)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(.horizontal, Spacing.md)
        .padding(.vertical, Spacing.sm)
        .background(
            Capsule()
                .fill(Color.Fairy.cloud)
                .fairyShadow(.float)
                .overlay(
                    Capsule()
                        .strokeBorder(toast.color.opacity(0.15), lineWidth: 1)
                )
        )
        .contentShape(Capsule())
        .onTapGesture(perform: onTap)
        .pressScale(0.97)
    }
}

// MARK: - ToastOverlayView

/// The transparent overlay that hosts and animates the active toast.
/// Attach this to the root of the view hierarchy via `.toastOverlay()`.
struct ToastOverlayView: View {

    @Environment(ToastQueue.self) private var queue

    var body: some View {
        VStack {
            Spacer()

            if let toast = queue.current {
                ToastPill(toast: toast) {
                    queue.dismiss()
                }
                .transition(.fairySlideUp)
                .padding(.bottom, Spacing.lg)
            }
        }
        .animation(.fairyMagic, value: queue.current?.id)
        .allowsHitTesting(queue.current != nil)
    }
}

// MARK: - Environment Key

private struct ToastQueueKey: EnvironmentKey {
    static let defaultValue: ToastQueue = ToastQueue()
}

extension EnvironmentValues {
    var toastQueue: ToastQueue {
        get { self[ToastQueueKey.self] }
        set { self[ToastQueueKey.self] = newValue }
    }
}

// MARK: - ViewModifier

/// Attaches a ToastQueue to the environment and renders the ToastOverlayView.
///
/// Usage — place once at the root of your scene:
/// ```swift
/// ContentView()
///     .withToastQueue(toastQueue)
/// ```
struct ToastQueueModifier: ViewModifier {

    let queue: ToastQueue

    func body(content: Content) -> some View {
        ZStack {
            content
            ToastOverlayView()
        }
        .environment(queue)
    }
}

extension View {
    /// Injects a ToastQueue into the environment and renders toast messages.
    func withToastQueue(_ queue: ToastQueue) -> some View {
        modifier(ToastQueueModifier(queue: queue))
    }
}

// MARK: - Preview

#Preview("FairyToast") {
    @Previewable @State var queue = ToastQueue()

    VStack(spacing: Spacing.md) {
        Text("Toast Demos")
            .fairyText(.title)

        FairyButton("Show Success", icon: "checkmark.circle", style: .primary) {
            queue.show(.success("File converted successfully!"))
        }

        FairyButton("Show Error", icon: "xmark.circle", style: .destructive) {
            queue.show(.error("Conversion failed. Try again."))
        }

        FairyButton("Show Warning", icon: "exclamationmark.triangle", style: .secondary) {
            queue.show(.warning("File is larger than 50 MB"))
        }

        FairyButton("Show Info", style: .ghost) {
            queue.show(.info("Tap a file to open it", icon: "hand.tap"))
        }

        FairyButton("Queue Three", style: .secondary) {
            queue.show(.info("First toast"))
            queue.show(.success("Second toast!"))
            queue.show(.warning("Third toast..."))
        }
    }
    .padding(Spacing.md)
    .frame(maxWidth: .infinity, maxHeight: .infinity)
    .background(Color.Fairy.dust)
    .withToastQueue(queue)
}
