import CoreGraphics

public struct Modifiers: OptionSet, Sendable, Hashable {
    public let rawValue: UInt8
    public init(rawValue: UInt8) { self.rawValue = rawValue }

    public static let shift = Modifiers(rawValue: 1 << 0)
    public static let control = Modifiers(rawValue: 1 << 1)
    public static let option = Modifiers(rawValue: 1 << 2)
    public static let command = Modifiers(rawValue: 1 << 3)

    /// Keeps only the four modifiers shortcuts use. Arrow keys also carry the fn and numeric pad flags.
    public init(_ flags: CGEventFlags) {
        var modifiers: Modifiers = []
        if flags.contains(.maskShift) { modifiers.insert(.shift) }
        if flags.contains(.maskControl) { modifiers.insert(.control) }
        if flags.contains(.maskAlternate) { modifiers.insert(.option) }
        if flags.contains(.maskCommand) { modifiers.insert(.command) }
        self = modifiers
    }
}

/// Physical key codes (`kVK_*`), so shortcuts don't depend on the keyboard layout.
public enum KeyCode {
    public static let tab: UInt16 = 48
    public static let escape: UInt16 = 53
    public static let leftArrow: UInt16 = 123
    public static let rightArrow: UInt16 = 124
    public static let upArrow: UInt16 = 126
}

public struct KeyEvent: Sendable, Equatable {
    public enum Kind: Sendable { case keyDown, keyUp, flagsChanged }

    public let kind: Kind
    public let keyCode: UInt16
    public let modifiers: Modifiers

    public init(kind: Kind, keyCode: UInt16, modifiers: Modifiers) {
        self.kind = kind
        self.keyCode = keyCode
        self.modifiers = modifiers
    }
}

public enum SwitcherAction: Sendable, Equatable {
    case open, next, previous, commit, cancel
}

public enum InputAction: Sendable, Equatable {
    case tile(TileTarget)
    case switcher(SwitcherAction)
}

/// Decides, synchronously and per event, which actions a key event triggers and whether it is swallowed.
public struct InputMatcher: Sendable {
    public struct Result: Sendable, Equatable {
        public let actions: [InputAction]
        public let swallow: Bool
    }

    private var switching = false
    /// Key-ups of swallowed key-downs, swallowed too so apps never see half a keystroke.
    private var pendingKeyUps: Set<UInt16> = []

    public init() {}

    public mutating func handle(_ event: KeyEvent) -> Result {
        // A missed ⌥ release (the tap can be disabled for a moment) must not leave the switcher stuck open.
        var actions: [InputAction] = []
        if switching, !event.modifiers.contains(.option) {
            switching = false
            actions.append(.switcher(.commit))
        }

        switch event.kind {
        case .flagsChanged:
            return Result(actions: actions, swallow: false)
        case .keyUp:
            let swallow = pendingKeyUps.remove(event.keyCode) != nil
            return Result(actions: actions, swallow: swallow)
        case .keyDown:
            guard let action = keyDown(event) else { return Result(actions: actions, swallow: false) }
            pendingKeyUps.insert(event.keyCode)
            return Result(actions: actions + [action], swallow: true)
        }
    }

    private mutating func keyDown(_ event: KeyEvent) -> InputAction? {
        if switching {
            switch event.keyCode {
            case KeyCode.tab:
                return .switcher(event.modifiers.contains(.shift) ? .previous : .next)
            case KeyCode.leftArrow:
                return .switcher(.previous)
            case KeyCode.rightArrow:
                return .switcher(.next)
            case KeyCode.escape:
                switching = false
                return .switcher(.cancel)
            default:
                return nil
            }
        }

        if event.modifiers == [.control, .option] {
            switch event.keyCode {
            case KeyCode.leftArrow: return .tile(.left)
            case KeyCode.rightArrow: return .tile(.right)
            case KeyCode.upArrow: return .tile(.fill)
            default: return nil
            }
        }

        if event.keyCode == KeyCode.tab,
            event.modifiers == .option || event.modifiers == [.option, .shift]
        {
            switching = true
            return .switcher(.open)
        }
        return nil
    }
}
