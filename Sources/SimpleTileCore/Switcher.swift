/// Opaque window identity, minted by the shell.
public struct WindowID: Hashable, Sendable {
    public let raw: Int
    public init(_ raw: Int) { self.raw = raw }
}

/// The open switcher: entries are frozen at open.
public struct SwitcherState: Sendable, Equatable {
    public let entries: [WindowID]
    public private(set) var selected: Int

    /// Nil with no entries. Opens on the second entry, so a quick ⌥Tab returns to the previous window,
    /// or on the only entry.
    public init?(entries: [WindowID]) {
        guard !entries.isEmpty else { return nil }
        self.entries = entries
        self.selected = entries.count > 1 ? 1 : 0
    }

    public var selection: WindowID { entries[selected] }

    public mutating func next() {
        selected = (selected + 1) % entries.count
    }

    public mutating func previous() {
        selected = (selected - 1 + entries.count) % entries.count
    }
}

/// Windows ordered by when they last had focus.
public struct FocusHistory: Sendable {
    private var recent: [WindowID] = []

    public init() {}

    public mutating func touch(_ id: WindowID) {
        recent.removeAll { $0 == id }
        recent.insert(id, at: 0)
    }

    /// Most recently focused first. Windows never seen focused follow, in their given order.
    public func ordered(_ ids: [WindowID]) -> [WindowID] {
        let present = Set(ids)
        let known = recent.filter(present.contains)
        let knownSet = Set(known)
        return known + ids.filter { !knownSet.contains($0) }
    }
}
