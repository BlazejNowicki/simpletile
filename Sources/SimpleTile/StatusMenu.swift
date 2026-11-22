import AppKit
import ServiceManagement
import os

@MainActor
final class StatusMenu: NSObject, NSMenuDelegate {
    private let log = Logger(subsystem: "simpletile", category: "app")
    private let statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
    private let permissionItem = NSMenuItem(
        title: "Waiting for Accessibility permission", action: nil, keyEquivalent: "")
    private let launchAtLoginItem = NSMenuItem(title: "Launch at Login", action: nil, keyEquivalent: "")

    var isWaitingForPermission: Bool {
        get { !permissionItem.isHidden }
        set { permissionItem.isHidden = !newValue }
    }

    override init() {
        super.init()
        statusItem.button?.image = NSImage(
            systemSymbolName: "rectangle.split.2x1", accessibilityDescription: "SimpleTile")
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
        statusItem.menu = menu
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
