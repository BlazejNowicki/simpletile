import AppKit
import ApplicationServices
import SimpleTileCore
import os

@MainActor
final class AppDelegate: NSObject, NSApplicationDelegate {
    private let log = Logger(subsystem: "simpletile", category: "app")
    private let windows = WindowSystem()
    private lazy var focus = FocusTracker(windows: windows)
    private lazy var switcher = SwitcherController(windows: windows, focus: focus)
    private var tap: EventTap?
    private var statusMenu: StatusMenu?
    private var permissionTimer: Timer?

    func applicationDidFinishLaunching(_ notification: Notification) {
        // A login item plus a manual launch would otherwise run two event taps handling every shortcut twice.
        if let bundleID = Bundle.main.bundleIdentifier,
            NSRunningApplication.runningApplications(withBundleIdentifier: bundleID).count > 1
        {
            NSApp.terminate(nil)
            return
        }
        let statusMenu = StatusMenu()
        self.statusMenu = statusMenu
        let options = ["AXTrustedCheckOptionPrompt": true] as CFDictionary
        if AXIsProcessTrustedWithOptions(options) {
            start()
            return
        }
        statusMenu.isWaitingForPermission = true
        // macOS has no public notification for the permission being granted.
        permissionTimer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { [weak self] _ in
            MainActor.assumeIsolated {
                guard let self, AXIsProcessTrusted() else { return }
                self.permissionTimer?.invalidate()
                self.statusMenu?.isWaitingForPermission = false
                self.start()
            }
        }
    }

    private func start() {
        focus.start()
        let tap = EventTap { [weak self] actions in
            DispatchQueue.main.async {
                MainActor.assumeIsolated { self?.handle(actions) }
            }
        }
        if !tap.start() { log.error("Could not create the event tap") }
        self.tap = tap
    }

    private func handle(_ actions: [InputAction]) {
        for action in actions {
            switch action {
            case .tile(let target): windows.tileFocusedWindow(target)
            case .switcher(let action): switcher.handle(action)
            }
        }
    }
}
