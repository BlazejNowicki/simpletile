import AppKit
import ApplicationServices
import SimpleTileCore

/// Records focus changes: app activation from NSWorkspace, window changes within an app from AX.
@MainActor
final class FocusTracker {
    private(set) var history = FocusHistory()
    private let windows: WindowSystem
    private var observers: [pid_t: AXObserver] = [:]

    init(windows: WindowSystem) {
        self.windows = windows
    }

    func start() {
        let center = NSWorkspace.shared.notificationCenter
        center.addObserver(forName: NSWorkspace.didActivateApplicationNotification, object: nil, queue: .main) {
            [weak self] _ in
            MainActor.assumeIsolated { self?.recordFrontmost() }
        }
        center.addObserver(forName: NSWorkspace.didLaunchApplicationNotification, object: nil, queue: .main) {
            [weak self] note in
            let pid = (note.userInfo?[NSWorkspace.applicationUserInfoKey] as? NSRunningApplication)?.processIdentifier
            MainActor.assumeIsolated { if let pid { self?.observe(pid) } }
        }
        center.addObserver(forName: NSWorkspace.didTerminateApplicationNotification, object: nil, queue: .main) {
            [weak self] note in
            let pid = (note.userInfo?[NSWorkspace.applicationUserInfoKey] as? NSRunningApplication)?.processIdentifier
            MainActor.assumeIsolated { if let pid { self?.unobserve(pid) } }
        }
        for app in NSWorkspace.shared.runningApplications where app.activationPolicy == .regular {
            observe(app.processIdentifier)
        }
        recordFrontmost()
    }

    func record(_ id: WindowID) {
        history.touch(id)
    }

    fileprivate func windowFocused(_ window: AXUIElement) {
        history.touch(windows.id(for: window))
    }

    private func recordFrontmost() {
        if let id = windows.focusedWindowID() { history.touch(id) }
    }

    private func observe(_ pid: pid_t) {
        guard observers[pid] == nil, pid != ProcessInfo.processInfo.processIdentifier else { return }
        var observer: AXObserver?
        guard AXObserverCreate(pid, focusChangedCallback, &observer) == .success, let observer else { return }
        let refcon = Unmanaged.passUnretained(self).toOpaque()
        AXObserverAddNotification(
            observer, AXUIElementCreateApplication(pid), kAXFocusedWindowChangedNotification as CFString, refcon)
        CFRunLoopAddSource(CFRunLoopGetMain(), AXObserverGetRunLoopSource(observer), .defaultMode)
        observers[pid] = observer
    }

    private func unobserve(_ pid: pid_t) {
        guard let observer = observers.removeValue(forKey: pid) else { return }
        CFRunLoopRemoveSource(CFRunLoopGetMain(), AXObserverGetRunLoopSource(observer), .defaultMode)
    }
}

/// Runs on the main run loop, where the observer sources are installed.
private func focusChangedCallback(
    _: AXObserver, _ element: AXUIElement, _: CFString, _ refcon: UnsafeMutableRawPointer?
) {
    guard let refcon else { return }
    let tracker = Unmanaged<FocusTracker>.fromOpaque(refcon).takeUnretainedValue()
    nonisolated(unsafe) let window = element
    MainActor.assumeIsolated { tracker.windowFocused(window) }
}
