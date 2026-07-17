import AppKit
import DCPClipboard
import DCPModel
import SwiftUI

/// The contents of the menu bar dropdown: recent clipboard history
/// (newest first), each entry a button that rolls the pasteboard back to
/// that entry's content, plus a Clear History action and Quit.
public struct MenuBarContentView: View {
    @ObservedObject private var historyStore: ClipboardHistoryStore
    @StateObject private var launchAtLoginManager = LaunchAtLoginManager()
    private let clipboardWatcher: ClipboardWatcher

    @StateObject private var clock = TickingClock()

    public init(historyStore: ClipboardHistoryStore, clipboardWatcher: ClipboardWatcher) {
        self.historyStore = historyStore
        self.clipboardWatcher = clipboardWatcher
    }

    public var body: some View {
        if historyStore.entries.isEmpty {
            Text("No clipboard history yet")
        } else {
            Text("Previous clipboard entries (click to copy):")
                .font(.caption)
                .foregroundStyle(.secondary)
                .disabled(true)

            ForEach(historyStore.entries) { entry in
                Button {
                    clipboardWatcher.restore(entry)
                } label: {
                    Self.timestampText(for: entry, now: clock.now) + Text(" ") + Text(Self.preview(for: entry))
                }
            }

            Divider()

            Button("Clear History") {
                historyStore.clear()
            }
        }

        Divider()

        Toggle(
            "Launch at Login",
            isOn: Binding(
                get: { launchAtLoginManager.isEnabled },
                set: { launchAtLoginManager.setEnabled($0) }
            )
        )

        Divider()

        Button("Quit Double Copy Paste") {
            NSApplication.shared.terminate(nil)
        }
        .keyboardShortcut("q")
    }

    /// Collapses to a single line and truncates so long copies don't blow
    /// out the width of the dropdown. Exposed at `internal` (not `private`)
    /// so tests can drive it directly via `@testable import`.
    static func preview(for entry: ClipboardEntry) -> String {
        let singleLine = entry.previewText.replacingOccurrences(of: "\n", with: " ")
        guard singleLine.count > 60 else { return singleLine }
        return String(singleLine.prefix(60)) + "…"
    }

    /// Styled, italicized/secondary-colored `Text` for an entry's relative
    /// timestamp, meant to be prepended to the preview text so the two read
    /// as visually distinct parts of the same menu item title.
    static func timestampText(for entry: ClipboardEntry, now: Date = Date()) -> Text {
        Text(relativeTimeString(for: entry.capturedAt, relativeTo: now))
            .italic()
            .foregroundColor(.secondary)
    }

    /// "10 seconds ago" / "3 minutes ago" while `date` falls on the same
    /// calendar day as `now`; "Yesterday" for the previous calendar day;
    /// an absolute medium-style date beyond that (`RelativeDateTimeFormatter`
    /// only speaks in elapsed units, so it can't produce "Yesterday" itself).
    static func relativeTimeString(for date: Date, relativeTo now: Date) -> String {
        guard Calendar.current.isDateInToday(date) else {
            let dateFormatter = DateFormatter()
            dateFormatter.doesRelativeDateFormatting = true
            dateFormatter.dateStyle = .medium
            dateFormatter.timeStyle = .none
            return dateFormatter.string(from: date)
        }

        // Below 1 second, `RelativeDateTimeFormatter` rounds to 0 and reads
        // that as *future* tense ("In 0 seconds") rather than "ago" — also
        // covers `date` landing a hair after `now` from clock-read skew
        // between capture time and render time.
        guard now.timeIntervalSince(date) >= 1 else { return "Just now" }

        let formatter = RelativeDateTimeFormatter()
        formatter.formattingContext = .beginningOfSentence
        formatter.unitsStyle = .full
        return formatter.localizedString(for: date, relativeTo: now)
    }
}
