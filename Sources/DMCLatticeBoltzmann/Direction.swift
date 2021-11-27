public enum Direction: Int, CaseIterable {
    case none = 0
    case n, ne, e, se, s, sw, w, nw
}

public let numDirections = Direction.allCases.count
let directionIndices: [Int] = Direction.allCases.map { $0.rawValue }
