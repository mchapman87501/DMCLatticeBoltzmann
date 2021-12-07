import XCTest

#if !canImport(ObjectiveC)
    public func allTests() -> [XCTestCaseEntry] {
        return [
            testCase(MovieFrameTests.allTests),
            testCase(PalettesTests.allTests),
            testCase(WorldWriterTests.allTests),
        ]
    }
#endif
