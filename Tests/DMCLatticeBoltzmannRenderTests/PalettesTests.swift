import XCTest

@testable import DMCLatticeBoltzmann
@testable import DMCLatticeBoltzmannRender

final class PalettesTests: XCTestCase {
    private func testColorRetrieval(_ colorFn: (Double) -> NSColor) throws {
        for fract in [-0.02, 0.0, 0.25, 0.5, 0.75, 0.99, 1.00, 1.2, 5.0] {
            let color = colorFn(fract)
            if fract < 0.0 {
                XCTAssertEqual(color, colorFn(0.0))
            } else if fract > 1.0 {
                XCTAssertEqual(color, colorFn(1.0))
            }
        }
    }

    func testColorRetrieval() throws {
        try testColorRetrieval(InfernoPalette.color)
        try testColorRetrieval(BWRPalette.color)
        try testColorRetrieval(BluescalePalette.color)
    }
}
