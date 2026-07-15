import SwiftUI

@main
struct DoubleCopyPasteApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) private var appDelegate

    var body: some Scene {
        MenuBarExtra("Double Copy Paste", systemImage: "doc.on.clipboard") {
            Button("Quit Double Copy Paste") {
                NSApplication.shared.terminate(nil)
            }
            .keyboardShortcut("q")
        }
        .menuBarExtraStyle(.menu)
    }
}
