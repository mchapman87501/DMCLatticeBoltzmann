enum Direction: Int, CaseIterable {
    case none = 0
    case n, ne, e, se, s, sw, w, nw
}

/// The total number of lattice field directions
public let numDirections = Direction.allCases.count
