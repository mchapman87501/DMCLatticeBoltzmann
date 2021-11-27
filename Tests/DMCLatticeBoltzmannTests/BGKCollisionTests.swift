import XCTest

@testable import DMCLatticeBoltzmann

final class BGKCollisionTests: XCTestCase {
    // XXX FIX THIS these tests are all very superficial and weak

    func testDirection(direction: Int, windSpeed: Double) throws {
        let width = 5
        let height = 2
        var n = LatticeNodeData.allocate(
            capacity: numDirections * width * height)
        // Initialize nodes to equilibrium condition for given wind-from-west.
        Lattice.initNodeArray(
            n: &n, width: width, height: height, windSpeed: windSpeed)

        let propCalc = LatticePropertyCalc(n: n, width: width, height: height)
        let offset = 0
        let props = propCalc.getNodeProperties(offset: offset)
        let equil = BGKCollision.getFEq(
            direction: direction, siteProps: props, dvix: dvx[direction],
            dviy: dvy[direction])
        // Zero wind.  equilibrium density should match current density?
        XCTAssertEqual(n[offset + direction], Float(equil), accuracy: 1.0e-7)
    }

    func testNoWind() throws {
        for direction in 0..<numDirections {
            try testDirection(direction: direction, windSpeed: 0.0)
        }
    }

    func testWithWind() throws {
        // Always directed to the east, from the west:
        for direction in 0..<numDirections {
            try testDirection(direction: direction, windSpeed: 0.1)
        }
    }
}
