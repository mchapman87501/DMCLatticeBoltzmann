import XCTest

@testable import DMC2D
@testable import DMCLatticeBoltzmann

typealias CoordLists = [[DMCLatticeBoltzmann.ShapeAdjacentCoords.Coord]]

final class ShapeAdjacentCoordsTests: XCTestCase {

    func foilShape() -> Polygon {
        return AirFoil(
            x: 0.0, y: 0.0, width: 100.0, alphaRad: 4.0 * .pi / 180.0
        ).shape
    }

    func testInit() throws {
        let shape = foilShape()
        let adjCoords = ShapeAdjacentCoords(shape: shape)
        XCTAssertEqual(adjCoords.adjacents.count, shape.edges.count)
    }

    func testAdjacentsLieOutside() throws {
        let shape = foilShape()
        let adjCoords = ShapeAdjacentCoords(shape: shape)
        for edgePoints in adjCoords.adjacents {
            XCTAssertTrue(edgePoints.count > 0)
            for point in edgePoints {
                XCTAssertFalse(shape.contains(x: point.0, y: point.1))
            }
        }
    }

    struct ShapeMask: CustomStringConvertible {
        // Origin:
        let x: Int
        let y: Int
        // Size:
        let width: Int
        let height: Int

        let inShape: [[Bool]]

        init(shape: Polygon) {
            let sbb = shape.bbox
            let xOrigin = Int(sbb.minX) - 5
            let yOrigin = Int(sbb.minY) - 5
            let width = Int(0.5 + sbb.width) + 10
            let height = Int(0.5 + sbb.height) + 10

            var inShape = [[Bool]]()
            for y in yOrigin..<(yOrigin + height) {
                let row = (xOrigin..<(xOrigin + width)).map { x in
                    shape.contains(x: x, y: y)
                }
                inShape.append(row)
            }
            self.x = xOrigin
            self.y = yOrigin
            self.width = width
            self.height = height
            self.inShape = inShape
        }

        func contains(x xIn: Int, y yIn: Int) -> Bool {
            let ix = xIn - x
            if (ix < 0) || (ix >= width) {
                return false
            }
            let iy = yIn - y
            if (iy < 0) || (iy >= height) {
                return false
            }
            return inShape[iy][ix]
        }

        var description: String {
            return "ShapeMask(\(x), \(y), \(width), \(height))"
        }

        func getMaskStrGrid() -> [[String]] {
            let result: [[String]] = inShape.map { row in
                row.map { isMaskPoint in
                    return isMaskPoint ? "+" : "."
                }
            }
            return result
        }

        func adjMarker(_ isMaskPoint: Bool, index: Int = 0) -> String {
            // Points outside the mask are represented by a single decimal digit.
            let units = index % 10
            return isMaskPoint ? "*" : "\(units)"
        }

        func getMaskStr(with adjacents: CoordLists) -> [[String]] {
            var strGrid = getMaskStrGrid()
            for (iEdge, coordList) in adjacents.enumerated() {
                for (xc, yc) in coordList {
                    // Transform to grid coordinate system.
                    let xGrid = xc - x
                    let yGrid = yc - y
                    if (xGrid < 0) || (xGrid >= width) {
                        print(
                            "getMaskStr: x (\(xc) -> \(xGrid)) is out of bounds"
                        )
                    } else if (yGrid < 0) || (yGrid >= height) {
                        print(
                            "getMaskStr: y (\(yc) -> \(yGrid)) is out of bounds"
                        )
                    } else {
                        strGrid[yGrid][xGrid] = adjMarker(
                            inShape[yGrid][xGrid], index: iEdge)
                    }
                }
            }
            return strGrid
        }

        func printMaskStr(_ maskStr: [[String]]) {
            // A diagnostic image would work better here...
            // This tries to pixellate the polygon and the generated adjacents
            // list, as text to stdout.
            for row in maskStr.reversed() {
                print(row.joined(separator: ""))
            }
        }

        func printMaskStr(highlightingX xIn: Int, y yIn: Int) {
            // Print with positive y upward.
            printMaskStr(getMaskStr(with: [[(xIn, yIn)]]))
        }

        func printMaskStr(with adjacents: CoordLists) {
            printMaskStr(getMaskStr(with: adjacents))
        }
    }

    func abuts(mask: ShapeMask, edgeIndex: Int, x: Int, y: Int) -> Bool {
        // Adjacency test is complicated by rounding to nearest integer coordinates.

        // Verify that the point lies outside the mask.
        if mask.contains(x: x, y: y) {
            return false
        }
        // Verify that at least one adjacent point lies inside the mask.
        // Why 3?  My analytical technique is weak, and visual inspection of
        // mask vs. adjacency shows that some trailing edge adjacent points are
        // this far from the mask edge.
        let orthoRadius = (-3...3)
        for dx in orthoRadius {
            for dy in orthoRadius {
                if mask.contains(x: x + dx, y: y + dy) {
                    return true
                }
            }
        }
        mask.printMaskStr(highlightingX: x, y: y)
        return false
    }

    func testAdjacentsAreNearest() throws {
        let shape = foilShape()
        let mask = ShapeMask(shape: shape)

        let adjCoords = ShapeAdjacentCoords(shape: shape)
        var hadFailures = false
        for iEdge in 0..<adjCoords.adjacents.count {
            let edgePoints = adjCoords.adjacents[iEdge]
            for point in edgePoints {
                // Integer rounding makes this more difficult...
                // Can one step one pixel vertically, horizontally, or diagonally
                // to a point that lies inside the shape?
                let abuts = abuts(
                    mask: mask, edgeIndex: iEdge, x: point.0, y: point.1)
                XCTAssertTrue(abuts, "\(point)")
                if !abuts {
                    hadFailures = true
                }
            }
        }
        if hadFailures {
            mask.printMaskStr(with: adjCoords.adjacents)
        }
    }
}
