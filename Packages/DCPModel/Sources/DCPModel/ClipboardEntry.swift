import Foundation

/// A single pasteboard representation captured at copy time (e.g. plain
/// text, RTF, HTML). Keeping the raw type/data pair — rather than
/// flattening straight to a `String` — is what lets rich text round-trip
/// losslessly through history, and lets image support be added later by
/// extending `PasteboardType.allowList` rather than reshaping this type.
public struct PasteboardRepresentation: Equatable, Sendable {
    public let type: String
    public let data: Data

    public init(type: String, data: Data) {
        self.type = type
        self.data = data
    }
}

/// Pasteboard type identifiers this app knows how to capture/restore.
/// Extending to images later means adding `public.png`/`public.tiff` here.
public enum PasteboardType {
    public static let plainText = "public.utf8-plain-text"
    public static let rtf = "public.rtf"
    public static let html = "public.html"
    public static let allowList: [String] = [plainText, rtf, html]

    /// Convention respected by clipboard managers: password managers (1Password,
    /// Bitwarden, etc.) mark a pasteboard write with one of these types to
    /// signal "don't capture this into history." Not optional — any tool that
    /// keeps clipboard history is expected to honor it.
    public static let concealed = "org.nspasteboard.ConcealedType"
    public static let transient = "org.nspasteboard.TransientType"
    public static let exclusionMarkers: [String] = [concealed, transient]

    public static func isExcluded(types: [String]) -> Bool {
        !Set(types).isDisjoint(with: exclusionMarkers)
    }
}

public struct ClipboardEntry: Identifiable, Equatable, Sendable {
    public let id: UUID
    public let capturedAt: Date
    public let previewText: String
    public let representations: [PasteboardRepresentation]

    public init(id: UUID = UUID(), capturedAt: Date = Date(), previewText: String, representations: [PasteboardRepresentation]) {
        self.id = id
        self.capturedAt = capturedAt
        self.previewText = previewText
        self.representations = representations
    }

    /// Builds an entry from the pasteboard's currently available types,
    /// reading each allow-listed type's data via `dataProvider`. Returns
    /// `nil` if the pasteboard is marked concealed/transient (see
    /// `PasteboardType.exclusionMarkers`), or if none of the allow-listed
    /// types are present (e.g. only an image or file was copied — not yet
    /// supported).
    public static func capture(types: [String], dataProvider: (String) -> Data?) -> ClipboardEntry? {
        guard !PasteboardType.isExcluded(types: types) else { return nil }

        let representations = PasteboardType.allowList.compactMap { type -> PasteboardRepresentation? in
            guard types.contains(type), let data = dataProvider(type) else { return nil }
            return PasteboardRepresentation(type: type, data: data)
        }
        guard !representations.isEmpty else { return nil }

        let preview = representations
            .first { $0.type == PasteboardType.plainText }
            .flatMap { String(data: $0.data, encoding: .utf8) }
            ?? "(rich text)"

        return ClipboardEntry(previewText: preview, representations: representations)
    }
}
