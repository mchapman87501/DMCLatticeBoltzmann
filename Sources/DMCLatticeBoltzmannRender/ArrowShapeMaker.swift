import AppKit
import DMC2D
import DMCLatticeBoltzmann
import Foundation

struct ArrowShapeMaker {
    func getArrowShape(vector: Vector, tailAnchor: Vector, width: Double)
        -> NSBezierPath
    {
        // Get an arrow of representative length, with its tip at 0.0.
        let shape = getArrowShape(length: vector.magnitude(), width: width)

        // Translate the tail to the origin:
        let arrowLength = shape.bounds.width
        let tailOffsetTrans = AffineTransform(
            translationByX: arrowLength, byY: 0.0)

        // Rotate by the vector's direction:
        let rotateTrans = AffineTransform(rotationByRadians: vector.angle())

        // Translate to the anchor point.
        let offsetTrans = AffineTransform(
            translationByX: tailAnchor.x, byY: tailAnchor.y)

        var arrowTransform = AffineTransform.identity
        arrowTransform.append(tailOffsetTrans)
        arrowTransform.append(rotateTrans)
        arrowTransform.append(offsetTrans)

        shape.transform(using: arrowTransform)
        shape.lineCapStyle = .round
        shape.lineJoinStyle = .miter
        return shape
    }

    func getArrowShape(vector: Vector, tipAnchor: Vector, width: Double)
        -> NSBezierPath
    {
        // Get an arrow of representative length, with its tip at 0.0.
        let shape = getArrowShape(length: vector.magnitude(), width: width)

        // Translate the tip to the endpoint:
        let offsetTrans = AffineTransform(
            translationByX: tipAnchor.x, byY: tipAnchor.y)

        // Rotate by the vector's direction:
        let rotateTrans = AffineTransform(rotationByRadians: vector.angle())

        var arrowTransform = AffineTransform.identity
        arrowTransform.append(rotateTrans)
        arrowTransform.append(offsetTrans)

        shape.transform(using: arrowTransform)
        shape.lineCapStyle = .round
        shape.lineJoinStyle = .miter
        return shape
    }

    // Get a shape (a Bezier path) for an arrow with a given shaft length.
    // The arrowhead size is fixed.
    // The arrow points in the positive x direction.
    // The arrow's tip is at (0.0, 0.0)
    func getArrowShape(length shaftLength: Double, width: Double)
        -> NSBezierPath
    {
        let arrow = NSBezierPath()

        let arrSz = 5.0 * width / 2.0
        let yLineOffset = width / 2.0
        // Let positive X direction be zero rotation.

        // This is the arrowhead.
        let first = NSPoint(x: -1.5 * arrSz, y: yLineOffset)
        arrow.move(to: first)
        arrow.line(to: NSPoint(x: -2.0 * arrSz, y: arrSz))
        arrow.line(to: NSPoint(x: 0.0, y: 0.0))
        arrow.line(to: NSPoint(x: -2.0 * arrSz, y: -arrSz))
        arrow.line(to: NSPoint(x: -1.5 * arrSz, y: -yLineOffset))

        // This is the shaft.
        let xShaftEnd = -1.5 * arrSz - shaftLength
        let shaftEnd1 = NSPoint(x: xShaftEnd, y: -yLineOffset)
        let shaftEnd2 = NSPoint(x: xShaftEnd, y: yLineOffset)
        let arcCenter = NSPoint(x: xShaftEnd - width, y: 0.0)

        // Add a half-circle from shaftEnd1 to the implied shaftEnd2.
        arrow.line(to: shaftEnd1)
        arrow.appendArc(from: arcCenter, to: shaftEnd2, radius: width / 2.0)
        // Connect back to the arrowhead.
        arrow.close()

        return arrow
    }
}
