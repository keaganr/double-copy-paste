import Foundation

/// Publishes the current time once a second so views showing relative
/// timestamps (e.g. "10 seconds ago") redraw on a live cadence.
///
/// A `MenuBarExtra`'s content only re-renders in response to a state
/// change — not merely because the menu was reopened — so without this,
/// a timestamp would freeze at whatever it read on the last
/// history-driven redraw (i.e. when that entry was captured) until the
/// next clipboard copy forced a new one.
@MainActor
final class TickingClock: ObservableObject {
    @Published private(set) var now = Date()

    // `nonisolated(unsafe)` because `deinit` is always nonisolated even on
    // a @MainActor class; only ever touched on the main actor otherwise.
    private nonisolated(unsafe) var timer: Timer?

    init(interval: TimeInterval = 1) {
        timer = Timer.scheduledTimer(withTimeInterval: interval, repeats: true) { [weak self] _ in
            Task { @MainActor in
                self?.now = Date()
            }
        }
    }

    deinit {
        timer?.invalidate()
    }
}
