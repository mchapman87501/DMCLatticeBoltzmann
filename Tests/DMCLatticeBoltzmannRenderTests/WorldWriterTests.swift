import XCTest

@testable import DMCLatticeBoltzmann
@testable import DMCLatticeBoltzmannRender
@testable import DMCMovieWriter

class WorldWriterTests: XCTestCase {
    private let movieURL = URL(fileURLWithPath: "movie.mov")

    override func tearDownWithError() throws {
        let fm = FileManager.default
        if fm.fileExists(atPath: movieURL.path) {
            try fm.removeItem(at: movieURL)
        }
    }

    func testWorldWriter() throws {
        let foil = AirFoil(
            x: 0.0, y: 0.0, width: 5.0, alphaRad: 10.0 * .pi / 180.0)
        let lattice = Lattice(width: 8, height: 6, windSpeed: 30.0)!

        let movieWidth = 40 * lattice.width
        let movieHeight = 40 * lattice.height
        guard
            let movieWriter = try? DMCMovieWriter(
                outpath: movieURL, width: movieWidth, height: movieHeight)
        else {
            XCTFail("Could not create movie writer.")
            return
        }
        guard
            let writer = try? WorldWriter(
                lattice: lattice, foil: foil, writingTo: movieWriter)
        else {
            XCTFail("Could not create world writer.")
            return
        }

        try writer.showTitle("Your Title Here")

        for _ in 0..<32 {
            lattice.step()
            try writer.writeNextFrame()
        }

        let frameWidth = Double(movieWidth) / 2.0
        let frameHeight = Double(movieHeight) / 2.0
        let frameImage = writer.getCurrFrame(width: frameWidth)
        XCTAssertEqual(frameImage.size.width, frameWidth)
        XCTAssertEqual(frameImage.size.height, frameHeight)

        try movieWriter.finish()
        let moviePath = movieURL.path
        let fm = FileManager.default
        XCTAssert(
            fm.fileExists(atPath: moviePath), "No such file: \(moviePath)")

        let attrs = try fm.attributesOfItem(atPath: moviePath)
        let fileSize = (attrs[.size]! as? Int) ?? -1
        XCTAssertTrue(fileSize > 0)
    }
}
