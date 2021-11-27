import Foundation

public struct Vector: Equatable {
    public let x: Double
    public let y: Double

    public func magSqr() -> Double {
        return x * x + y * y
    }

    public func magnitude() -> Double {
        return sqrt(magSqr())
    }

    public func unit() -> Vector {
        let ms = magSqr()
        if ms > 0.0 {
            let mag = sqrt(ms)
            return Vector(x: x / mag, y: y / mag)
        }
        return Vector(x: 0.0, y: 0.0)
    }

    public func normal() -> Vector {
        return Vector(x: -y, y: x)
    }

    public func angle() -> Double {
        return atan2(self.y, self.x)
    }

    public func adding(_ offset: Vector) -> Vector {
        return Vector(x: offset.x + self.x, y: offset.y + self.y)
    }

    public func scaled(_ s: Double) -> Vector {
        return Vector(x: self.x * s, y: self.y * s)
    }

}

extension Vector {
    public init() {
        x = 0.0
        y = 0.0
    }

    public init(_ p: CGPoint) {
        self.init(x: Double(p.x), y: Double(p.y))
    }
}

extension CGPoint {
    public init(_ v: Vector) {
        self.init(x: v.x, y: v.y)
    }
}
