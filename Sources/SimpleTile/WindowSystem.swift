import AppKit
import ApplicationServices
import SimpleTileCore

struct WindowEntry {
    let id: WindowID
    let pid: pid_t
    let title: String
}

/// Bridges the Accessibility API. AX calls run synchronously on the main thread with a short timeout,
/// so a hung app stalls the UI for at most `messagingTimeout` per call.
@MainActor
final class WindowSystem {
    private static let messagingTimeout: Float = 0.5

    private var ids: [AXUIElement: WindowID] = [:]
    private var elements: [WindowID: AXUIElement] = [:]
    private var lastID = 0
    private let ownPID = ProcessInfo.processInfo.processIdentifier

    func id(for window: AXUIElement) -> WindowID {
        if let id = ids[window] { return id }
        lastID += 1
        let id = WindowID(lastID)
        ids[window] = id
        elements[id] = window
        return id
    }

    /// Standard, non-minimized windows of regular apps, as AX reports them for the current Space.
    func standardWindows() -> [WindowEntry] {
        var entries: [WindowEntry] = []
        for app in NSWorkspace.shared.runningApplications
        where app.activationPolicy == .regular && app.processIdentifier != ownPID {
            for window in application(app.processIdentifier).windows
            where window.isStandardWindow && !window.isMinimized {
                let title = window.title.flatMap { $0.isEmpty ? nil : $0 } ?? app.localizedName ?? ""
                entries.append(WindowEntry(id: id(for: window), pid: app.processIdentifier, title: title))
            }
        }
        let present = Set(entries.map(\.id))
        for (id, element) in elements where !present.contains(id) {
            elements[id] = nil
            ids[element] = nil
        }
        return entries
    }

    func focusedWindowID() -> WindowID? {
        guard let app = NSWorkspace.shared.frontmostApplication, app.processIdentifier != ownPID,
            let window = application(app.processIdentifier).focusedWindow
        else { return nil }
        return id(for: window)
    }

    func tileFocusedWindow(_ target: TileTarget) {
        guard let app = NSWorkspace.shared.frontmostApplication, app.processIdentifier != ownPID else { return }
        let appElement = application(app.processIdentifier)
        guard let window = appElement.focusedWindow, !window.isFullscreen, let frame = window.frame else { return }

        let primaryHeight = NSScreen.screens.first?.frame.height ?? 0
        let areas = NSScreen.screens.map {
            Geometry.axRect(fromAppKit: $0.visibleFrame, primaryDisplayHeight: primaryHeight)
        }
        guard !areas.isEmpty else { return }
        let area = areas[Geometry.bestArea(for: frame, among: areas) ?? 0]
        setFrame(window, Geometry.tile(target, in: area), app: appElement)
    }

    func focus(_ id: WindowID) {
        guard let window = elements[id], let pid = window.pid,
            let target = NSRunningApplication(processIdentifier: pid)
        else { return }
        // Raise before activating, so the right window is on top when the app comes forward.
        window.set(kAXMainAttribute, kCFBooleanTrue)
        AXUIElementPerformAction(window, kAXRaiseAction as CFString)
        // Since macOS 14 activation is cooperative: a request from an inactive app is ignored, so we
        // activate ourselves and hand activation over. AXFrontmost would work but raises every window
        // of the app, like a Dock click. See docs/spikes.md.
        NSApp.activate()
        NSApp.yieldActivation(to: target)
        target.activate(from: .current, options: [])
    }

    private func application(_ pid: pid_t) -> AXUIElement {
        let element = AXUIElementCreateApplication(pid)
        AXUIElementSetMessagingTimeout(element, Self.messagingTimeout)
        return element
    }

    private func setFrame(_ window: AXUIElement, _ rect: CGRect, app: AXUIElement) {
        // Many apps animate AX moves while AXEnhancedUserInterface is on, which assistive tools enable.
        let enhancedUI = "AXEnhancedUserInterface"
        let wasEnhanced = app.value(enhancedUI) as? Bool ?? false
        if wasEnhanced { app.set(enhancedUI, kCFBooleanFalse) }
        defer { if wasEnhanced { app.set(enhancedUI, kCFBooleanTrue) } }

        // Size before and after the move: some apps clamp size to the display the window is on.
        window.setSize(rect.size)
        window.setPosition(rect.origin)
        window.setSize(rect.size)
    }
}
