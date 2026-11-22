import CoreGraphics
import Testing

@testable import SimpleTileCore

struct GeometryTests {
    let area = CGRect(x: 0, y: 25, width: 1440, height: 875)

    @Test("TIL-1: left takes the left half of the usable area")
    func left() {
        #expect(Geometry.tile(.left, in: area) == CGRect(x: 0, y: 25, width: 720, height: 875))
    }

    @Test("TIL-2: right takes the right half of the usable area")
    func right() {
        #expect(Geometry.tile(.right, in: area) == CGRect(x: 720, y: 25, width: 720, height: 875))
    }

    @Test("TIL-3: fill takes the whole usable area")
    func fill() {
        #expect(Geometry.tile(.fill, in: area) == area)
    }

    @Test("TIL-1, TIL-2: odd widths give the extra point to the left half")
    func oddWidth() {
        let odd = CGRect(x: 0, y: 0, width: 1441, height: 900)
        #expect(Geometry.tile(.left, in: odd).width == 721)
        #expect(Geometry.tile(.right, in: odd) == CGRect(x: 721, y: 0, width: 720, height: 900))
    }

    @Test("TIL-1, TIL-2: halves of a display left of and above the primary one")
    func offsetDisplay() {
        let secondary = CGRect(x: -1920, y: -1080, width: 1920, height: 1080)
        #expect(Geometry.tile(.left, in: secondary) == CGRect(x: -1920, y: -1080, width: 960, height: 1080))
        #expect(Geometry.tile(.right, in: secondary) == CGRect(x: -960, y: -1080, width: 960, height: 1080))
    }

    @Test("AppKit rects convert to AX coordinates")
    func conversion() {
        // Primary display 1440x900, menu bar 25 pt, Dock 0: visible frame in AppKit is (0, 0, 1440, 875).
        let visible = CGRect(x: 0, y: 0, width: 1440, height: 875)
        #expect(Geometry.axRect(fromAppKit: visible, primaryDisplayHeight: 900) == area)

        // A display above the primary one has a positive AppKit y and a negative AX y.
        let above = CGRect(x: 0, y: 900, width: 1920, height: 1080)
        #expect(
            Geometry.axRect(fromAppKit: above, primaryDisplayHeight: 900)
                == CGRect(x: 0, y: -1080, width: 1920, height: 1080))
    }

    @Test("A window spanning two displays belongs to the one holding more of it")
    func bestArea() {
        let main = CGRect(x: 0, y: 0, width: 1440, height: 900)
        let right = CGRect(x: 1440, y: 0, width: 1920, height: 1080)
        let mostlyRight = CGRect(x: 1300, y: 100, width: 800, height: 600)
        #expect(Geometry.bestArea(for: mostlyRight, among: [main, right]) == 1)
        #expect(Geometry.bestArea(for: CGRect(x: 5000, y: 0, width: 10, height: 10), among: [main, right]) == nil)
    }
}
