import DCPModel
import Foundation
import os

private let logger = Logger(subsystem: "com.keaganr.DoubleCopyPaste", category: "ClipboardWatcher")

/// Watches the system pasteboard for changes.
///
/// There is no OS push notification for "clipboard changed," so this polls
/// `NSPasteboard.changeCount` on a timer while running — the same approach
/// `simple-window-snap` uses to poll `AXIsProcessTrusted()`, for the same
/// reason (no push notification exists for that either).
@MainActor
public final class ClipboardWatcher {
    private let pasteboard: PasteboardProviding
    private let pollInterval: TimeInterval
    private var lastSeenChangeCount: Int

    // `nonisolated(unsafe)` because `deinit` is always nonisolated even on a
    // @MainActor class; only ever touched on the main actor otherwise.
    private nonisolated(unsafe) var pollTimer: Timer?

    /// Fired when a detected pasteboard change yields a capturable entry
    /// (i.e. `ClipboardEntry.capture` didn't return `nil`). Tests drive
    /// `poll()` directly and observe this instead of depending on log output.
    public var onEntryCaptured: ((ClipboardEntry) -> Void)?

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

    /// Writes `entry` back onto the pasteboard, overwriting whatever is
    /// currently there — the "rollback" action.
    ///
    /// Writing to the pasteboard bumps `changeCount` again, same as any
    /// other copy. Without the `lastSeenChangeCount` update below, the next
    /// `poll()` would see that as a brand-new external change and re-capture
    /// this restore as a duplicate history entry — the single most common
    /// bug source in a tool like this. Updating it here, before the next
    /// poll can observe the new count, closes that loop.
    public func restore(_ entry: ClipboardEntry) {
        pasteboard.clearContents()
        for representation in entry.representations {
            pasteboard.setData(representation.data, forType: representation.type)
        }
        lastSeenChangeCount = pasteboard.changeCount
    }

    /// Exposed at `internal` (not `private`) so tests can drive it directly
    /// via `@testable import`, rather than depending on `Timer` firing.
    func poll() {
        let count = pasteboard.changeCount
        guard count != lastSeenChangeCount else { return }
        lastSeenChangeCount = count

        let types = pasteboard.types()
        if PasteboardType.isExcluded(types: types) {
            logger.debug("Clipboard changed but marked concealed/transient — not captured: changeCount=\(count, privacy: .public)")
            return
        }
        guard let entry = ClipboardEntry.capture(types: types, dataProvider: pasteboard.data(forType:)) else {
            logger.debug("Clipboard changed but no supported representation found: changeCount=\(count, privacy: .public) types=\(types.joined(separator: ", "), privacy: .public)")
            return
        }

        logger.debug("Captured clipboard entry: changeCount=\(count, privacy: .public) preview=\(entry.previewText, privacy: .private)")
        onEntryCaptured?(entry)
    }
}
