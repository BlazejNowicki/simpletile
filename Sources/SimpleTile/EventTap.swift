import CoreGraphics
import Foundation
import SimpleTileCore

/// Owns the CGEventTap and its InputMatcher on a dedicated thread. The matcher has to decide synchronously
/// whether to swallow each event, and macOS disables taps whose callback is slow, so actions are handed off.
final class EventTap: @unchecked Sendable {
    private let onActions: @Sendable ([InputAction]) -> Void
    private var matcher = InputMatcher()
    private var port: CFMachPort?
    private var started = false

    init(onActions: @escaping @Sendable ([InputAction]) -> Void) {
        self.onActions = onActions
    }

    /// False when the tap can't be created, which means the Accessibility permission is missing.
    func start() -> Bool {
        let ready = DispatchSemaphore(value: 0)
        let thread = Thread { [self] in
            let mask: CGEventMask =
                1 << CGEventType.keyDown.rawValue | 1 << CGEventType.keyUp.rawValue
                | 1 << CGEventType.flagsChanged.rawValue
            port = CGEvent.tapCreate(
                tap: .cgSessionEventTap, place: .headInsertEventTap, options: .defaultTap,
                eventsOfInterest: mask, callback: eventTapCallback,
                userInfo: Unmanaged.passUnretained(self).toOpaque())
            guard let port else {
                ready.signal()
                return
            }
            CFRunLoopAddSource(CFRunLoopGetCurrent(), CFMachPortCreateRunLoopSource(nil, port, 0), .commonModes)
            started = true
            ready.signal()
            CFRunLoopRun()
        }
        thread.name = "EventTap"
        thread.start()
        ready.wait()
        return started
    }

    fileprivate func handle(_ type: CGEventType, _ event: CGEvent) -> Unmanaged<CGEvent>? {
        let kind: KeyEvent.Kind
        switch type {
        case .keyDown: kind = .keyDown
        case .keyUp: kind = .keyUp
        case .flagsChanged: kind = .flagsChanged
        case .tapDisabledByTimeout, .tapDisabledByUserInput:
            if let port { CGEvent.tapEnable(tap: port, enable: true) }
            return Unmanaged.passUnretained(event)
        default:
            return Unmanaged.passUnretained(event)
        }
        let keyEvent = KeyEvent(
            kind: kind,
            keyCode: UInt16(event.getIntegerValueField(.keyboardEventKeycode)),
            modifiers: Modifiers(event.flags))
        let result = matcher.handle(keyEvent)
        if !result.actions.isEmpty { onActions(result.actions) }
        return result.swallow ? nil : Unmanaged.passUnretained(event)
    }
}

private func eventTapCallback(
    _: CGEventTapProxy, _ type: CGEventType, _ event: CGEvent, _ refcon: UnsafeMutableRawPointer?
) -> Unmanaged<CGEvent>? {
    guard let refcon else { return Unmanaged.passUnretained(event) }
    return Unmanaged<EventTap>.fromOpaque(refcon).takeUnretainedValue().handle(type, event)
}
