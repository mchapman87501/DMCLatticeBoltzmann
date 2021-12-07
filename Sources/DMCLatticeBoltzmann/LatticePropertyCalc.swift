import Accelerate
import Foundation

public typealias NodeProperties = SystemProperties

public struct LatticePropertyCalc {
    static private var fone = (0..<numDirections).map { _ in Float(1.0) }

    let n: LatticeNodeData
    public let width: Int
    public let height: Int

    let index: LatticeIndexing

    private let numRecords: Int
    private var rhos: [Float]
    private var uxSums: [Float]
    private var uySums: [Float]
    private var ux: [Float]
    private var uy: [Float]

    public init(n: LatticeNodeData, width: Int, height: Int) {
        self.n = n
        self.width = width
        self.height = height
        self.index = LatticeIndexing(width: width, height: height)

        let numRecords = width * height
        self.numRecords = numRecords
        self.rhos = [Float](repeating: 0.0, count: numRecords)
        self.uxSums = [Float](repeating: 0.0, count: numRecords)
        self.uySums = [Float](repeating: 0.0, count: numRecords)
        self.ux = [Float](repeating: 0.0, count: numRecords)
        self.uy = [Float](repeating: 0.0, count: numRecords)
        calcAllNodeProperties()
    }

    public mutating func update() {
        calcAllNodeProperties()
    }

    private mutating func calcAllNodeProperties() {
        let numRecords = Int32(numRecords)
        // rhos:
        cblas_sgemv(
            CblasRowMajor, CblasNoTrans, numRecords, Int32(numDirections), 1.0,
            n, Int32(numDirections), Self.fone, Int32(1), 0.0, &rhos, Int32(1))

        // uxSums:
        cblas_sgemv(
            CblasRowMajor, CblasNoTrans, numRecords, Int32(numDirections), 1.0,
            n, Int32(numDirections), fdvx, Int32(1), 0.0, &uxSums, Int32(1))

        // uySums:
        cblas_sgemv(
            CblasRowMajor, CblasNoTrans, numRecords, Int32(numDirections), 1.0,
            n, Int32(numDirections), fdvy, Int32(1), 0.0, &uySums, Int32(1))

        var nr = numRecords
        vvdivf(&ux, &uxSums, &rhos, &nr)
        vvdivf(&uy, &uySums, &rhos, &nr)
    }

    public func getProperties() -> SystemProperties {
        let rhoSum = Double(rhos.reduce(0.0) { $0 + $1 })
        let uxSum = Double(uxSums.reduce(0.0) { $0 + $1 })
        let uySum = Double(uySums.reduce(0.0) { $0 + $1 })

        let rho = rhoSum / Double(numRecords)
        let ux = (rho > 0.0) ? (uxSum / rho) : 0.0
        let uy = (rho > 0.0) ? (uySum / rho) : 0.0
        return SystemProperties(rho: rho, ux: ux, uy: uy)
    }

    public func getNodeProperties(x: Int, y: Int) throws -> NodeProperties {
        let offset = try index.siteIndex(x: x, y: y)
        let result = getNodeProperties(offset: offset)
        return result
    }

    public func getNodeProperties(offset nodeOffset: Int) -> NodeProperties {
        // XXX FIX THIS artifact of old API
        let offset = nodeOffset / numDirections

        let rho = Double(rhos[offset])
        let x = Double(ux[offset])
        let y = Double(uy[offset])
        /// **NB:** In a D2Q9 simulation pressure varies linearly with density.
        /// Paraphrasing from [https://homepages.abdn.ac.uk/jderksen/pages/lbm/ln02_lb.pdf](https://homepages.abdn.ac.uk/jderksen/pages/lbm/ln02_lb.pdf):
        ///
        /// "Finally, as we will see in Section 2.4, each velocity set comes with a constant _c\_s_ that relates
        /// pressure _p_ with density _rho_:  p = rho \* c\_s^2
        /// This is an (isothermal) ideal gas law with ∂p = c\_s^2
        /// so that c\_s is the speed of sound.
        ///
        /// In the most common velocity sets, c\_s = √(1/3) \* ∆x/∆t
        /// (i.e., c_s = √(1/3) in lattice units)."
        return NodeProperties(rho: rho, ux: x, uy: y)
    }
}
