import XCTest

#if !canImport(ObjectiveC)
    public func allTests() -> [XCTestCaseEntry] {
        [
            testCase(MovieFrameTests.allTests),
            testCase(PalettesTests.allTests),
            testCase(WorldWriterTests.allTests),
        ]
    }
#endif
