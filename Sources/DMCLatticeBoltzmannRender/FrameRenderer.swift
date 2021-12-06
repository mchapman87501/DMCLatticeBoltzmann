import AppKit
import DMCLatticeBoltzmann
import Foundation

typealias NormalizeFN = (Double) -> Double

private let palette = BluescalePalette()

class FrameRenderer {
    let title: String
    let alpha: Double
    let scale: Double

    let n: LatticeNodeData
    let foilShape: DMCLatticeBoltzmann.Polygon
    let propCalc: LatticePropertyCalc
    let normalizedDensity: NormalizeFN
    let isObstacle: [Bool]
    // Indexed by [x][y].
    let nodeRects: [[NSRect]]
    // Array of (x, y)
    let tracers: [(Double, Double)]

    init(
        title: String, alpha: Double, scale: Double, lattice: Lattice,
        foil: AirFoil, nodeRects: [[NSRect]],
        normalizedDensity: @escaping NormalizeFN
    ) {
        // Cache the current lattice state.
        // NSImage's drawing block may be executed later, after lattice has changed.
        let numFields = lattice.width * lattice.height * numDirections
        let n = LatticeNodeData.allocate(capacity: numFields)
        n.assign(from: lattice.n, count: numFields)
        let propCalc = LatticePropertyCalc(
            n: n, width: lattice.width, height: lattice.height)

        let tracerPositions = lattice.tracers.map { ($0.x, $0.y) }

        self.title = title

        self.alpha = alpha
        self.scale = scale
        self.n = n
        self.foilShape = foil.shape
        self.propCalc = propCalc
        self.normalizedDensity = normalizedDensity
        self.isObstacle = lattice.isObstacle
        self.nodeRects = nodeRects
        self.tracers = tracerPositions
    }

    deinit {
        n.deallocate()
    }

    func draw(_ rect: NSRect) {
        drawBackground(rect)
        drawLatticeSites(rect)
        drawTracers(rect)
        drawFoil(rect)
        drawPressureVectors(rect)
        if !title.isEmpty {
            drawLegend(rect)
        }
        overlayAlpha(rect)
    }

    private func drawBackground(_ rect: NSRect) {
        // Multiple frames may be rendering concurrently.  Does this
        // setFill affect other contexts?
        NSColor.black.setFill()
        NSBezierPath.fill(rect)
    }

    private func overlayAlpha(_ rect: NSRect) {
        NSColor.black.withAlphaComponent(1.0 - alpha).setFill()
        NSBezierPath.fill(rect)
    }

    private func drawLatticeSites(_ rect: NSRect) {
        // From https://homepages.abdn.ac.uk/jderksen/pages/lbm/ln02_lb.pdf,
        // in Lattice Boltzmann simulations pressure varies linearly with density.
        // So, use density as a proxy for pressure.

        for y in 0..<propCalc.height {
            let rowIndex = y * propCalc.width
            for x in 0..<propCalc.width {
                var color = NSColor.lightGray
                if !isObstacle[rowIndex + x] {
                    if let props = try? propCalc.getNodeProperties(x: x, y: y) {
                        color = palette.color(
                            fraction: normalizedDensity(props.rho))
                    }
                }
                color.setFill()
                NSBezierPath.fill(nodeRects[x][y])
            }
        }
    }

    private func drawTracers(_ rect: NSRect) {
        NSColor(calibratedRed: 1.0, green: 0.2, blue: 0.2, alpha: 1.0).setFill()
        for (x, y) in tracers {
            let xDisplay = x * scale
            let yDisplay = y * scale
            let tracerRect = NSRect(
                x: xDisplay, y: yDisplay, width: 3 * scale, height: 3 * scale)
            let path = NSBezierPath(ovalIn: tracerRect)
            path.fill()
        }
    }

    private func drawFoil(_ rect: NSRect) {
        // Explicitly draw the foil, mainly to eliminate lattice site jaggies.
        let path = NSBezierPath()
        path.move(to: foilShape.vertices[0])
        for vertex in foilShape.vertices[1...] {
            path.line(to: vertex)
        }
        path.close()

        let fillColor = NSColor.gray
        fillColor.setFill()
        path.fill()

        let strokeColor = NSColor.black
        strokeColor.set()
        path.lineWidth = 1.0
        path.stroke()
    }

    private func drawPressureVectors(_ rect: NSRect) {
        let epc = EdgePressureCalc(propCalc: propCalc, shape: foilShape)
        drawSegmentPressureVectors(rect, epc: epc)
        drawNetPressureVector(rect, epc: epc)
    }

    private func drawSegmentPressureVectors(
        _ rect: NSRect, epc: EdgePressureCalc
    ) {
        let maker = ArrowShapeMaker()

        for i in 0..<epc.edgeMidpoints.count {
            let shape = maker.getArrowShape(
                vector: epc.edgePressureVectors[i],
                tipAnchor: epc.edgeMidpoints[i], width: 3.0)
            let color =
                (epc.edgePressures[i] < 0.0) ? NSColor.blue : NSColor.red
            color.setFill()
            color.setStroke()
            shape.lineWidth = 0.2
            shape.stroke()
            shape.fill()
        }
    }

    private func drawNetPressureVector(_ rect: NSRect, epc: EdgePressureCalc) {
        let maker = ArrowShapeMaker()
        NSColor.lightGray.set()
        NSColor.white.setFill()
        // Offset the end point so the tail of the arrow lands at the foil's center.
        let foilCenter = foilShape.center

        // Heuristic: scale up the net pressure vector so it has visible length.
        let pressureVec = epc.netPressure.scaled(10.0)
        let endPoint = Vector(foilCenter)
        let arrowWidth = foilShape.bbox.width / 50.0
        let netPressShape = maker.getArrowShape(
            vector: pressureVec, tailAnchor: endPoint, width: arrowWidth)
        netPressShape.lineWidth = 1.0
        netPressShape.stroke()
        netPressShape.fill()
    }

    private func drawLegend(_ fullRect: NSRect) {
        let width = fullRect.width / 4
        let height = fullRect.height / 4

        let mfSize = 10.0
        let measureFont = NSFont.systemFont(ofSize: mfSize)
        let measureAttrs = [
            NSAttributedString.Key.font: measureFont
        ]
        let refTitleSize = (title as NSString).size(
            withAttributes: measureAttrs)

        let scale = min(
            width / refTitleSize.width, height / refTitleSize.height)
        let fontSize = scale * mfSize
        let font = NSFont.systemFont(ofSize: fontSize)
        let attrs = [
            NSAttributedString.Key.font: font,
            NSAttributedString.Key.foregroundColor: NSColor.black,
        ]
        let titleSize = (title as String).size(withAttributes: attrs)

        // Create a background rect that fits the text plus some margin.
        let marginFract = 0.05  // Margin within the background rect
        let bgWidth = titleSize.width * (1.0 + 2.0 * marginFract)
        let bgHeight = titleSize.height * (1.0 + 2.0 * marginFract)

        let bgOffset = 10.0
        let bgOrigin = CGPoint(
            x: fullRect.origin.x + bgOffset,
            y: fullRect.height - bgHeight - bgOffset)
        let bgSize = NSSize(width: bgWidth, height: bgHeight)
        let backgroundRect = NSRect(origin: bgOrigin, size: bgSize)

        NSColor(calibratedWhite: 1.0, alpha: 0.3).setFill()
        NSBezierPath.fill(backgroundRect)

        let xPos = bgOrigin.x + (bgWidth - titleSize.width) / 2.0
        let yPos = bgOrigin.y + (bgHeight - titleSize.height) / 2.0

        (title as NSString).draw(
            at: NSPoint(x: xPos, y: yPos),
            withAttributes: attrs)

        NSColor.black.setStroke()
        NSBezierPath.stroke(backgroundRect)
    }
}
