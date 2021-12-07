import XCTest

@testable import DMCLatticeBoltzmann

final class LatticeIndexingTests: XCTestCase {
    func testSiteIndex() throws {
        let width = 10
        let height = 10
        let indexer = LatticeIndexing(width: width, height: height)

        XCTAssertThrowsError(try indexer.siteIndex(x: -1, y: 0))
        XCTAssertThrowsError(try indexer.siteIndex(x: 0, y: -1))
        XCTAssertThrowsError(try indexer.siteIndex(x: width, y: 0))
        XCTAssertThrowsError(try indexer.siteIndex(x: 0, y: height))

        let numSiteCells = 9
        for (x, y) in [
            (0, 0),
            (width - 1, height - 1),
            (width / 2, height / 2),
            (width - 1, height / 2),
            (width / 2, height - 1),
            (1, height / 2),
            (width / 2, 1),
        ] {
            let actual = try indexer.siteIndex(x: x, y: y)
            let expected = (y * width + x) * numSiteCells
            XCTAssertEqual(
                actual, expected,
                "(\(x), \(y)) = \(actual) vs. expected \(expected)")
        }
    }
}
