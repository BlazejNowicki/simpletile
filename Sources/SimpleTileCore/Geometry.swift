import CoreGraphics

public enum TileTarget: Sendable, Equatable {
    case left, right, fill
}

/// All rects are in AX coordinates: origin at the top-left of the primary display, y grows downward.
public enum Geometry {
    /// The left half gets the extra point when the width is odd.
    public static func tile(_ target: TileTarget, in area: CGRect) -> CGRect {
        let leftWidth = (area.width / 2).rounded(.up)
        switch target {
        case .fill:
            return area
        case .left:
            return CGRect(x: area.minX, y: area.minY, width: leftWidth, height: area.height)
        case .right:
            return CGRect(
                x: area.minX + leftWidth, y: area.minY,
                width: area.width - leftWidth, height: area.height)
        }
    }

    /// AppKit rects have their origin at the bottom-left of the primary display, with y growing upward.
    public static func axRect(fromAppKit rect: CGRect, primaryDisplayHeight: CGFloat) -> CGRect {
        CGRect(
            x: rect.minX, y: primaryDisplayHeight - rect.maxY,
            width: rect.width, height: rect.height)
    }

    /// Index of the area that overlaps `rect` the most, or nil when none overlaps.
    public static func bestArea(for rect: CGRect, among areas: [CGRect]) -> Int? {
        var best: (index: Int, overlap: CGFloat)?
        for (index, area) in areas.enumerated() {
            let overlap = rect.intersection(area)
            guard !overlap.isNull else { continue }
            let size = overlap.width * overlap.height
            if size > 0, size > (best?.overlap ?? 0) {
                best = (index, size)
            }
        }
        return best?.index
    }
}
