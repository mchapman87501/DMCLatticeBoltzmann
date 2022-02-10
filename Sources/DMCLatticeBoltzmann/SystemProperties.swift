// Rho is the total node density.
// u is the aggregate velocity vector for the node.

/// Describes the gas properties of a whole lattice.
///
/// ``NodeProperties`` is an alias that describes the properties of a single lattice site.
public struct SystemProperties {
    /// fluid density (unitless)
    public let rho: Double
    /// x component of macroscopic flow velocity
    public let ux: Double
    /// y component of macroscopic flow velocity
    public let uy: Double
}
