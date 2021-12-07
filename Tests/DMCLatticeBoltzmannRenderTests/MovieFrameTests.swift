import XCTest

@testable import DMCLatticeBoltzmann
@testable import DMCLatticeBoltzmannRender

class MovieFrameTests: XCTestCase {
    func testSingleFrame() throws {
        let width = 128.0
        let height = 72.0
        let lattice = Lattice(
            width: Int(width), height: Int(height), windSpeed: 40.0)!
        let foil = AirFoil(
            x: width / 4.0, y: height / 2.0, width: width / 2.75,
            alphaRad: 4.0 * .pi / 180.0)
        lattice.addObstacle(shape: foil.shape)

        let framer = MovieFrame(
            lattice: lattice, foil: foil, width: Int(width * 10.0),
            height: Int(height * 10.0), title: "")
        let image = framer.createFrame()
        if let imageData = image.tiffRepresentation {
            let bitmapRep = NSBitmapImageRep(data: imageData)
            XCTAssertNotNil(bitmapRep)
        }
        lattice.step()
        let framer2 = MovieFrame(
            lattice: lattice, foil: foil, width: Int(width * 10.0),
            height: Int(height * 10.0), title: "After One Step")
        let image2 = framer2.createFrame()
        if let imageData2 = image2.tiffRepresentation {
            let bitmapRep = NSBitmapImageRep(data: imageData2)
            XCTAssertNotNil(bitmapRep)
        }
    }
}
