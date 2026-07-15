import Combine
import Foundation

/// In-memory clipboard history, capped at `maxEntries` — no disk
/// persistence by design (see implementation-plan.md), so history resets
/// on quit/restart.
@MainActor
public final class ClipboardHistoryStore: ObservableObject {
    @Published public private(set) var entries: [ClipboardEntry] = []

    private let maxEntries: Int

    public init(maxEntries: Int = 50) {
        self.maxEntries = maxEntries
    }

    /// Prepends `entry`, skipping it if it's an exact repeat of the current
    /// most-recent entry (avoids a duplicate row when the same thing is
    /// copied twice in a row). Drops the oldest entry once over `maxEntries`.
    public func add(_ entry: ClipboardEntry) {
        if entries.first?.representations == entry.representations {
            return
        }
        entries.insert(entry, at: 0)
        if entries.count > maxEntries {
            entries.removeLast(entries.count - maxEntries)
        }
    }

    public func clear() {
        entries.removeAll()
    }
}
