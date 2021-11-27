// I'm trying to learn a bit about Lattice Boltzmann by following
// assignment guidelines from
// https://physics.weber.edu/schroeder/javacourse/LatticeBoltzmann.pdf
import Foundation
import DMCLatticeBoltzmann
import DMCMovieWriter
import DMCLatticeBoltzmannRender

struct StopWatch {
    let t0 = DispatchTime.now()

    func finish(_ msg: String) {
        let tf = DispatchTime.now()
        let dt = Double(tf.uptimeNanoseconds - t0.uptimeNanoseconds) / 1.0e9
        print(String(format: "\(msg): %.2f seconds", dt))
    }

    func time<T>(_ msg: String, _ block: () -> T) -> T {
        defer { finish(msg) }
        return block()
    }
}

struct Scenario {
    let temperature: Double
    let viscosity: Double
    let windSpeed: Double

    func description() -> String {
        return String(
            format: """
                Temperature: %.2f
                Viscosity: %.4f
                Wind speed: %.2f
                """, temperature, viscosity, windSpeed)
    }
}

func run(scenario: Scenario, lattice: Lattice, foil: AirFoil, writingTo movieWriter: DMCMovieWriter) {
    let title = scenario.description()

    let writer = try! WorldWriter(lattice: lattice, foil: foil, writingTo: movieWriter, title: title)

    print(title)
    try! writer.showTitle(title)

    let fps = 30
    let stepsPerFrame = 10
    let seconds = 30

    // Initial conditions are often way out of equilibrium.
    // Allow time to converge to a steadier flow state.
    print("Settling...")
    let eqSeconds = 15
    for sec in 1...eqSeconds {
        StopWatch().time("    \(sec)") {
            for _ in 1...fps {
                for _ in 1...stepsPerFrame {
                    lattice.step(disableTracers: true)
                }
            }
        }
    }

    print("Running.")
    for sec in 1...seconds {
        for frame in 1...fps {
            StopWatch().time("    \(sec).\(frame)") {
                for _ in 1...stepsPerFrame {
                    lattice.step()
                }
                // Cheap way to ramp up / down.
                let alpha: Double = {
                    if sec == 1 {
                        return Double(frame) / Double(fps)
                    }
                    if sec == seconds {
                        return Double(fps - frame) / Double(fps)
                    }
                    return 1.0
                }()
                try! writer.writeNextFrame(alpha: alpha)
            }
        }
    }
}

func recordScenario(
    movieWriter: DMCMovieWriter, worldWidth: Int, worldHeight: Int,
    scenario: Scenario
) {
    let xFoil = 0.4 * Double(worldWidth)
    let yFoil = 0.4 * Double(worldHeight)
    let wFoil = Double(worldWidth) / 3.0
    let foil = AirFoil(
        x: xFoil, y: yFoil, width: wFoil, alphaRad: 6.0 * .pi / 180.0)

    let omega = 1.0 / (3.0 * scenario.viscosity + 0.5)
    let lattice = Lattice(
        width: worldWidth, height: worldHeight, omega: omega,
        temperature: scenario.temperature, windSpeed: scenario.windSpeed)!
    lattice.addObstacle(shape: foil.shape)

    try! lattice.setBoundaryEdge(y: 0)
    try! lattice.setBoundaryEdge(y: worldHeight - 1)
    try! lattice.setBoundaryEdge(x: 0)
    try! lattice.setBoundaryEdge(x: worldWidth - 1)

    run(scenario: scenario, lattice: lattice, foil: foil, writingTo: movieWriter)
}

func getScenarios() -> [Scenario] {
    var result = [Scenario]()
    let temperature = 20.0
    for viscosity in [0.002, 0.04] {
        for windSpeed in [90.0, 40.0] {
            result.append(
                Scenario(
                    temperature: temperature, viscosity: viscosity,
                    windSpeed: windSpeed))
        }
    }
    return result
}

func main() {
    let worldWidth = 1280
    let worldHeight = 720

    let movieURL = URL(fileURLWithPath: "movie.mov")

    guard
        let movieWriter = try? DMCMovieWriter(
            outpath: movieURL, width: worldWidth, height: worldHeight)
    else {
        print("Could not create movie writer.")
        return
    }

    for scenario in getScenarios() {
        recordScenario(
            movieWriter: movieWriter,
            worldWidth: worldWidth, worldHeight: worldHeight,
            scenario: scenario)
        try! movieWriter.drain()
    }
    try! movieWriter.finish()
}

main()
