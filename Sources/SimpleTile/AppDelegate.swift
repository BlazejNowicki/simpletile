import AppKit
import ApplicationServices
import ServiceManagement
import SimpleTileCore
import os

@MainActor
final class AppDelegate: NSObject, NSApplicationDelegate, NSMenuDelegate {
    /// A quick ⌥Tab commits before this delay passes, so the panel doesn't flash.
    private static let switcherShowDelay: TimeInterval = 0.1

    private let log = Logger(subsystem: "simpletile", category: "app")
    private let windows = WindowSystem()
    private lazy var focus = FocusTracker(windows: windows)
    private let panel = SwitcherPanel()
    private var tap: EventTap?
    private var statusItem: NSStatusItem?
    private let permissionItem = NSMenuItem(title: "Waiting for Accessibility permission", action: nil, keyEquivalent: "")
    private let launchAtLoginItem = NSMenuItem(title: "Launch at Login", action: nil, keyEquivalent: "")
    private var permissionTimer: Timer?

    private var switcher: SwitcherState?
    private var switcherSession = 0

    func applicationDidFinishLaunching(_ notification: Notification) {
        // A login item plus a manual launch would otherwise run two event taps handling every shortcut twice.
        if let bundleID = Bundle.main.bundleIdentifier,
            NSRunningApplication.runningApplications(withBundleIdentifier: bundleID).count > 1
        {
            NSApp.terminate(nil)
            return
        }
        setUpStatusItem()
        let options = ["AXTrustedCheckOptionPrompt": true] as CFDictionary
        if AXIsProcessTrustedWithOptions(options) {
            start()
            return
        }
        permissionItem.isHidden = false
        // macOS has no public notification for the permission being granted.
        permissionTimer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { [weak self] _ in
            MainActor.assumeIsolated {
                guard let self, AXIsProcessTrusted() else { return }
                self.permissionTimer?.invalidate()
                self.permissionItem.isHidden = true
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
            case .switcher(let action): handle(action)
            }
        }
    }

    private func handle(_ action: SwitcherAction) {
        switch action {
        case .open:
            openSwitcher()
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
            closeSwitcher()
        case .cancel:
            closeSwitcher()
        }
    }

    private func openSwitcher() {
        let entries = windows.standardWindows()
        let byID = Dictionary(uniqueKeysWithValues: entries.map { ($0.id, $0) })
        let ordered = focus.history.ordered(entries.map(\.id))
        guard let state = SwitcherState(entries: ordered) else { return }
        switcher = state
        switcherSession += 1
        let session = switcherSession

        let items = ordered.compactMap { byID[$0] }.map {
            SwitcherItem(title: $0.title, icon: NSRunningApplication(processIdentifier: $0.pid)?.icon)
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + Self.switcherShowDelay) { [weak self] in
            MainActor.assumeIsolated {
                guard let self, self.switcherSession == session, let switcher = self.switcher else { return }
                self.panel.show(items, selected: switcher.selected)
            }
        }
    }

    private func closeSwitcher() {
        switcher = nil
        switcherSession += 1
        panel.hide()
    }

    private func setUpStatusItem() {
        let item = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        item.button?.image = NSImage(systemSymbolName: "rectangle.split.2x1", accessibilityDescription: "SimpleTile")
        let menu = NSMenu()
        menu.delegate = self
        permissionItem.isHidden = true
        menu.addItem(permissionItem)
        launchAtLoginItem.target = self
        launchAtLoginItem.action = #selector(toggleLaunchAtLogin)
        // Registration needs an app bundle; `swift run` has none.
        launchAtLoginItem.isHidden = Bundle.main.bundleIdentifier == nil
        menu.addItem(launchAtLoginItem)
        menu.addItem(.separator())
        menu.addItem(NSMenuItem(title: "Quit", action: #selector(NSApplication.terminate(_:)), keyEquivalent: "q"))
        item.menu = menu
        statusItem = item
    }

    /// The setting can also change in System Settings, so it is read each time the menu opens.
    func menuWillOpen(_ menu: NSMenu) {
        launchAtLoginItem.state = SMAppService.mainApp.status == .enabled ? .on : .off
    }

    @objc private func toggleLaunchAtLogin() {
        let service = SMAppService.mainApp
        do {
            if service.status == .enabled {
                try service.unregister()
            } else {
                try service.register()
                if service.status == .requiresApproval { SMAppService.openSystemSettingsLoginItems() }
            }
        } catch {
            log.error("Launch at login: \(error.localizedDescription)")
            let alert = NSAlert(error: error)
            alert.messageText = "Could not change Launch at Login"
            alert.runModal()
        }
    }
}
