import Foundation

/// Represents a tracer object that flows through a ``Lattice`` in accordance with macroscopic lattice site velocities.
public class Tracer {
    private let x0: Double
    private let y0: Double

    /// x coordinate of the tracer within a ``Lattice``
    public private(set) var x: Double
    /// y coordinate of the tracer within a ``Lattice``
    public private(set) var y: Double

    /// Create a new tracer object at the specified ``Lattice`` site.
    /// - Parameters:
    ///   - x: initial x coordinate of the tracer within a ``Lattice``
    ///   - y: initial y coordinate of the tracer within a ``Lattice``
    public init(x: Double, y: Double) {
        self.x0 = x
        self.y0 = y
        self.x = x
        self.y = y
    }

    func wholePos() -> (x: Int, y: Int) {
        (x: Int(x + 0.5), y: Int(y + 0.5))
    }

    func move(
        dx: Double, dy: Double, boundingXMin xMin: Double, yMin: Double,
        xMax: Double,
        yMax: Double
    ) {
        x += dx
        y += dy

        if x < xMin {
            x = xMin
        } else if x > xMax {
            // Recycle -- assumes everything flows toward +x
            x = xMin
            y = y0
        }

        if y < yMin {
            y = yMin
        } else if y > yMax {
            y = yMax
        }
    }
}
