import XCTest

@testable import DMCLatticeBoltzmann

class VectorTests: XCTestCase {

    func testZeroUnit() throws {
        let zeroUnit = Vector().unit()
        XCTAssertEqual(zeroUnit.magnitude(), 0.0)
    }

    func testAngle() throws {
        for degrees in [
            0.0, 10.0, 30.0, 45.0, 90.0, 132.3, 245.0, 281.3, 301.4,
        ] {
            let rads = degrees * .pi / 180.0
            let r = 3.1
            let vx = r * cos(rads)
            let vy = r * sin(rads)

            let vec = Vector(x: vx, y: vy)
            XCTAssertEqual(vec.magnitude(), r)

            let vAngle = vec.angle()
            let actual = (vAngle < 0.0) ? vAngle + (2.0 * .pi) : vAngle
            XCTAssertEqual(actual, rads, accuracy: 1.0e-12)
        }
    }

    func testCGPoint() throws {
        let vx = -7.0
        let vy = 1.2
        let vec = Vector(x: vx, y: vy)
        let point = CGPoint(vec)
        XCTAssertEqual(point.x, vx)
        XCTAssertEqual(point.y, vy)
    }
}
