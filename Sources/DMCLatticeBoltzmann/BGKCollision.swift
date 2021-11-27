import Accelerate

public struct BGKCollision {
    private static let cardinal = 1.0 / 9.0
    private static let diagonal = 1.0 / 36.0
    public static let weights = [
        4.0 / 9.0,  // center
        cardinal, diagonal, cardinal, diagonal, cardinal, diagonal, cardinal,
        diagonal,
    ]

    public static func getFEq(
        direction: Int, siteProps p: NodeProperties, dvix: Double, dviy: Double
    ) -> Double {
        let weight = weights[direction]

        let ux = p.ux
        let uy = p.uy
        let cdotu = dvix * ux + dviy * uy
        let usqr = ux * ux + uy * uy

        let result =
            p.rho * weight
            * (1.0 + 3.0 * cdotu + 4.5 * cdotu * cdotu - 1.5 * usqr)
        return result
    }
}
