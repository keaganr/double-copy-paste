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
}
