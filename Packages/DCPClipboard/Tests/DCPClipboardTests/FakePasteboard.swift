import Foundation
@testable import DCPClipboard

@MainActor
final class FakePasteboard: PasteboardProviding {
    private(set) var changeCount = 0
    private var storage: [String: Data] = [:]

    func types() -> [String] {
        Array(storage.keys)
    }

    func data(forType type: String) -> Data? {
        storage[type]
    }

    func setData(_ data: Data, forType type: String) {
        storage[type] = data
        changeCount += 1
    }

    func clearContents() {
        storage.removeAll()
        changeCount += 1
    }
}
