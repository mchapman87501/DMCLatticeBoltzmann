import Foundation

// NB: Based on old Figure 8 code.

internal func sRGBToLabD65(red: Double, green: Double, blue: Double) -> (
    labL: Double, laba: Double, labb: Double
) {
    let (x, y, z) = sRGBToXYZ(red: red, green: green, blue: blue)
    return xyzToLabD65(x: x, y: y, z: z)
}

func labD65TosRGB(labL: Double, laba: Double, labb: Double) -> (
    red: Double, green: Double, blue: Double
) {
    let (x, y, z) = labD65ToXYZ(labL: labL, laba: laba, labb: labb)
    return xyzTosRGB(x: x, y: y, z: z)
}

private let cieE = 216.0 / 24389.0
private let d65IllumX = 0.95047
private let d65IllumY = 1.0
private let d65IllumZ = 1.08883

private func scaleXYZToLabD65(_ component: Double) -> Double {
    if component > cieE {
        return pow(component, 1.0 / 3.0)
    }
    return (7.787 * component) + (16.0 / 116.0)
}

private func unscaleXYZToLabD65(_ component: Double) -> Double {
    let cubed = pow(component, 3)
    if cubed > cieE {
        return cubed
    }
    return (cubed - 16.0 / 116.0) / 7.787
}

private func scalesRGBToXYZ(_ component: Double) -> Double {
    let fract = component / 255.0
    if fract > 0.04045 {
        return pow((fract + 0.055) / 1.055, 2.4)
    }
    return fract / 12.92
}

private func unscalesRGBToXYZ(_ component: Double) -> Double {
    if component > 0.0031308 {
        return (1.055 * pow(component, 1.0 / 2.4)) - 0.055
    }
    return component * 12.92
}

func xyzToLabD65(x: Double, y: Double, z: Double) -> (
    labL: Double, laba: Double, labb: Double
) {
    let xs = scaleXYZToLabD65(x / d65IllumX)
    let ys = scaleXYZToLabD65(y / d65IllumY)
    let zs = scaleXYZToLabD65(z / d65IllumZ)
    return (
        labL: (116.0 * ys) - 16.0,
        laba: 500.0 * (xs - ys),
        labb: 200.0 * (ys - zs)
    )
}

func labD65ToXYZ(labL: Double, laba: Double, labb: Double) -> (
    x: Double, y: Double, z: Double
) {
    let ty = (labL + 16.0) / 116.0
    let tx = laba / 500.0 + ty
    let tz = ty - labb / 200.0
    return (
        x: d65IllumX * unscaleXYZToLabD65(tx),
        y: d65IllumY * unscaleXYZToLabD65(ty),
        z: d65IllumZ * unscaleXYZToLabD65(tz)
    )
}

func xyzTosRGB(x: Double, y: Double, z: Double) -> (
    red: Double, green: Double, blue: Double
) {
    let tr = 3.24071 * x + -1.53726 * y + -0.498571 * z
    let tg = -0.969258 * x + 1.87599 * y + 0.0415557 * z
    let tb = 0.0556352 * x + -0.203996 * y + 1.05707 * z

    return (
        red: unscalesRGBToXYZ(tr),
        green: unscalesRGBToXYZ(tg),
        blue: unscalesRGBToXYZ(tb)
    )
}

func sRGBToXYZ(red: Double, green: Double, blue: Double) -> (
    x: Double, y: Double, z: Double
) {
    // sRGB uses D65 illuminant.
    let r = scalesRGBToXYZ(red)
    let g = scalesRGBToXYZ(green)
    let b = scalesRGBToXYZ(blue)

    return (
        x: 0.412424 * r + 0.357579 * g + 0.180464 * b,
        y: 0.212656 * r + 0.715158 * g + 0.0721856 * b,
        z: 0.0193324 * r + 0.119193 * g + 0.950444 * b
    )
}
