import AppKit
import DCPClipboard
import DCPModel

@MainActor
final class AppDelegate: NSObject, NSApplicationDelegate {
    let clipboardWatcher = ClipboardWatcher()
    let historyStore = ClipboardHistoryStore()

    func applicationDidFinishLaunching(_ notification: Notification) {
        clipboardWatcher.onEntryCaptured = { [historyStore] entry in
            historyStore.add(entry)
        }
        clipboardWatcher.start()
    }
}
