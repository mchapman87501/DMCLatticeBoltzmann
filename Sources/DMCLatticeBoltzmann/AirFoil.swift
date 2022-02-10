import DMC2D
import Foundation

/// Represents an airfoil as a polygon whose shape can be added, as an obstacle, to a ``Lattice``.
///
/// The coordinates of the polygon are those of a NACA2412 airfoil, similar to the airfoil used by
/// a Cessna 172.  The coordinates were generated using the algorithm detailed at
/// [airfoiltools.com](http://airfoiltools.com/airfoil/naca4digit).  Some points near the
/// trailing edge were removed manually.
public struct AirFoil {
    /// The airfoil's shape
    public let shape: Polygon

    /// Create a new airfoil.
    ///
    /// The foil is rotated to the specified angle of attack, `alphaRad`.  It is scaled to the specified `width` and positioned
    /// with its leftmost point at `left` and its bottom-most point at `bottom`.
    /// - Parameters:
    ///   - left: leftmost point of the foil shape
    ///   - bottom: bottom-most point of the foil shape
    ///   - width: total width of the foil shape
    ///   - alphaRad: angle of attack of the foil shape, in radians
    public init(
        x left: Double, y bottom: Double, width: Double, alphaRad: Double
    ) {
        let vertexCoords: [(Double, Double)] = [
            (0.0000, 0.0000),
            (0.0092, 0.0188),
            (0.0403, 0.0373),
            (0.0920, 0.0543),
            (0.1622, 0.0679),
            (0.2478, 0.0766),
            (0.3447, 0.0792),
            (0.4480, 0.0758),
            (0.5531, 0.0681),
            (0.6557, 0.0573),
            (0.7512, 0.0448),
            (0.8356, 0.0318),
            (0.9053, 0.0198),

            (1.0001, 0.0013),

            (0.9037, -0.0080),
            (0.8335, -0.0128),
            (0.7488, -0.0184),
            (0.6534, -0.0245),
            (0.5514, -0.0306),
            (0.4474, -0.0360),
            (0.3463, -0.0399),
            (0.2522, -0.0422),
            (0.1686, -0.0417),
            (0.0990, -0.0375),
            (0.0462, -0.0292),
            (0.0126, -0.0166),
        ]

        // Normalize in x.
        let xvals = vertexCoords.map { x, _ in x }
        let ymin = vertexCoords.map { _, y in y }.min()!
        let xmin = xvals.min()!
        let mag = xvals.max()! - xvals.min()!
        let normedCoords = vertexCoords.map {
            x, y in
            (((x - xmin) / mag), ((y - ymin) / mag))
        }

        // Alpha = angle of attack.  Since leading edge is at the origin,
        // rotate clockwise (-alphaRad).
        let cosAlpha = cos(-alphaRad)
        let sinAlpha = sin(-alphaRad)
        let rotatedCoords = normedCoords.map { x, y in
            ((cosAlpha * x - sinAlpha * y), (sinAlpha * x + cosAlpha * y))
        }

        // Scale up so airfoil has the requested width.
        let scaledCoords = rotatedCoords.map {
            x, y in
            ((x * width + left), (y * width + bottom))
        }
        shape = Polygon(scaledCoords)
    }
}
