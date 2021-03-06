// swift-tools-version:5.5
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "DMCLatticeBoltzmann",
    // https://docs.swift.org/package-manager/PackageDescription/PackageDescription.html
    platforms: [
        .macOS(.v11)
        // .linux
    ],
    products: [
        .library(
            name: "DMCLatticeBoltzmann",
            targets: ["DMCLatticeBoltzmann"]),
        .library(
            name: "DMCLatticeBoltzmannRender",
            targets: ["DMCLatticeBoltzmannRender"]),
        .executable(
            name: "DMCLatticeBoltzmannSim",
            targets: ["DMCLatticeBoltzmannSim"]),
    ],
    dependencies: [
        // Dependencies declare other packages that this package depends on.
        // .package(url: /* package url */, from: "1.0.0"),
        .package(
            url: "https://github.com/mchapman87501/DMCMovieWriter.git",
            from: "1.0.1"),
        .package(
            url: "https://github.com/mchapman87501/DMC2D.git", from: "1.0.4"),
    ],
    targets: [
        // Targets are the basic building blocks of a package. A target can define a module or a test suite.
        // Targets can depend on other targets in this package, and on products in packages this package depends on.
        .executableTarget(
            name: "DMCLatticeBoltzmannSim",
            dependencies: ["DMCLatticeBoltzmann", "DMCLatticeBoltzmannRender"]),
        .target(
            name: "DMCLatticeBoltzmann",
            dependencies: ["DMC2D"]),
        .target(
            name: "DMCLatticeBoltzmannRender",
            dependencies: ["DMCMovieWriter", "DMCLatticeBoltzmann"]),
        .testTarget(
            name: "DMCLatticeBoltzmannTests",
            dependencies: ["DMCLatticeBoltzmann"]),
        .testTarget(
            name: "DMCLatticeBoltzmannRenderTests",
            dependencies: ["DMCLatticeBoltzmannRender"]),
    ]
)
