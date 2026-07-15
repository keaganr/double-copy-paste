import XCTest
@testable import DCPClipboard
@testable import DCPModel

@MainActor
final class ClipboardWatcherTests: XCTestCase {
    func testPollDoesNothingWhenChangeCountIsUnchanged() {
        let pasteboard = FakePasteboard()
        let watcher = ClipboardWatcher(pasteboard: pasteboard)
        var captured: [ClipboardEntry] = []
        watcher.onEntryCaptured = { captured.append($0) }

        watcher.poll()

        XCTAssertTrue(captured.isEmpty)
    }

    func testPollCapturesEntryWhenChangeCountAdvances() {
        let pasteboard = FakePasteboard()
        let watcher = ClipboardWatcher(pasteboard: pasteboard)
        var captured: [ClipboardEntry] = []
        watcher.onEntryCaptured = { captured.append($0) }

        pasteboard.setData(Data("hello".utf8), forType: PasteboardType.plainText)
        watcher.poll()
        watcher.poll()

        XCTAssertEqual(captured.count, 1)
        XCTAssertEqual(captured.first?.previewText, "hello")
    }

    func testPollIgnoresChangesWithNoSupportedRepresentation() {
        let pasteboard = FakePasteboard()
        let watcher = ClipboardWatcher(pasteboard: pasteboard)
        var captured: [ClipboardEntry] = []
        watcher.onEntryCaptured = { captured.append($0) }

        pasteboard.setData(Data([0xFF, 0xD8]), forType: "public.png")
        watcher.poll()

        XCTAssertTrue(captured.isEmpty)
    }

    func testPollFiresAgainOnEachSubsequentChange() {
        let pasteboard = FakePasteboard()
        let watcher = ClipboardWatcher(pasteboard: pasteboard)
        var captured: [ClipboardEntry] = []
        watcher.onEntryCaptured = { captured.append($0) }

        pasteboard.setData(Data("first".utf8), forType: PasteboardType.plainText)
        watcher.poll()
        pasteboard.setData(Data("second".utf8), forType: PasteboardType.plainText)
        watcher.poll()

        XCTAssertEqual(captured.map(\.previewText), ["first", "second"])
    }
}
