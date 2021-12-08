import DMC2D
import Foundation

/// EdgePressureCalc aggregates pressure (okay, density) info around a shape.
public struct EdgePressureCalc {
    public let edgeMidpoints: [Vector]
    public let edgePressures: [Double]
    public let edgePressureVectors: [Vector]
    public let netPressure: Vector

    public init(propCalc: LatticePropertyCalc, shape: Polygon) {
        let adjCoords = ShapeAdjacentCoords(shape: shape).adjacents

        let edgePressures: [Double] = adjCoords.enumerated().map {
            (iEdge, edgeAdjCoords) in
            var result = 0.0
            let numCoords = edgeAdjCoords.count
            if numCoords <= 0 {
                return result
            }

            for (latticeX, latticeY) in edgeAdjCoords {
                if let props = try? propCalc.getNodeProperties(
                    x: latticeX, y: latticeY)
                {
                    // Does it matter that the node has, not just a density, but a net flow velocity?
                    result += props.rho
                }
            }
            // Voodoo: average density over # samples, multiply by segment length.
            result =
                (result / Double(numCoords))
                * shape.edges[iEdge].asVector().magnitude()
            return result
        }

        let edgeMidpoints: [Vector] = shape.edges.map { edge in
            let xMid = (edge.p0.x + edge.pf.x) / 2.0
            let yMid = (edge.p0.y + edge.pf.y) / 2.0
            return Vector(x: xMid, y: yMid)
        }
        let edgePressureVectors = (0..<shape.edges.count).map { edgeIndex in
            // Pressure vectors point inward -- opposite to the edge normals
            return shape.edgeNormals[edgeIndex] * -edgePressures[edgeIndex]
        }

        var netPressure = Vector()
        for ep in edgePressureVectors {
            netPressure += ep
        }

        self.edgeMidpoints = edgeMidpoints
        self.edgePressures = edgePressures
        self.edgePressureVectors = edgePressureVectors
        self.netPressure = netPressure
    }
}
