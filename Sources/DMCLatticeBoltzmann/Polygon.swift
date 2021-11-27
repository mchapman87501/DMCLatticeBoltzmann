import CoreGraphics
import Foundation

public struct Polygon {
    public struct Segment {
        public let p0: CGPoint
        public let pf: CGPoint

        func crossesUpward(_ y: CGFloat) -> Bool {
            return (
                // Upward, non-horizontal edge.
                (p0.y < pf.y)
                // Upward crossing includes segment start,
                // excludes segment end.
                && (p0.y <= y) && (y < pf.y))
        }

        func crossesDownward(_ y: CGFloat) -> Bool {
            return (
                // Downward, non-horizontal edge.
                (p0.y > pf.y)
                // Downward crossing excludes segment start, includes
                // segment end.
                && (pf.y <= y) && (y < p0.y))
        }

        func xIntersect(_ rayOrigin: CGPoint) -> CGFloat {
            // Caller must ensure this is not a horizontal line.
            let dx = pf.x - p0.x
            let dy = pf.y - p0.y
            if abs(dx) < 1.0e-6 {
                let ry = rayOrigin.y
                let (ymin, ymax) = (p0.y < pf.y) ? (p0.y, pf.y) : (pf.y, p0.y)
                // If y is not between p0.y and pf.y?
                // Pretend the intersection is to the left of the ray origin.
                if (ry < ymin) || (ry > ymax) {
                    return rayOrigin.x - 1.0
                }
                // Otherwise the intersection is at the x coord of the
                // vertical line.
                return p0.x
            }
            let dyFract = (rayOrigin.y - p0.y) / dy
            let result = p0.x + dyFract * dx
            return result
        }

        func asVector() -> Vector {
            return Vector(x: Double(pf.x - p0.x), y: Double(pf.y - p0.y))
        }
    }

    public let vertices: [CGPoint]
    private let vertexVectors: [Vector]

    public let edges: [Segment]
    public let edgeNormals: [Vector]
    public let bbox: CGRect
    public let center: CGPoint  // Geometric center, sort of.

    // Find out whether a point lies on or within the boundaries of self.
    // This algorithm avoids a host of boundary conditions:
    // http://geomalgorithms.com/a03-_inclusion.html
    /*
     Edge Crossing Rules

     1. an upward edge includes its starting endpoint, and excludes its final endpoint;

     2. a downward edge excludes its starting endpoint, and includes its final endpoint;

     3. horizontal edges are excluded

     4. the edge-ray intersection point must be strictly right of the point P.

     cn_PnPoly( Point P, Point V[], int n )
     {
         int    cn = 0;    // the  crossing number counter

         // loop through all edges of the polygon
         for (each edge E[i]:V[i]V[i+1] of the polygon) {
             if (E[i] crosses upward ala Rule #1
              || E[i] crosses downward ala  Rule #2) {
                 if (P.x <  x_intersect of E[i] with y=P.y)   // Rule #4
                      ++cn;   // a valid crossing to the right of P.x
             }
         }
         return (cn&1);    // 0 if even (out), and 1 if  odd (in)

     }
     */
    func contains(point: CGPoint) -> Bool {
        if bbox.contains(point) {
            let x0 = point.x
            let y0 = point.y
            var numCrossings = 0
            for edge in edges {
                if edge.crossesUpward(y0) || edge.crossesDownward(y0) {
                    let xIntersect = edge.xIntersect(point)
                    if x0 < xIntersect {
                        numCrossings += 1
                    }
                }
            }
            return 0 != (numCrossings % 2)
        }
        return false
    }

    func contains(x: Double, y: Double) -> Bool {
        return contains(point: CGPoint(x: x, y: y))
    }

    func contains(x: Int, y: Int) -> Bool {
        return contains(x: Double(x), y: Double(y))
    }

    private static func getEdges(_ vertices: [CGPoint]) -> [Segment] {
        let numVertices = vertices.count
        // Assume the polygon is not closed - that its first and last
        // vertices are not the same.
        return (0..<numVertices).map {
            Segment(p0: vertices[$0], pf: vertices[($0 + 1) % numVertices])
        }
    }

    private static func getEdgeNormals(_ edges: [Segment]) -> [Vector] {
        edges.map { edge in
            edge.asVector().normal().unit()
        }
    }
}

extension Polygon {
    public init(_ verticesIn: [CGPoint]) {
        var bb = CGRect(x: 0.0, y: 0.0, width: 0.0, height: 0.0)
        var first = true
        for v in verticesIn {
            if first {
                bb = CGRect(x: v.x, y: v.y, width: 0.0, height: 0.0)
                first = false
            } else {
                bb = bb.union(CGRect(x: v.x, y: v.y, width: 0.0, height: 0.0))
            }
        }

        let xMean =
            verticesIn.map { $0.x }.reduce(0.0, +) / Double(verticesIn.count)
        let yMean =
            verticesIn.map { $0.y }.reduce(0.0, +) / Double(verticesIn.count)

        vertices = verticesIn
        vertexVectors = vertices.map { v in
            Vector(x: Double(v.x), y: Double(v.y))
        }
        edges = Polygon.getEdges(verticesIn)
        edgeNormals = Polygon.getEdgeNormals(edges)
        bbox = bb
        center = CGPoint(x: xMean, y: yMean)
    }

    public init(_ verticesIn: [(Double, Double)]) {
        self.init(verticesIn.map { CGPoint(x: $0, y: $1) })
    }
}
