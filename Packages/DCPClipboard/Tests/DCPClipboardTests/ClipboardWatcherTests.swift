import XCTest
@testable import DCPClipboard

@MainActor
final class ClipboardWatcherTests: XCTestCase {
    func testPollDoesNothingWhenChangeCountIsUnchanged() {
        let pasteboard = FakePasteboard()
        let watcher = ClipboardWatcher(pasteboard: pasteboard)
        var detections: [(Int, [String])] = []
        watcher.onChangeDetected = { detections.append(($0, $1)) }

        watcher.poll()

        XCTAssertTrue(detections.isEmpty)
    }

    func testPollFiresOnceWhenChangeCountAdvances() {
        let pasteboard = FakePasteboard()
        let watcher = ClipboardWatcher(pasteboard: pasteboard)
        var detections: [(Int, [String])] = []
        watcher.onChangeDetected = { detections.append(($0, $1)) }

        pasteboard.setData(Data("hello".utf8), forType: "public.utf8-plain-text")
        watcher.poll()
        watcher.poll()

        XCTAssertEqual(detections.count, 1)
        XCTAssertEqual(detections.first?.0, pasteboard.changeCount)
        XCTAssertEqual(detections.first?.1, ["public.utf8-plain-text"])
    }

    func testPollFiresAgainOnEachSubsequentChange() {
        let pasteboard = FakePasteboard()
        let watcher = ClipboardWatcher(pasteboard: pasteboard)
        var detectionCount = 0
        watcher.onChangeDetected = { _, _ in detectionCount += 1 }

        pasteboard.setData(Data("first".utf8), forType: "public.utf8-plain-text")
        watcher.poll()
        pasteboard.setData(Data("second".utf8), forType: "public.utf8-plain-text")
        watcher.poll()

        XCTAssertEqual(detectionCount, 2)
    }
}
