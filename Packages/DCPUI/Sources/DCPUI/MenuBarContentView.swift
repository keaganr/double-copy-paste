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

    public init(historyStore: ClipboardHistoryStore, clipboardWatcher: ClipboardWatcher) {
        self.historyStore = historyStore
        self.clipboardWatcher = clipboardWatcher
    }

    public var body: some View {
        if historyStore.entries.isEmpty {
            Text("No clipboard history yet")
        } else {
            ForEach(historyStore.entries) { entry in
                Button(Self.preview(for: entry)) {
                    clipboardWatcher.restore(entry)
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
    /// out the width of the dropdown.
    private static func preview(for entry: ClipboardEntry) -> String {
        let singleLine = entry.previewText.replacingOccurrences(of: "\n", with: " ")
        guard singleLine.count > 60 else { return singleLine }
        return String(singleLine.prefix(60)) + "…"
    }
}
