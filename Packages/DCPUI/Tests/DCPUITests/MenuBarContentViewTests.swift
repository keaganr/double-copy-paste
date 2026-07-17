import XCTest
@testable import DCPModel
@testable import DCPUI

@MainActor
final class MenuBarContentViewTests: XCTestCase {
    private func makeEntry(_ text: String) -> ClipboardEntry {
        ClipboardEntry(previewText: text, representations: [
            PasteboardRepresentation(type: PasteboardType.plainText, data: Data(text.utf8)),
        ])
    }

    func testPreviewReturnsShortTextUnchanged() {
        let entry = makeEntry("hello world")
        XCTAssertEqual(MenuBarContentView.preview(for: entry), "hello world")
    }

    func testPreviewCollapsesNewlinesToSpaces() {
        let entry = makeEntry("line one\nline two")
        XCTAssertEqual(MenuBarContentView.preview(for: entry), "line one line two")
    }

    func testPreviewTruncatesLongTextWithEllipsis() {
        let longText = String(repeating: "a", count: 100)
        let preview = MenuBarContentView.preview(for: makeEntry(longText))

        XCTAssertEqual(preview.count, 61)
        XCTAssertTrue(preview.hasSuffix("…"))
        XCTAssertEqual(String(preview.dropLast()), String(repeating: "a", count: 60))
    }

    func testPreviewDoesNotTruncateAtExactlySixtyCharacters() {
        let exactlySixty = String(repeating: "b", count: 60)
        XCTAssertEqual(MenuBarContentView.preview(for: makeEntry(exactlySixty)), exactlySixty)
    }

    func testRelativeTimeStringForJustCapturedEntry() {
        let now = Date()
        XCTAssertEqual(MenuBarContentView.relativeTimeString(for: now, relativeTo: now), "Just now")
    }

    func testRelativeTimeStringDoesNotGoFutureTenseOnClockSkew() {
        let now = Date()
        // `now` computed a hair before `date` (e.g. entry captured, then
        // `now` read a moment later but before a full second elapsed) must
        // not read as "In 0 seconds" — regression test for that bug.
        let justCaptured = now.addingTimeInterval(0.4)
        XCTAssertEqual(MenuBarContentView.relativeTimeString(for: justCaptured, relativeTo: now), "Just now")
    }

    func testRelativeTimeStringForSecondsAgo() {
        let now = Date()
        let tenSecondsAgo = now.addingTimeInterval(-10)
        XCTAssertEqual(
            MenuBarContentView.relativeTimeString(for: tenSecondsAgo, relativeTo: now),
            "10 seconds ago"
        )
    }

    func testRelativeTimeStringForMinutesAgo() {
        let now = Date()
        let threeMinutesAgo = now.addingTimeInterval(-3 * 60)
        XCTAssertEqual(
            MenuBarContentView.relativeTimeString(for: threeMinutesAgo, relativeTo: now),
            "3 minutes ago"
        )
    }

    func testRelativeTimeStringForYesterday() {
        let now = Date()
        let calendar = Calendar.current
        let yesterday = calendar.date(byAdding: .day, value: -1, to: now)!
        XCTAssertEqual(
            MenuBarContentView.relativeTimeString(for: yesterday, relativeTo: now),
            "Yesterday"
        )
    }

    func testRelativeTimeStringForOlderDatesFallsBackToAbsoluteDate() {
        let now = Date()
        let calendar = Calendar.current
        let lastWeek = calendar.date(byAdding: .day, value: -8, to: now)!

        let expectedFormatter = DateFormatter()
        expectedFormatter.doesRelativeDateFormatting = true
        expectedFormatter.dateStyle = .medium
        expectedFormatter.timeStyle = .none

        XCTAssertEqual(
            MenuBarContentView.relativeTimeString(for: lastWeek, relativeTo: now),
            expectedFormatter.string(from: lastWeek)
        )
    }
}
