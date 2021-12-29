import Foundation

struct LatticeIndexing {
    let width: Int
    let height: Int

    // Get the index of a mask node
    public func maskIndex(x: Int, y: Int) -> Int {
        y * width + x
    }

    // Get the index of a node's first (of numDirections) cell.
    public func uncheckedSiteIndex(x: Int, y: Int) -> Int {
        (y * width + x) * numDirections
    }

    public func siteIndex(x: Int, y: Int) throws -> Int {
        guard (0 <= x) && (x < width) else {
            throw LatticeError.indexError("x (\(x)) must be in 0..<\(width)")
        }
        guard (0 <= y) && (y < height) else {
            throw LatticeError.indexError("y (\(y)) must be in 0..<\(height)")
        }
        return uncheckedSiteIndex(x: x, y: y)
    }
}
