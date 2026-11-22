import Testing

@testable import SimpleTileCore

private let a = WindowID(1)
private let b = WindowID(2)
private let c = WindowID(3)
private let d = WindowID(4)

struct SwitcherStateTests {
    @Test("SW-3: opens with the second entry selected")
    func secondSelected() throws {
        let state = try #require(SwitcherState(entries: [a, b, c]))
        #expect(state.selection == c)
    }

    @Test("SW-4: next and previous wrap around")
    func wraps() throws {
        var state = try #require(SwitcherState(entries: [a, b, c]))
        state.next()
        #expect(state.selection == c)
        state.next()
        #expect(state.selection == a)
        state.previous()
        #expect(state.selection == c)
    }

    @Test("SW-3, SW-7: a single entry opens with that entry selected")
    func single() throws {
        let state = try #require(SwitcherState(entries: [a]))
        #expect(state.selection == a)
    }

    @Test("SW-4: next and previous stay on a single entry")
    func singleWraps() throws {
        var state = try #require(SwitcherState(entries: [a]))
        state.next()
        #expect(state.selection == a)
        state.previous()
        #expect(state.selection == a)
    }

    @Test("SW-7: no entries does not open")
    func empty() {
        #expect(SwitcherState(entries: []) == nil)
    }
}

struct FocusHistoryTests {
    @Test("SW-2: most recently focused first, never-focused windows after in given order")
    func order() {
        var history = FocusHistory()
        history.touch(b)
        history.touch(c)
        #expect(history.ordered([a, b, c, d]) == [c, b, a, d])
    }

    @Test("SW-2: focusing a window again moves it to the front")
    func refocus() {
        var history = FocusHistory()
        history.touch(a)
        history.touch(b)
        history.touch(a)
        #expect(history.ordered([a, b]) == [a, b])
    }

    @Test("SW-2: closed windows are left out")
    func closed() {
        var history = FocusHistory()
        history.touch(a)
        history.touch(b)
        #expect(history.ordered([a]) == [a])
    }
}
