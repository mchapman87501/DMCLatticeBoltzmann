import Foundation
import simd

// Lattice Node Vectors - elements are in the same order as Direction.
// TODO Factor to a separate source file.
public let idvx = [0, 0, 1, 1, 1, 0, -1, -1, -1]
public let idvy = [0, 1, 1, 0, -1, -1, -1, 0, 1]

public let dvx = idvx.map { Double($0) }
public let fdvx = idvx.map { Float($0) }

public let dvy = idvy.map { Double($0) }
public let fdvy = idvy.map { Float($0) }

public typealias LatticeNodeData = UnsafeMutablePointer<Float>
public typealias LatticeMaskData = [Bool]

public class Lattice {
    public let width: Int
    public let height: Int
    let omega: Double

    public private(set) var n: LatticeNodeData
    private var nStream: LatticeNodeData

    public private(set) var isObstacle: LatticeMaskData
    public private(set) var isBoundary: LatticeMaskData

    public private(set) var tracers: [Tracer]

    // "internal": to support unit testing
    internal let index: LatticeIndexing
    internal var propCalc: LatticePropertyCalc

    private let concurrency = ProcessInfo.processInfo.activeProcessorCount
    private let queue = DispatchQueue(
        label: "lattice steps", qos: .utility, attributes: .concurrent)
    private let group = DispatchGroup()

    public init?(
        width: Int, height: Int, omega: Double = 0.5,
        temperature: Double = 20.0, windSpeed: Double = 0.0
    ) {
        guard (0 < width) && (0 < height) else {
            NSLog("Lattice must have width and height > 0")
            return nil
        }
        guard (0.0 <= omega) && (omega <= 2.0) else {
            NSLog("Lattice init: Omega must be in 0.0 ... 2.0")
            return nil
        }
        self.width = width
        self.height = height
        self.omega = omega
        // Thermal velocity v varies as the square root of temperature.
        // T = K * v**2
        // If I remember correctly, using Boltzmann's equations, at 20°C v should
        // be about 400 m/s.
        // 20 = K * (400 * 400)
        let K = 1.0 / 8000.0
        let thermalSpeed = sqrt(temperature / K)
        
        // The lattice spacing and simulation time steps are scaled
        // so that lattice discrete speeds are <= 1.
        // That is, maximum lattice spacing ∆x and simulation time step ∆t are chosen so that
        // c = ∆x/∆t = 1.
        // Absent wind, the thermal velocity v = dx/dt needs to be scaled by
        // some constant K2 so that c = 1 = K2 * v.
        // Similarly, in the presence of wind velocity u, c = 1 = K2 * (v + u)
        // Hm... but it also needs to be scaled so that the maximum lattice speed component
        // in initNodeDensities, i.e., 1.0 + 3.0 * u + 3.0 * uSqr
        // is <= 1.414?
        // 3.0 * u**2 + 3.0*u + 1.0 <= sqrt(2)
        // u = sqrt(sqrt(2) + 1.25) - 1.5
        // scale2 = u / windSpeed
        // So... use a fudge factor to hide my incorrect reasoning...
        let K2 = 1.0 / (1.6 * (thermalSpeed + windSpeed))
        
        let scaledWindSpeed = K2 * windSpeed

        var n = LatticeNodeData.allocate(
            capacity: width * height * numDirections)
        Self.initNodeArray(
            n: &n, width: width, height: height, windSpeed: scaledWindSpeed)
        self.n = n

        // This will be fully assigned during each streaming step.
        self.nStream = LatticeNodeData.allocate(
            capacity: width * height * numDirections)

        self.isObstacle = [Bool](repeating: false, count: width * height)
        self.isBoundary = self.isObstacle

        self.tracers = stride(from: 0, to: height, by: 20).flatMap { y in
            stride(from: 0, to: width, by: 20).map { x in
                Tracer(x: Double(x), y: Double(y))
            }
        }

        self.index = LatticeIndexing(width: width, height: height)
        self.propCalc = LatticePropertyCalc(n: n, width: width, height: height)
    }

    internal static func initNodeArray(
        n: inout LatticeNodeData, width: Int, height: Int, windSpeed: Double
    ) {
        let densities = initNodeDensities(windSpeed: windSpeed)
        let numNodes = width * height
        var offset = 0
        for _ in 0..<numNodes {
            for j in 0..<numDirections {
                n[offset] = Float(densities[j])
                offset += 1
            }
        }
    }

    private static func initNodeDensities(windSpeed: Double) -> [Double] {
        // Mimic Daniel Schroeder's initial conditions, without understanding them.
        // He credits several others:
        // https://physics.weber.edu/schroeder/fluids/LatticeBoltzmannDemo.java.txt

        let v = windSpeed
        let vSqr = v * v
        let baseline = 1.0 - 1.5 * vSqr
        let easterly = 1.0 + 3.0 * v + 3.0 * vSqr
        let westerly = 1.0 - 3.0 * v + 3.0 * vSqr
        let wNone = 4.0 / 9.0
        let wCardinal = 1.0 / 9.0  // North, east, west, south
        let wOrdinal = 1.0 / 36.0  // Northeast, etc.
        let result: [Double] = Direction.allCases.map { dir in
            switch dir {
            case .none:
                return wNone * baseline
            case .n:
                return wCardinal * baseline
            case .e:
                return wCardinal * easterly
            case .w:
                return wCardinal * westerly
            case .s:
                return wCardinal * baseline
            case .ne, .se:
                return wOrdinal * easterly
            case .nw, .sw:
                return wOrdinal * westerly
            }
        }
        return result
    }

    deinit {
        n.deallocate()
        nStream.deallocate()
    }

    public func addObstacle(shape: Polygon) {
        // Slow and dirty:
        let yStart = Int(shape.bbox.minY)
        let yEnd = 1 + Int(shape.bbox.maxY)
        let xStart = Int(shape.bbox.minX)
        let xEnd = 1 + Int(shape.bbox.maxX)
        for y in yStart..<yEnd {
            let rowOffset = y * width
            for x in xStart..<xEnd {
                if shape.contains(x: x, y: y) {
                    isObstacle[rowOffset + x] = true
                }
            }
        }
        // Ditch any tracers that are positioned inside.
        let keep = tracers.filter { tracer in
            !shape.contains(x: tracer.x, y: tracer.y)
        }
        tracers = keep
    }

    public func setBoundaryEdge(x: Int) throws {
        guard (0 <= x) && (x < width) else {
            throw LatticeError.indexError("x (\(x)) must be in 0..<\(width)")
        }
        for y in 0..<height {
            isBoundary[y * width + x] = true
        }
    }

    public func setBoundaryEdge(y: Int) throws {
        guard (0 <= y) && (y < height) else {
            throw LatticeError.indexError("y (\(y)) must be in 0..<\(height)")
        }
        let rowOffset = y * width
        for x in 0..<width {
            isBoundary[rowOffset + x] = true
        }
    }

    public func step(disableTracers: Bool = false) {
        collide()
        stream()
        propCalc.update()
        if !disableTracers {
            moveTracers()
        }
    }

    internal func collide() {
        let numNodes = width * height
        let stepSize = numNodes / (3 * concurrency)
        for iStart in stride(from: 0, to: numNodes, by: stepSize) {
            queue.async(group: group) {
                let iEnd = min(numNodes, iStart + stepSize)
                for nodeIndex in iStart..<iEnd {
                    let offset = nodeIndex * numDirections

                    if self.isObstacle[nodeIndex] {
                        self.collideObstacle(offset)
                    } else if self.isBoundary[nodeIndex] {
                        self.collideBoundary(offset)
                    } else {
                        self.collideFluid(offset)
                    }
                }
            }
        }
        group.wait()
    }

    internal func collideObstacle(_ offset: Int) {
        let destIndices = [0, 5, 6, 7, 8, 1, 2, 3, 4]
        let newOffsets = (0..<numDirections).map { i in
            n[offset + destIndices[i]]
        }
        for i in 0..<numDirections {
            n[offset + i] = newOffsets[i]
        }
    }

    internal func collideBoundary(_ offset: Int) {
        // inget att göra
    }

    internal func collideFluid(_ offset: Int) {
        let props = propCalc.getNodeProperties(offset: offset)
        for i in 0..<numDirections {
            let equil = BGKCollision.getFEq(
                direction: i, siteProps: props, dvix: dvx[i], dviy: dvy[i])
            let dens = Double(n[offset + i])
            n[offset + i] = Float(dens + omega * (equil - dens))
        }
    }

    internal func stream() {
        let width = width
        let height = height
        
        func wrapped(_ val: Int, _ maxVal: Int) -> Int {
            return (val < 0) ? (val + maxVal) : ((val >= maxVal) ? val - maxVal : val)
        }

        let stepSize = max(1, height / (3 * concurrency))
        for ySrcStart in stride(from: 0, to: height, by: stepSize) {
            let ySrcEnd = min(height, ySrcStart + stepSize)
            queue.async(group: group) {
                for ySrc in ySrcStart..<ySrcEnd {
                    let rowNodeIndex = ySrc * width

                    for xSrc in 0..<width {
                        let iSrcNode = rowNodeIndex + xSrc
                        let iSrcNodeSite0 = iSrcNode * numDirections

                        for dirIndex in 0..<numDirections {
                            let iSrcSite = iSrcNodeSite0 + dirIndex

                            let yDest = wrapped(ySrc + idvy[dirIndex], height)
                            let xDest = wrapped(xSrc + idvx[dirIndex], width)
                            let iDestNode = yDest * width + xDest
                            let iDestSite = iDestNode * numDirections + dirIndex

                            // Boundary nodes don't stream in values; they just copy in their
                            // current field densities.
                            let srcIndex = self.isBoundary[iDestNode] ? iDestSite : iSrcSite
                            self.nStream[iDestSite] = self.n[srcIndex]
                        }
                    }
                }
            }
        }
        group.wait()
        n.assign(from: nStream, count: width * height * numDirections)
    }

    internal func moveTracers() {
        for tracer in tracers {
            let (x, y) = tracer.wholePos()
            let nodeIndex = index.uncheckedSiteIndex(x: x, y: y)
            let props = propCalc.getNodeProperties(offset: nodeIndex)
            tracer.move(
                dx: props.ux, dy: props.uy, boundingXMin: 0.0, yMin: 0.0,
                xMax: Double(width - 1), yMax: Double(height - 1))
        }
    }

    private func wrapped(_ val: Int, _ maxVal: Int) -> Int {
        if val < 0 {
            return val + maxVal
        }
        if val >= maxVal {
            return val - maxVal
        }
        return val
    }

}

// For visualization:
extension Lattice {
    /// Get the range of densities across all nodes of the lattice.
    /// - Returns: a tuple `(min, max)` of minimum and maximum densities
    public func getDensityRange() -> (min: Double, max: Double) {
        var minVal = 0.0
        var maxVal = 0.0
        var first = true

        for x in 0..<width {
            for y in 0..<height {
                let nodeIndex = (y * width) + x
                if !(isBoundary[nodeIndex] || isObstacle[nodeIndex]) {
                    if let rho = try? propCalc.getNodeProperties(x: x, y: y).rho {
                        if first {
                            minVal = rho
                            maxVal = rho
                            first = false
                        } else {
                            minVal = (minVal < rho) ? minVal : rho
                            maxVal = (maxVal > rho) ? maxVal : rho
                        }
                    }
                }
            }
        }
        return (min: minVal, max: maxVal)
    }
}
