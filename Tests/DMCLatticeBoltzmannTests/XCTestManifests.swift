import XCTest

#if !canImport(ObjectiveC)
    public func allTests() -> [XCTestCaseEntry] {
        return [
            testCase(BGKCollisionTests.allTests),
            testCase(EdgePressureCalcTests.allTests),
            testCase(LatticeIndexingTests.allTests),
            testCase(LatticeTests.allTests),
            testCase(ShapeAdjacentCoordsTests.allTests),
            testCase(VectorTests.allTests),
        ]
    }
#endif
