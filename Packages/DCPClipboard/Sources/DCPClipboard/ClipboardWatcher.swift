import Foundation
import os

private let logger = Logger(subsystem: "com.keaganr.DoubleCopyPaste", category: "ClipboardWatcher")

/// Watches the system pasteboard for changes.
///
/// There is no OS push notification for "clipboard changed," so this polls
/// `NSPasteboard.changeCount` on a timer while running — the same approach
/// `simple-window-snap` uses to poll `AXIsProcessTrusted()`, for the same
/// reason (no push notification exists for that either).
///
/// Phase 1: log-only, no history capture yet — that lands in Phase 2 once
/// `DCPModel.ClipboardEntry` exists to capture into.
@MainActor
public final class ClipboardWatcher {
    private let pasteboard: PasteboardProviding
    private let pollInterval: TimeInterval
    private var lastSeenChangeCount: Int

    // `nonisolated(unsafe)` because `deinit` is always nonisolated even on a
    // @MainActor class; only ever touched on the main actor otherwise.
    private nonisolated(unsafe) var pollTimer: Timer?

    /// Fired after a detected pasteboard change is logged. Phase 2 hooks this
    /// to capture a `ClipboardEntry` into the history store; tests use it to
    /// verify change detection without depending on log output.
    public var onChangeDetected: ((_ changeCount: Int, _ types: [String]) -> Void)?

    public init(pasteboard: PasteboardProviding = SystemPasteboard.shared, pollInterval: TimeInterval = 0.5) {
        self.pasteboard = pasteboard
        self.pollInterval = pollInterval
        self.lastSeenChangeCount = pasteboard.changeCount
    }

    deinit {
        pollTimer?.invalidate()
    }

    public func start() {
        guard pollTimer == nil else { return }
        pollTimer = Timer.scheduledTimer(withTimeInterval: pollInterval, repeats: true) { [weak self] _ in
            Task { @MainActor in
                self?.poll()
            }
        }
    }

    public func stop() {
        pollTimer?.invalidate()
        pollTimer = nil
    }

    /// Exposed at `internal` (not `private`) so tests can drive it directly
    /// via `@testable import`, rather than depending on `Timer` firing.
    func poll() {
        let count = pasteboard.changeCount
        guard count != lastSeenChangeCount else { return }
        lastSeenChangeCount = count

        let types = pasteboard.types()
        logger.debug("Clipboard changed: changeCount=\(count, privacy: .public) types=\(types.joined(separator: ", "), privacy: .public)")
        onChangeDetected?(count, types)
    }
}
