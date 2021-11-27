import Foundation

/// ShapeAdjacentSites records coordinates that are adjacent to the
/// sides of a shape.  This information can be used to extract aggregate properties along
/// a shape's boundaries – e.g., the aggregate pressure along each edge of an airfoil polygon.
public struct ShapeAdjacentCoords {
    struct ShapeCoord: Hashable {
        let x: Int
        let y: Int
    }
    public typealias Coord = (Int, Int)

    public let adjacents: [[Coord]]

    init(shape: Polygon) {
        adjacents = (0..<shape.edges.count).map { i in
            let edge = shape.edges[i]
            let normal = shape.edgeNormals[i]
            return Self.getAdjacentCoords(
                shape: shape, edge: edge, normal: normal)
        }
    }

    internal static func getAdjacentCoords(
        shape: Polygon, edge: Polygon.Segment, normal: Vector
    ) -> [Coord] {
        // TODO Use Bresenham's algorithm.
        let dx = edge.pf.x - edge.p0.x
        let dy = edge.pf.y - edge.p0.y
        // Step along the axis which has the larger span - avoid pixellation gaps.
        if abs(dx) < abs(dy) {
            return getAdjacentCoordsAlongY(
                shape: shape, edge: edge, normal: normal)
        }
        return getAdjacentCoordsAlongX(shape: shape, edge: edge, normal: normal)
    }

    internal static func getAdjacentCoordsAlongY(
        shape: Polygon, edge: Polygon.Segment, normal: Vector
    ) -> [Coord] {
        let n = normal.unit().scaled(0.5)
        let p0 = Vector(edge.p0).adding(n)
        let pf = Vector(edge.pf).adding(n)

        let y0 = p0.y
        let yf = pf.y
        let dy = yf - y0

        let x0 = p0.x
        let xf = pf.x
        let dx = xf - x0

        let step = (dy < 0.0) ? -1.0 : 1.0
        let points: [ShapeCoord] = stride(from: y0, through: yf, by: step)
            .compactMap { y in
                let x = x0 + dx * (y - y0) / dy
                let ix = Int(round(x))
                let iy = Int(round(y))
                // What to do when the computed point lies inside shape?
                if !shape.contains(x: ix, y: iy) {
                    return ShapeCoord(x: ix, y: iy)
                }
                return nil
            }
        let result = Set(points).map { sc in (sc.x, sc.y) }
        return result
    }

    internal static func getAdjacentCoordsAlongX(
        shape: Polygon, edge: Polygon.Segment, normal: Vector
    ) -> [Coord] {
        let n = normal.unit().scaled(0.5)
        let p0 = Vector(edge.p0).adding(n)
        let pf = Vector(edge.pf).adding(n)

        let y0 = p0.y
        let yf = pf.y
        let dy = yf - y0

        let x0 = p0.x
        let xf = pf.x
        let dx = xf - x0

        let step = (dx < 0.0) ? -1.0 : 1.0
        let points: [ShapeCoord] = stride(from: x0, through: xf, by: step)
            .compactMap { x in
                let y = y0 + dy * (x - x0) / dx
                let ix = Int(round(x))
                let iy = Int(round(y))
                // What to do when the computed point lies inside shape?
                if !shape.contains(x: ix, y: iy) {
                    return ShapeCoord(x: ix, y: iy)
                }
                return nil
            }
        let result = Set(points).map { sc in (sc.x, sc.y) }
        return result
    }
}
