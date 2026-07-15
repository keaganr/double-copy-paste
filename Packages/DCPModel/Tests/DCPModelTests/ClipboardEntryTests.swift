import XCTest
@testable import DCPModel

final class ClipboardEntryTests: XCTestCase {
    func testCaptureReturnsNilWhenNoAllowListedTypePresent() {
        let entry = ClipboardEntry.capture(types: ["public.png"]) { _ in Data() }
        XCTAssertNil(entry)
    }

    func testCapturePrefersPlainTextForPreview() {
        let plain = Data("hello world".utf8)
        let entry = ClipboardEntry.capture(types: [PasteboardType.plainText, PasteboardType.rtf]) { type in
            type == PasteboardType.plainText ? plain : Data("rtf-bytes".utf8)
        }
        XCTAssertEqual(entry?.previewText, "hello world")
        XCTAssertEqual(entry?.representations.count, 2)
    }

    func testCaptureFallsBackToPlaceholderPreviewWhenOnlyRichTextPresent() {
        let entry = ClipboardEntry.capture(types: [PasteboardType.rtf]) { _ in Data("rtf-bytes".utf8) }
        XCTAssertEqual(entry?.previewText, "(rich text)")
    }

    func testCaptureSkipsTypesMissingData() {
        let entry = ClipboardEntry.capture(types: [PasteboardType.plainText, PasteboardType.html]) { type in
            type == PasteboardType.plainText ? Data("text".utf8) : nil
        }
        XCTAssertEqual(entry?.representations.count, 1)
        XCTAssertEqual(entry?.representations.first?.type, PasteboardType.plainText)
    }
}
