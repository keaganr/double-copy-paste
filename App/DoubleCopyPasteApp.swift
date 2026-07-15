import DCPUI
import SwiftUI

@main
struct DoubleCopyPasteApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) private var appDelegate

    var body: some Scene {
        MenuBarExtra("Double Copy Paste", systemImage: "doc.on.clipboard") {
            MenuBarContentView(historyStore: appDelegate.historyStore, clipboardWatcher: appDelegate.clipboardWatcher)
        }
        .menuBarExtraStyle(.menu)
    }
}
