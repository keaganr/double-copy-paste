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

    func testRestoreDoesNotReCaptureItsOwnWrite() {
        let pasteboard = FakePasteboard()
        let watcher = ClipboardWatcher(pasteboard: pasteboard)
        var captured: [ClipboardEntry] = []
        watcher.onEntryCaptured = { captured.append($0) }

        let entry = ClipboardEntry(previewText: "restored", representations: [
            PasteboardRepresentation(type: PasteboardType.plainText, data: Data("restored".utf8)),
        ])
        watcher.restore(entry)
        watcher.poll()

        XCTAssertTrue(captured.isEmpty, "restore()'s own pasteboard write must not be re-captured as a new history entry")
    }

    func testRestoreWritesAllRepresentationsToPasteboard() {
        let pasteboard = FakePasteboard()
        let watcher = ClipboardWatcher(pasteboard: pasteboard)

        let entry = ClipboardEntry(previewText: "plain", representations: [
            PasteboardRepresentation(type: PasteboardType.plainText, data: Data("plain".utf8)),
            PasteboardRepresentation(type: PasteboardType.rtf, data: Data("rtf-bytes".utf8)),
        ])
        watcher.restore(entry)

        XCTAssertEqual(pasteboard.data(forType: PasteboardType.plainText), Data("plain".utf8))
        XCTAssertEqual(pasteboard.data(forType: PasteboardType.rtf), Data("rtf-bytes".utf8))
    }

    func testExternalChangeAfterRestoreIsStillCaptured() {
        let pasteboard = FakePasteboard()
        let watcher = ClipboardWatcher(pasteboard: pasteboard)
        var captured: [ClipboardEntry] = []
        watcher.onEntryCaptured = { captured.append($0) }

        let entry = ClipboardEntry(previewText: "restored", representations: [
            PasteboardRepresentation(type: PasteboardType.plainText, data: Data("restored".utf8)),
        ])
        watcher.restore(entry)
        watcher.poll()

        pasteboard.setData(Data("something new".utf8), forType: PasteboardType.plainText)
        watcher.poll()

        XCTAssertEqual(captured.map(\.previewText), ["something new"])
    }
}
