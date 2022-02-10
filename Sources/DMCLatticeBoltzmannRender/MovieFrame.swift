import AppKit
import DMCLatticeBoltzmann
import Foundation

/// Make images (movie frames) of a `Lattice` fluid flow simulation.
public struct MovieFrame {
    let lattice: Lattice
    let foil: AirFoil
    let imgWidth: Double
    let imgHeight: Double
    let scale: Double

    let title: String

    private let nodeRects: [[NSRect]]

    /// Create a new image (movie frame) generator.
    /// - Parameters:
    ///   - lattice: lattice whose state is to be depicted
    ///   - foil: airfoil around which the lattice is simulating flow
    ///   - width: desired width of movie frames, in pixels
    ///   - height: desired height of movie frames, in pixels
    ///   - title: the title to be displayed in the legend of each image
    public init(
        lattice: Lattice, foil: AirFoil, width: Int, height: Int, title: String
    ) {
        self.lattice = lattice
        self.foil = foil
        // Expedient: assume the lattice has same aspect ratio as width/height
        imgWidth = Double(width)
        imgHeight = Double(height)
        self.title = title
        let scale = imgWidth / Double(lattice.width)
        self.scale = scale
        nodeRects = Self.initNodeRects(lattice: lattice, scale: scale)
    }

    private static func initNodeRects(lattice: Lattice, scale: Double)
        -> [[NSRect]]
    {
        (0..<lattice.width).map { x in
            let xDisplay = Double(x) * scale
            let column: [NSRect] = (0..<lattice.height).map { y in
                let yDisplay = Double(y) * scale
                return NSRect(
                    x: xDisplay, y: yDisplay, width: scale, height: scale)
            }
            return column
        }
    }

    /// Create an image showing the current state of self's `Lattice`.
    ///
    /// `alpha` can be used for fade-in/fade-out effects.  A value of 0 results in a solid black, "faded out," image.
    /// A value of 1 results in a normal, "faded in," depiction of the world.
    ///
    /// - Parameter alpha: the opacity of the depiction over a black background
    /// - Returns: an image depicting the current lattice state
    public func createFrame(alpha: Double = 1.0) -> NSImage {
        let size = NSSize(width: imgWidth, height: imgHeight)

        let renderer = FrameRenderer(
            title: title, alpha: alpha, scale: scale, lattice: lattice,
            foil: foil, nodeRects: nodeRects, normalizedDensity: getNormalizer()
        )

        return NSImage(size: size, flipped: false) { rect in
            renderer.draw(rect)
            return true
        }
    }

    private func getNormalizer() -> NormalizeFN {
        // Collect lattice density information, if it has not
        // already been collected.
        var (minVal, maxVal) = lattice.getDensityRange()
        let dVal = maxVal - minVal
        var denom = 1.0
        if dVal > 0.0 {
            let inset = 0.05 * dVal
            minVal += inset
            maxVal -= inset
            denom = maxVal - minVal
        }

        func normalizer(rho density: Double) -> Double {
            let clipped = min(maxVal, max(minVal, density))
            let result = (clipped - minVal) / denom
            return result
        }
        return normalizer
    }
}
