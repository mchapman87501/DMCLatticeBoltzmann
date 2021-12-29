import DMC2D
import Foundation

// Airfoil coordinates are of a NACA2412-il foil.  Coordinates were derived
// from the CSV download link at
// http://airfoiltools.com/plotter/index?airfoil=naca2412-il
public struct AirFoil {
    public let shape: Polygon

    public init(
        x left: Double, y bottom: Double, width: Double, alphaRad: Double
    ) {
        // NACA2412
        // Coordinates were generated w. the algorithm detailed at
        // http://airfoiltools.com/airfoil/naca4digit
        // as implemented by https://github.com/mchapman87501/naca_4_digit_airfoils
        // Some points near the trailing edge were manually removed.
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
