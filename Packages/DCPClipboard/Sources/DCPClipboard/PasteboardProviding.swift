import AppKit

/// Abstracts `NSPasteboard.general` so `ClipboardWatcher` can be unit-tested
/// against an in-memory fake instead of the real system pasteboard.
@MainActor
public protocol PasteboardProviding: AnyObject {
    var changeCount: Int { get }
    func types() -> [String]
    func data(forType type: String) -> Data?
    func setData(_ data: Data, forType type: String)
    func clearContents()
}

@MainActor
public final class SystemPasteboard: PasteboardProviding {
    public static let shared = SystemPasteboard()

    private let pasteboard = NSPasteboard.general

    public var changeCount: Int { pasteboard.changeCount }

    public func types() -> [String] {
        (pasteboard.types ?? []).map(\.rawValue)
    }

    public func data(forType type: String) -> Data? {
        pasteboard.data(forType: NSPasteboard.PasteboardType(type))
    }

    public func setData(_ data: Data, forType type: String) {
        pasteboard.setData(data, forType: NSPasteboard.PasteboardType(type))
    }

    public func clearContents() {
        pasteboard.clearContents()
    }
}
