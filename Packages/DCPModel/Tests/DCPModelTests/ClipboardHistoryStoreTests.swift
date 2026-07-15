import XCTest
@testable import DCPModel

@MainActor
final class ClipboardHistoryStoreTests: XCTestCase {
    private func makeEntry(_ text: String) -> ClipboardEntry {
        ClipboardEntry(previewText: text, representations: [
            PasteboardRepresentation(type: PasteboardType.plainText, data: Data(text.utf8)),
        ])
    }

    func testAddPrependsNewestFirst() {
        let store = ClipboardHistoryStore()
        store.add(makeEntry("first"))
        store.add(makeEntry("second"))

        XCTAssertEqual(store.entries.map(\.previewText), ["second", "first"])
    }

    func testAddSkipsExactRepeatOfMostRecentEntry() {
        let store = ClipboardHistoryStore()
        store.add(makeEntry("same"))
        store.add(makeEntry("same"))

        XCTAssertEqual(store.entries.count, 1)
    }

    func testAddAllowsRepeatIfNotImmediatelyPreceding() {
        let store = ClipboardHistoryStore()
        store.add(makeEntry("a"))
        store.add(makeEntry("b"))
        store.add(makeEntry("a"))

        XCTAssertEqual(store.entries.map(\.previewText), ["a", "b", "a"])
    }

    func testAddDropsOldestEntryPastCap() {
        let store = ClipboardHistoryStore(maxEntries: 2)
        store.add(makeEntry("a"))
        store.add(makeEntry("b"))
        store.add(makeEntry("c"))

        XCTAssertEqual(store.entries.map(\.previewText), ["c", "b"])
    }

    func testClearRemovesAllEntries() {
        let store = ClipboardHistoryStore()
        store.add(makeEntry("a"))
        store.clear()

        XCTAssertTrue(store.entries.isEmpty)
    }
}
