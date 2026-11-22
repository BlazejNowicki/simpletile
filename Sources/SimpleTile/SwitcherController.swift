import AppKit
import SimpleTileCore

/// Drives one switcher session from ⌥Tab to commit or cancel.
@MainActor
final class SwitcherController {
    /// A quick ⌥Tab commits before this delay passes, so the panel doesn't flash.
    private static let showDelay: TimeInterval = 0.1

    private let windows: WindowSystem
    private let focus: FocusTracker
    private let panel = SwitcherPanel()
    private var switcher: SwitcherState?
    /// Lets a delayed show tell whether its session is still the open one.
    private var session = 0

    init(windows: WindowSystem, focus: FocusTracker) {
        self.windows = windows
        self.focus = focus
    }

    func handle(_ action: SwitcherAction) {
        switch action {
        case .open:
            open()
        case .next:
            switcher?.next()
            if let switcher { panel.select(switcher.selected) }
        case .previous:
            switcher?.previous()
            if let switcher { panel.select(switcher.selected) }
        case .commit:
            if let selection = switcher?.selection {
                windows.focus(selection)
                focus.record(selection)
            }
            close()
        case .cancel:
            close()
        }
    }

    private func open() {
        let entries = windows.standardWindows()
        let byID = Dictionary(uniqueKeysWithValues: entries.map { ($0.id, $0) })
        let ordered = focus.history.ordered(entries.map(\.id))
        guard let state = SwitcherState(entries: ordered) else { return }
        switcher = state
        session += 1
        let current = session

        let items = ordered.compactMap { byID[$0] }.map {
            SwitcherItem(title: $0.title, icon: NSRunningApplication(processIdentifier: $0.pid)?.icon)
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + Self.showDelay) { [weak self] in
            MainActor.assumeIsolated {
                guard let self, self.session == current, let switcher = self.switcher else { return }
                self.panel.show(items, selected: switcher.selected)
            }
        }
    }

    private func close() {
        switcher = nil
        session += 1
        panel.hide()
    }
}
