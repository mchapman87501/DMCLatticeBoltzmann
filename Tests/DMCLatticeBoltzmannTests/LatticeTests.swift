import XCTest

@testable import DMC2D
@testable import DMCLatticeBoltzmann

extension Lattice {
    internal func testingGetProperties() -> SystemProperties {
        propCalc.getProperties()
    }

    internal func testingGetNodeProperties(x: Int, y: Int) throws
        -> NodeProperties
    {
        try propCalc.getNodeProperties(x: x, y: y)
    }

    internal func testingSetNodeDensities(x: Int, y: Int, values: [Double])
        throws
    {
        guard values.count == numDirections else {
            throw LatticeError.valueError(
                "Number of node densities must be \(numDirections)")
        }
        let siteIndex = try index.siteIndex(x: x, y: y)
        let nodeIndex = index.maskIndex(x: x, y: y)
        if !(isObstacle[nodeIndex] || isBoundary[nodeIndex]) {
            for i in 0..<numDirections {
                n[siteIndex + i] = Float(values[i])
            }
        }
    }

    internal func testingGetNodeDensities(x: Int, y: Int) throws -> [Double] {
        let offset = try index.siteIndex(x: x, y: y)
        let iStart = offset
        let iEnd = offset + numDirections
        return (iStart..<iEnd).map { i in Double(n[i]) }
    }

    internal func testingDensities() -> [[Double]] {
        var result = [[Double]]()
        var index = 0
        for _ in 0..<height {
            var currRow = [Double](repeating: 0.0, count: width)
            for x in 0..<width {
                currRow[x] = propCalc.getNodeProperties(offset: index).rho
                index += numDirections
            }
            result.append(currRow)
        }
        return result
    }
}

final class LatticeTests: XCTestCase {
    private typealias Polygon = DMC2D.Polygon

    private func magSqr(x: Double, y: Double) -> Double {
        x * x + y * y
    }

    func testInit() throws {
        let lat = Lattice(width: 10, height: 5, omega: 0.5)
        XCTAssertNotNil(lat)
    }

    func testInitBadOmega() throws {
        let lat = Lattice(width: 5, height: 7, omega: 2.1)
        XCTAssertNil(lat)
    }

    func testGetProperties() throws {
        let lat = Lattice(width: 10, height: 10)!
        let props = lat.testingGetProperties()
        XCTAssertEqual(props.rho, 1.0, accuracy: 1.0e-6)
    }

    func testGetNodeProperties() throws {
        let width = 5
        let height = 5
        let lat = Lattice(width: width, height: height)!
        for y in 0..<height {
            for x in 0..<width {
                let props = try lat.testingGetNodeProperties(x: x, y: y)
                XCTAssertEqual(
                    props.rho, 1.0, accuracy: 1.0e-6, "Node[\(x), \(y)]")
            }
        }
    }

    func testCollide() throws {
        let lat = Lattice(width: 5, height: 5, windSpeed: 0.1)!
        let before = lat.testingGetProperties()
        lat.collide()
        let after = lat.testingGetProperties()
        // Overall density and momentum must be preserved.
        XCTAssertEqual(before.rho, after.rho, accuracy: 1.0e-5)
        let uBefore = magSqr(x: before.ux, y: before.uy)
        let uAfter = magSqr(x: after.ux, y: after.uy)
        XCTAssertEqual(uBefore, uAfter, accuracy: 1.0e-5)
    }

    func testCollideObstacle() throws {
        // TODO verify that an obstacle node simply "reflects" its field densities during
        // collision.
    }

    func testStreamCenter() throws {
        let width = 3
        let height = 3
        let lat = Lattice(width: width, height: height)!
        var i = 0
        for y in 0..<height {
            for x in 0..<width {
                try lat.testingSetNodeDensities(
                    x: x, y: y,
                    values: [Double(i), 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0])
                i += 1
            }
        }
        lat.stream()
        i = 0
        for y in 0..<height {
            for x in 0..<width {
                let actual = try lat.testingGetNodeDensities(x: x, y: y)
                XCTAssertEqual(
                    actual, [Double(i), 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0])
                i += 1
            }
        }
    }

    private func testStreamOneDirection(dir: Direction) throws {
        let dirIndex = dir.rawValue
        let width = 4
        let height = 4

        // Fill the lattice with 1 in flow direction site, 0 elsewhere.
        let lat = Lattice(width: width, height: height)!
        var i = 0
        for y in 0..<height {
            for x in 0..<width {
                var dens = [Double](repeating: 0.0, count: numDirections)
                dens[dirIndex] = Double(i)
                try lat.testingSetNodeDensities(x: x, y: y, values: dens)
                i += 1
            }
        }

        struct Locus: Hashable {
            let x: Int
            let y: Int
        }
        typealias NodeDensities = [Locus: [Double]]

        func getDensities(_ lat: Lattice) throws -> NodeDensities {
            var result = [Locus: [Double]]()
            for x in 0..<lat.width {
                for y in 0..<lat.height {
                    result[Locus(x: x, y: y)] = try lat.testingGetNodeDensities(
                        x: x, y: y)
                }
            }
            return result
        }

        let before = try getDensities(lat)
        lat.stream()
        let after = try getDensities(lat)

        if dirIndex == 0 {
            // There should be no motion.
            XCTAssertEqual(before, after)
            return
        }

        XCTAssertNotEqual(before, after)
        for (k, vAfter) in after {
            // Verify non-flow-direction values are zero.
            for rawDir in 0..<numDirections {
                if rawDir != dirIndex {
                    XCTAssertEqual(vAfter[rawDir], 0.0)
                }
            }

            // vAfter value should have streamed in from where?
            let x = k.x
            let y = k.y
            let dx = Int(dvx[dirIndex])
            let dy = Int(dvy[dirIndex])
            var xSrc = x - dx
            if xSrc < 0 {
                xSrc += lat.width
            } else if xSrc >= lat.width {
                xSrc -= lat.width
            }
            var ySrc = y - dy
            if ySrc < 0 {
                ySrc += lat.height
            } else if ySrc >= lat.height {
                ySrc -= lat.height
            }

            let srcValues = before[Locus(x: xSrc, y: ySrc)]!
            let expected = srcValues[dirIndex]
            let actual = vAfter[dirIndex]
            if expected != actual {
                XCTFail(
                    "Direction \(dir) (\(dx), \(dy)): [\(x), \(y)] expected value from old [\(xSrc), \(ySrc)].  But actual \(actual) != expected \(expected)"
                )
            }
        }
    }

    func testStreamAllDirections() throws {
        for direction in Direction.allCases {
            try testStreamOneDirection(dir: direction)
        }
    }

    func testStep() throws {
        let width = 32
        let height = 16
        let lat = Lattice(width: width, height: height, windSpeed: 50.0)!
        var before = [[NodeProperties]]()
        for iy in 0..<height {
            var row = [NodeProperties]()
            for ix in 0..<width {
                let props = try lat.testingGetNodeProperties(x: ix, y: iy)
                row.append(props)
            }
            before.append(row)
        }

        for iStep in 1...300 {
            lat.step()
            // This is a useless test.  rho can change as "wind" is added at the "tunnel entrance"
            // on each step.
            for ix in 0..<width {
                for iy in 0..<height {
                    let currProp = try lat.testingGetNodeProperties(
                        x: ix, y: iy)
                    let beforeProp = before[iy][ix]
                    XCTAssertTrue(
                        beforeProp.rho <= currProp.rho,
                        "Step \(iStep), [\(iy), \(ix)]")
                    let uMagSqr = magSqr(x: currProp.ux, y: currProp.uy)
                    XCTAssertTrue(
                        uMagSqr > 0.0, "Step \(iStep), [\(iy), \(ix)]")
                }
            }
        }
    }

    func testAddObstacleOutOfBounds() throws {
        let width = 32
        let height = 24
        let lat = Lattice(width: width, height: height, windSpeed: 0.0)!

        let yOOB = Double(height) + 1
        let outOfBounds = Polygon([
            (0.0, yOOB), (5.0, yOOB), (5.0, yOOB + 4.0), (0.0, yOOB + 4.0),
        ])
        lat.addObstacle(shape: outOfBounds)
        for iy in 0..<height {
            let rowOffset = iy * width
            for ix in 0..<width {
                XCTAssertFalse(lat.isObstacle[rowOffset + ix])
            }
        }
    }

    func testAddObstacleInBounds() throws {
        let width = 32
        let height = 24
        let lat = Lattice(width: width, height: height, windSpeed: 0.0)!

        let extent = 2.0
        let x = Double(width) / 2.0
        let y = Double(height) / 2.0
        let shape = Polygon([
            (x - extent, y - extent), (x + extent, y - extent),
            (x + extent, y + extent), (x - extent, y + extent),
        ])
        lat.addObstacle(shape: shape)
        let numObstacleNodes = (lat.isObstacle.map { $0 ? 1 : 0 }).reduce(0) {
            $0 + $1
        }
        XCTAssertEqual(numObstacleNodes, 4 * Int(extent * extent))
    }

    func testWithObstacle() throws {
        // XXX FIX THIS dimensions reflect knowledge of tracer spacing
        // within lattice
        let width = 32
        let height = 24
        let lat = Lattice(width: width, height: height, windSpeed: 50.0)!
        let brick = Polygon([
            (1.0, 15.0), (5.0, 15.0), (5.0, 18.0), (1.0, 18.0),
        ])
        lat.addObstacle(shape: brick)

        var before = [[NodeProperties]]()
        for iy in 0..<height {
            var row = [NodeProperties]()
            for ix in 0..<width {
                let props = try lat.testingGetNodeProperties(x: ix, y: iy)
                row.append(props)
            }
            before.append(row)
        }

        // No density comparison vs. old state?
        // TODO understand how boundaries can affect densities of
        // adjacent sites.
        for iStep in 1...100 {
            lat.step()
            for ix in 0..<width {
                for iy in 0..<height {
                    let currProp = try lat.testingGetNodeProperties(
                        x: ix, y: iy)
                    XCTAssertGreaterThan(
                        currProp.rho, 0.0, "Step \(iStep), [\(iy), \(ix)]")
                }
            }
        }
    }

    func testWithBoundaries() throws {
        let width = 32
        let height = 24
        let lat = Lattice(width: width, height: height, windSpeed: 50.0)!
        try lat.setBoundaryEdge(x: 0)
        try lat.setBoundaryEdge(y: 0)

        var before = [[NodeProperties]]()
        for iy in 0..<height {
            var row = [NodeProperties]()
            for ix in 0..<width {
                let props = try lat.testingGetNodeProperties(x: ix, y: iy)
                row.append(props)
            }
            before.append(row)
        }

        for iStep in 1...100 {
            lat.step()
            for ix in 0..<width {
                for iy in 0..<height {
                    let currProp = try lat.testingGetNodeProperties(
                        x: ix, y: iy)
                    XCTAssertGreaterThan(
                        currProp.rho, 0.0, "Step \(iStep), [\(iy), \(ix)]")
                }
            }
        }
    }

    func testSetBoundaries() throws {
        let width = 32
        let height = 24
        let lat = Lattice(width: width, height: height, windSpeed: 50.0)!
        XCTAssertThrowsError(try lat.setBoundaryEdge(x: -5))
        XCTAssertThrowsError(try lat.setBoundaryEdge(x: width))
        XCTAssertThrowsError(try lat.setBoundaryEdge(y: -1))
        XCTAssertThrowsError(try lat.setBoundaryEdge(y: height))
    }

    func testDensityRange() throws {
        let width = 32
        let height = 24
        let lat = Lattice(width: width, height: height, windSpeed: 50.0)!
        for _ in 1...50 {
            lat.step()
            let (rhoMin, rhoMax) = lat.getDensityRange()
            // More weak tea
            XCTAssertGreaterThanOrEqual(rhoMax, rhoMin)
        }
    }
}
