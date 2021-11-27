import Foundation

public class Tracer {
    private let x0: Double
    private let y0: Double

    public private(set) var x: Double
    public private(set) var y: Double

    public init(x: Double, y: Double) {
        self.x0 = x
        self.y0 = y
        self.x = x
        self.y = y
    }

    func wholePos() -> (x: Int, y: Int) {
        return (x: Int(x + 0.5), y: Int(y + 0.5))
    }

    func move(
        v: Vector, boundingXMin xMin: Double, yMin: Double, xMax: Double,
        yMax: Double
    ) {
        move(dx: v.x, dy: v.y, boundingXMin: xMin, yMin: yMin, xMax: xMax, yMax: yMax)
    }

    func move(
        dx: Double, dy: Double, boundingXMin xMin: Double, yMin: Double, xMax: Double,
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
