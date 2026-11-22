import ApplicationServices

extension AXUIElement {
    func value(_ attribute: String) -> CFTypeRef? {
        var value: CFTypeRef?
        guard AXUIElementCopyAttributeValue(self, attribute as CFString, &value) == .success else { return nil }
        return value
    }

    @discardableResult
    func set(_ attribute: String, _ value: CFTypeRef) -> Bool {
        AXUIElementSetAttributeValue(self, attribute as CFString, value) == .success
    }

    var pid: pid_t? {
        var pid: pid_t = 0
        return AXUIElementGetPid(self, &pid) == .success ? pid : nil
    }

    var windows: [AXUIElement] { value(kAXWindowsAttribute) as? [AXUIElement] ?? [] }

    var focusedWindow: AXUIElement? {
        guard let value = value(kAXFocusedWindowAttribute), CFGetTypeID(value) == AXUIElementGetTypeID()
        else { return nil }
        return (value as! AXUIElement)
    }

    var title: String? { value(kAXTitleAttribute) as? String }
    var isStandardWindow: Bool { value(kAXSubroleAttribute) as? String == kAXStandardWindowSubrole }
    var isMinimized: Bool { value(kAXMinimizedAttribute) as? Bool ?? false }
    var isFullscreen: Bool { value("AXFullScreen") as? Bool ?? false }

    var frame: CGRect? {
        guard let position = axValue(kAXPositionAttribute), let sizeValue = axValue(kAXSizeAttribute) else {
            return nil
        }
        var origin = CGPoint.zero
        var size = CGSize.zero
        guard AXValueGetValue(position, .cgPoint, &origin), AXValueGetValue(sizeValue, .cgSize, &size) else {
            return nil
        }
        return CGRect(origin: origin, size: size)
    }

    func setPosition(_ point: CGPoint) {
        var point = point
        if let value = AXValueCreate(.cgPoint, &point) { set(kAXPositionAttribute, value) }
    }

    func setSize(_ size: CGSize) {
        var size = size
        if let value = AXValueCreate(.cgSize, &size) { set(kAXSizeAttribute, value) }
    }

    private func axValue(_ attribute: String) -> AXValue? {
        guard let value = value(attribute), CFGetTypeID(value) == AXValueGetTypeID() else { return nil }
        return (value as! AXValue)
    }
}
