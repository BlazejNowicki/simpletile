import AppKit

struct SwitcherItem {
    let title: String
    let icon: NSImage?
}

/// Non-activating, so showing it never takes focus from the app being switched away from.
@MainActor
final class SwitcherPanel {
    private enum Metrics {
        static let tile = NSSize(width: 128, height: 116)
        static let spacing: CGFloat = 8
        static let padding: CGFloat = 16
    }

    private let panel: NSPanel
    private var tiles: [SwitcherTile] = []

    init() {
        panel = NSPanel(
            contentRect: .zero, styleMask: [.borderless, .nonactivatingPanel], backing: .buffered, defer: true)
        panel.level = .popUpMenu
        panel.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary, .transient]
        panel.isOpaque = false
        panel.backgroundColor = .clear
        panel.hasShadow = true
        panel.hidesOnDeactivate = false
        panel.appearance = NSAppearance(named: .darkAqua)
    }

    /// Centred on the display with the menu bar.
    func show(_ items: [SwitcherItem], selected: Int) {
        guard let screen = NSScreen.screens.first, !items.isEmpty else { return }
        let step = Metrics.tile.width + Metrics.spacing
        let maxColumns = max(1, Int((screen.visibleFrame.width * 0.9 - 2 * Metrics.padding + Metrics.spacing) / step))
        let columns = min(items.count, maxColumns)
        let rows = (items.count + columns - 1) / columns
        let size = NSSize(
            width: 2 * Metrics.padding + CGFloat(columns) * step - Metrics.spacing,
            height: 2 * Metrics.padding + CGFloat(rows) * (Metrics.tile.height + Metrics.spacing) - Metrics.spacing)

        let background = NSVisualEffectView(frame: NSRect(origin: .zero, size: size))
        background.material = .hudWindow
        background.blendingMode = .behindWindow
        background.state = .active
        background.wantsLayer = true
        background.layer?.cornerRadius = 16
        background.layer?.masksToBounds = true

        tiles = items.enumerated().map { index, item in
            let row = CGFloat(index / columns)
            let column = CGFloat(index % columns)
            let origin = NSPoint(
                x: Metrics.padding + column * step,
                y: size.height - Metrics.padding - (row + 1) * Metrics.tile.height - row * Metrics.spacing)
            let tile = SwitcherTile(frame: NSRect(origin: origin, size: Metrics.tile), item: item)
            background.addSubview(tile)
            return tile
        }
        panel.contentView = background
        panel.setFrame(
            NSRect(
                x: screen.frame.midX - size.width / 2, y: screen.frame.midY - size.height / 2,
                width: size.width, height: size.height),
            display: true)
        select(selected)
        panel.orderFrontRegardless()
    }

    func select(_ index: Int) {
        for (i, tile) in tiles.enumerated() { tile.isSelected = i == index }
    }

    func hide() {
        panel.orderOut(nil)
        tiles = []
    }
}

private final class SwitcherTile: NSView {
    var isSelected = false {
        didSet { layer?.backgroundColor = isSelected ? NSColor.white.withAlphaComponent(0.2).cgColor : nil }
    }

    init(frame: NSRect, item: SwitcherItem) {
        super.init(frame: frame)
        wantsLayer = true
        layer?.cornerRadius = 10

        let iconSize: CGFloat = 64
        let icon = NSImageView(
            frame: NSRect(x: (frame.width - iconSize) / 2, y: frame.height - 8 - iconSize, width: iconSize, height: iconSize))
        icon.image = item.icon
        icon.imageScaling = .scaleProportionallyUpOrDown
        addSubview(icon)

        let label = NSTextField(wrappingLabelWithString: item.title)
        label.frame = NSRect(x: 6, y: 6, width: frame.width - 12, height: 32)
        label.alignment = .center
        label.font = .systemFont(ofSize: 11)
        label.maximumNumberOfLines = 2
        label.cell?.truncatesLastVisibleLine = true
        addSubview(label)
    }

    required init?(coder: NSCoder) { fatalError("not used") }
}
