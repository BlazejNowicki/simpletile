import CoreGraphics
import Testing

@testable import SimpleTileCore

private func down(_ code: UInt16, _ modifiers: Modifiers = []) -> KeyEvent {
    KeyEvent(kind: .keyDown, keyCode: code, modifiers: modifiers)
}

private func up(_ code: UInt16, _ modifiers: Modifiers = []) -> KeyEvent {
    KeyEvent(kind: .keyUp, keyCode: code, modifiers: modifiers)
}

private func flags(_ modifiers: Modifiers) -> KeyEvent {
    KeyEvent(kind: .flagsChanged, keyCode: 0, modifiers: modifiers)
}

private let controlOption: Modifiers = [.control, .option]

struct TilingInputTests {
    @Test(
        "TIL-1, TIL-2, TIL-3: ⌥⌃ arrows tile and are swallowed",
        arguments: [
            (KeyCode.leftArrow, TileTarget.left),
            (KeyCode.rightArrow, TileTarget.right),
            (KeyCode.upArrow, TileTarget.fill),
        ])
    func tiles(code: UInt16, target: TileTarget) {
        var matcher = InputMatcher()
        let result = matcher.handle(down(code, controlOption))
        #expect(result == .init(actions: [.tile(target)], swallow: true))
    }

    @Test("TIL-1: the key-up of a tiling shortcut is swallowed too")
    func keyUpSwallowed() {
        var matcher = InputMatcher()
        _ = matcher.handle(down(KeyCode.leftArrow, controlOption))
        #expect(matcher.handle(up(KeyCode.leftArrow, controlOption)).swallow)
        #expect(!matcher.handle(up(KeyCode.leftArrow, controlOption)).swallow)
    }

    @Test(
        "TIL-1: other modifier combinations pass through",
        arguments: [Modifiers.control, .option, [.control, .option, .shift], [.control, .option, .command]])
    func otherModifiers(modifiers: Modifiers) {
        var matcher = InputMatcher()
        #expect(matcher.handle(down(KeyCode.leftArrow, modifiers)) == .init(actions: [], swallow: false))
    }

    @Test("TIL-1: fn and numeric pad flags on arrow keys are ignored")
    func arrowFlags() {
        let cgFlags: CGEventFlags = [.maskControl, .maskAlternate, .maskSecondaryFn, .maskNumericPad]
        var matcher = InputMatcher()
        let result = matcher.handle(down(KeyCode.leftArrow, Modifiers(cgFlags)))
        #expect(result.actions == [.tile(.left)])
    }
}

struct SwitcherInputTests {
    @Test("SW-1: ⌥Tab opens the switcher and is swallowed")
    func opens() {
        var matcher = InputMatcher()
        #expect(matcher.handle(down(KeyCode.tab, .option)) == .init(actions: [.switcher(.open)], swallow: true))
    }

    @Test("SW-4: Tab moves forward and ⇧Tab backward while ⌥ is held")
    func cycles() {
        var matcher = InputMatcher()
        _ = matcher.handle(down(KeyCode.tab, .option))
        _ = matcher.handle(up(KeyCode.tab, .option))
        #expect(matcher.handle(down(KeyCode.tab, .option)).actions == [.switcher(.next)])
        _ = matcher.handle(flags([.option, .shift]))
        #expect(matcher.handle(down(KeyCode.tab, [.option, .shift])).actions == [.switcher(.previous)])
    }

    @Test("SW-4: ← moves backward and → forward while switching, swallowed with their key-ups")
    func arrows() {
        var matcher = InputMatcher()
        _ = matcher.handle(down(KeyCode.tab, .option))
        #expect(
            matcher.handle(down(KeyCode.leftArrow, .option)) == .init(actions: [.switcher(.previous)], swallow: true))
        #expect(matcher.handle(up(KeyCode.leftArrow, .option)).swallow)
        #expect(matcher.handle(down(KeyCode.rightArrow, .option)) == .init(actions: [.switcher(.next)], swallow: true))
        #expect(matcher.handle(up(KeyCode.rightArrow, .option)).swallow)
    }

    @Test("SW-4: ⌥ arrows pass through when the switcher is closed")
    func arrowsWhenClosed() {
        var matcher = InputMatcher()
        #expect(matcher.handle(down(KeyCode.leftArrow, .option)) == .init(actions: [], swallow: false))
    }

    @Test("SW-5: releasing ⌥ commits, and the flags event passes through")
    func commits() {
        var matcher = InputMatcher()
        _ = matcher.handle(down(KeyCode.tab, .option))
        #expect(matcher.handle(flags([])) == .init(actions: [.switcher(.commit)], swallow: false))
        #expect(matcher.handle(flags([])).actions.isEmpty)
    }

    @Test("SW-5: releasing ⇧ while ⌥ is still held does not commit")
    func shiftRelease() {
        var matcher = InputMatcher()
        _ = matcher.handle(down(KeyCode.tab, [.option, .shift]))
        #expect(matcher.handle(flags(.option)).actions.isEmpty)
    }

    @Test("SW-5: a missed ⌥ release commits on the next key event")
    func missedRelease() {
        var matcher = InputMatcher()
        _ = matcher.handle(down(KeyCode.tab, .option))
        let result = matcher.handle(down(KeyCode.tab))
        #expect(result == .init(actions: [.switcher(.commit)], swallow: false))
    }

    @Test("SW-6: Esc cancels and is swallowed, and releasing ⌥ afterwards does nothing")
    func cancels() {
        var matcher = InputMatcher()
        _ = matcher.handle(down(KeyCode.tab, .option))
        #expect(matcher.handle(down(KeyCode.escape, .option)) == .init(actions: [.switcher(.cancel)], swallow: true))
        #expect(matcher.handle(up(KeyCode.escape, .option)).swallow)
        #expect(matcher.handle(flags([])).actions.isEmpty)
    }

    @Test("SW-8: Tab key-ups are swallowed while switching")
    func tabKeyUps() {
        var matcher = InputMatcher()
        _ = matcher.handle(down(KeyCode.tab, .option))
        #expect(matcher.handle(up(KeyCode.tab, .option)).swallow)
        _ = matcher.handle(down(KeyCode.tab, .option))
        #expect(matcher.handle(up(KeyCode.tab, .option)).swallow)
    }

    @Test("SW-8: other keys pass through while switching")
    func otherKeys() {
        var matcher = InputMatcher()
        _ = matcher.handle(down(KeyCode.tab, .option))
        #expect(matcher.handle(down(0, .option)) == .init(actions: [], swallow: false))
    }

    @Test("Tab without ⌥ and ⌘⌥Tab pass through", arguments: [Modifiers(), [.command, .option], .control])
    func plainTab(modifiers: Modifiers) {
        var matcher = InputMatcher()
        #expect(matcher.handle(down(KeyCode.tab, modifiers)) == .init(actions: [], swallow: false))
    }
}
