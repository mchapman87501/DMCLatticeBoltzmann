import XCTest

@testable import DMCLatticeBoltzmann

typealias Polygon = DMCLatticeBoltzmann.Polygon

extension Polygon.Segment {
    func midpoint() -> Vector {
        let xMid = (p0.x + pf.x) / 2.0
        let yMid = (p0.y + pf.y) / 2.0
        return Vector(x: xMid, y: yMid)
    }
}

final class EdgePressureCalcTests: XCTestCase {
    func testEPC() throws {
        let width = 16
        let height = 12
        let lattice = Lattice(width: width, height: height, windSpeed: 20.0)!
        let propCalc = LatticePropertyCalc(
            n: lattice.n, width: lattice.width, height: lattice.height)
        let foil = AirFoil(
            x: Double(width) / 3.0, y: Double(height) / 3.0,
            width: Double(width) / 3.0, alphaRad: 0.0)
        let shape = foil.shape

        lattice.addObstacle(shape: shape)
        let calc = EdgePressureCalc(propCalc: propCalc, shape: shape)

        let numEdges = shape.edges.count
        XCTAssertEqual(calc.edgeMidpoints.count, numEdges)
        XCTAssertEqual(calc.edgePressureVectors.count, numEdges)
        XCTAssertEqual(calc.edgePressures.count, numEdges)

        for i in 0..<numEdges {
            let shapeMidpoint = shape.edges[i].midpoint()
            XCTAssertEqual(shapeMidpoint, calc.edgeMidpoints[i])

            XCTAssertGreaterThanOrEqual(calc.edgePressures[i], 0.0)
            if calc.edgePressures[i] > 0.0 {
                XCTAssertGreaterThan(
                    calc.edgePressureVectors[i].magnitude(), 0.0)
            }
        }
    }
}
