import AppKit
import DCPClipboard

@MainActor
final class AppDelegate: NSObject, NSApplicationDelegate {
    let clipboardWatcher = ClipboardWatcher()

    func applicationDidFinishLaunching(_ notification: Notification) {
        clipboardWatcher.start()
    }
}
