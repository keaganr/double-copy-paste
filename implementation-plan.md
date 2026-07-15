# Double Copy Paste — Implementation Plan

## Context

`functionality.md` describes a native macOS menu-bar utility that keeps a
running history of the clipboard, so a user can click back through recent
copies and restore an older one — instead of losing it the moment
something new is copied over it. This is a from-scratch project modeled
directly on the scaffolding, tooling, and CI conventions of a sibling
project, `simple-window-snap` (also a native macOS menu-bar utility),
reused wherever the pattern fit and adapted only where the clipboard
domain differs from window-snapping.

Fixed constraints for v1:

1. **Content types**: plain text and rich text (RTF/HTML). The storage
   model captures a list of raw pasteboard representations per entry
   (not a single `String`), specifically so image support can be added
   later by extending an allow-list rather than restructuring the model.
2. **History is in-memory only**, capped at a fixed count (`maxEntries`,
   default 50). No disk persistence, no settings UI — history resets on
   quit/restart. Simpler than `simple-window-snap`'s JSON-backed store.
3. **UI is a single `MenuBarExtra` dropdown list** — no separate
   history/search window.
4. **Direct distribution, unsandboxed** — same as the reference project,
   signed with a Developer ID certificate and notarized via GitHub
   Actions on tag push. (Clipboard access itself doesn't require this —
   `NSPasteboard.general` works fine sandboxed — but keeping the same
   distribution model as the reference project keeps the CI/signing setup
   directly reusable.)
5. **macOS 13 Ventura+ minimum**, for SwiftUI's `MenuBarExtra`.

## Project Structure

```
double-copy-paste/
  DoubleCopyPaste.xcodeproj
  App/
    DoubleCopyPasteApp.swift     # @main, MenuBarExtra scene
    AppDelegate.swift            # NSApplicationDelegateAdaptor
    Info.plist                   # LSUIElement = YES
    Assets.xcassets
  Packages/
    DCPModel/            # ClipboardEntry / PasteboardRepresentation + ClipboardHistoryStore (pure Swift)
    DCPClipboard/         # PasteboardProviding protocol + ClipboardWatcher (NSPasteboard polling + restore)
    DCPUI/                 # SwiftUI views: MenuBarContentView, LaunchAtLoginManager
  README.md
  .gitignore
```

No third-party SPM dependencies — everything is built on first-party
frameworks (`AppKit`, `SwiftUI`, `ServiceManagement`, `os.Logger`).

## Core Technical Design

**Clipboard watching (the crux):** there's no OS push notification for
"clipboard changed." `ClipboardWatcher` (in `DCPClipboard`) polls
`NSPasteboard.general.changeCount` on a `Timer` (default every 0.5s). When
the count changes, it reads the pasteboard's current representations and
emits a new `ClipboardEntry` via a callback.

Pasteboard access is wrapped behind a `PasteboardProviding` protocol (real
`NSPasteboard.general` conformance + an in-memory fake for tests), so
`ClipboardWatcher` is unit-testable without touching the real system
pasteboard.

**Self-restore loop (the single most common bug source here):** clicking a
history entry writes it back to `NSPasteboard.general`, which bumps
`changeCount` again. Without a guard, the watcher's next poll would see
"a change" and re-capture the app's own restore as a brand-new history
entry — duplicating/reordering history on every click. Fix:
`ClipboardWatcher.restore(_:)` updates its own `lastSeenChangeCount` to the
pasteboard's post-write value before returning, so the following poll sees
no delta.

**Data model:** `ClipboardEntry` stores a list of raw pasteboard
representations (type identifier + `Data`), not a single string, so rich
text round-trips losslessly:

```swift
struct ClipboardEntry: Identifiable, Equatable {
    let id: UUID
    let capturedAt: Date
    let previewText: String                          // derived from the plain-text repr, for menu display
    let representations: [PasteboardRepresentation]   // e.g. public.utf8-plain-text, public.rtf, public.html
}
struct PasteboardRepresentation: Equatable {
    let type: String   // NSPasteboard.PasteboardType rawValue
    let data: Data
}
```

Capture reads an allow-list of pasteboard types (plain text, RTF, HTML).
Adding image support later means adding `public.png`/`public.tiff` to that
allow-list plus a thumbnail in the menu row — no model rework. Restore
writes every stored representation back via `setData(_:forType:)`.

**Privacy:** password managers (1Password, Bitwarden, etc.) mark sensitive
pasteboard writes with `org.nspasteboard.ConcealedType` /
`org.nspasteboard.TransientType`. `ClipboardWatcher` checks for these
before capturing and skips the pasteboard state entirely if present — this
is a respected convention among clipboard managers, not optional.

**Dedup:** `ClipboardHistoryStore.add(_:)` skips inserting if the new
entry's content matches the current most-recent entry (avoids a duplicate
row from copying the same thing twice in a row). New entries are
prepended; once the store exceeds `maxEntries`, the oldest is dropped.

**Menu bar:** `MenuBarExtra("Double Copy Paste", systemImage:
"doc.on.clipboard")` with `.menuBarExtraStyle(.menu)`. `MenuBarContentView`
lists `ClipboardHistoryStore.entries` (truncated `previewText` per row),
each a `Button` calling `clipboardWatcher.restore(entry)`; plus "Clear
History", a "Launch at Login" `Toggle` (`LaunchAtLoginManager`, ported
near-verbatim from the reference project — it's already generic and
`SMAppService`-based), a `Divider`, and "Quit".

## Workflow Notes

- A copy of this plan is committed to the repo as `implementation-plan.md`
  at the start of Phase 0.
- Each numbered phase below is its own git commit (or a small number of
  commits if a phase is large), committed once that phase's demoable
  behavior works.

## Phased Build Order (each phase demoable)

0. **Scaffolding** — XcodeGen project, `LSUIElement=YES`, empty local
   packages, git init, README stub.
1. **Clipboard watcher (log-only)** — `PasteboardProviding`,
   `ClipboardWatcher` polling loop, logged via `os.Logger`. No UI, no
   history store yet.
2. **History store** — `DCPModel`: `ClipboardEntry`,
   `ClipboardHistoryStore` (cap + dedup), unit tests; wire watcher output
   into the store.
3. **Menu bar UI** — `MenuBarExtra` + `MenuBarContentView` listing
   history, click-to-restore wired end-to-end (including the self-restore
   guard).
4. **Privacy filtering** — concealed/transient pasteboard type exclusion.
5. **Polish** — Launch at Login toggle, Clear History, app icon, README.
6. **Packaging/CI** — GitHub Actions release workflow (adapted from
   `simple-window-snap`), `DISTRIBUTION.md`, `ExportOptions.plist`,
   Developer ID signing + notarization.

## Testing Strategy

- **Unit-testable (XCTest, CI-safe):** `ClipboardEntry`
  construction/equality, `ClipboardHistoryStore` cap+dedup behavior,
  concealed-type filtering, and `ClipboardWatcher`'s self-restore
  bookkeeping — all against a fake `PasteboardProviding`, no real
  `NSPasteboard` needed.
- **Manual/integration QA only:** copy plain text and rich/formatted text
  from several different real apps and confirm entries appear correctly;
  click an older entry and paste elsewhere to confirm it restores
  (including formatting); copy the same content twice in a row and
  confirm no duplicate row; copy more than `maxEntries` items and confirm
  the oldest drops; verify a password manager's copy doesn't appear in
  history.

## Critical Files

- `App/DoubleCopyPasteApp.swift` — `@main` entry, `MenuBarExtra` scene
- `Packages/DCPClipboard/Sources/DCPClipboard/ClipboardWatcher.swift` — the crux polling/restore engine
- `Packages/DCPClipboard/Sources/DCPClipboard/PasteboardProviding.swift` — real/fake pasteboard abstraction
- `Packages/DCPModel/Sources/DCPModel/ClipboardEntry.swift` — data model
- `Packages/DCPModel/Sources/DCPModel/ClipboardHistoryStore.swift` — cap + dedup logic
- `Packages/DCPUI/Sources/DCPUI/MenuBarContentView.swift` — the dropdown UI

## Verification

- Each phase is individually demoable by running the app (`⌘R` in Xcode)
  and exercising that phase's behavior directly.
- Run `swift test` in each `Packages/DCP*` directory after phases that
  touch them.
- Before declaring the app "done," walk the manual QA checklist above at
  least once against real third-party apps.
