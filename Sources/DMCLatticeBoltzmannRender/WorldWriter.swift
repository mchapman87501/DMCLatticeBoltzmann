import AppKit
import DMCLatticeBoltzmann
import DMCMovieWriter
import Foundation

/// Creates movies showing the evolving state of a fluid flow simulation.
public struct WorldWriter {
    let lattice: Lattice
    let foil: AirFoil
    let movieWriter: DMCMovieWriter
    let frameMaker: MovieFrame
    var title: String

    /// Create a new instance to record a simulation to a movie URL.
    ///
    /// Caveat emptor: this has been tested only with local `file:` movie URLs.
    /// - Parameters:
    ///   - lattice: the lattice to be recorded
    ///   - foil: airfoil around which fluid flow is being modeled
    ///   - writingTo: the location of the output movie
    ///   - title: title text to be displayed in legend overlays
    public init(
        lattice: Lattice, foil: AirFoil, writingTo: DMCMovieWriter,
        title: String = ""
    ) throws {
        self.lattice = lattice
        self.foil = foil
        movieWriter = writingTo
        frameMaker = MovieFrame(
            lattice: lattice, foil: foil, width: lattice.width,
            height: lattice.height, title: title)
        self.title = title
    }

    /// Add a title frame.
    ///
    /// Caveat: Multline titles *should* be supported, but this has not been tested.
    /// - Parameters:
    ///   - title: Text to show in the title frame
    ///   - duration: How long to display the title frame, excluding any fade-in/out time
    public func showTitle(_ title: String, duration seconds: Int = 3) throws {
        let size = NSSize(width: lattice.width, height: lattice.height)

        let numRampFrames = 30
        let rampFrameDuration = 1.0 / 30.0

        var alpha = 0.0
        let dAlpha = 1.0 / Double(numRampFrames)
        for _ in 0..<numRampFrames {
            try addTitleFrame(
                title: title, size: size, alpha: alpha,
                duration: rampFrameDuration)
            alpha += dAlpha
        }

        try addTitleFrame(
            title: title, size: size, alpha: 1.0, duration: Double(seconds))

        for _ in 0..<numRampFrames {
            try addTitleFrame(
                title: title, size: size, alpha: alpha,
                duration: rampFrameDuration)
            alpha -= dAlpha
        }
        try movieWriter.drain()
    }

    private func addTitleFrame(
        title: String, size: NSSize, alpha: Double, duration: Double
    ) throws {
        try autoreleasepool {
            try movieWriter.addFrame(
                titleFrameImage(title: title, size: size, alpha: alpha),
                duration: duration)
        }
    }

    private func titleFrameImage(title: String, size: NSSize, alpha: Double)
        -> NSImage
    {
        NSImage(size: size, flipped: false) { rect in
            NSColor.black.setFill()
            NSBezierPath.fill(rect)

            // Solution from https://izziswift.com/how-to-use-nsstring-drawinrect-to-center-text/ inter alia
            let numLines = title.components(separatedBy: "\n").count

            // Try to use, e.g.,  1/3 of the height.
            let fontSize = (rect.height / 3.0) / Double(numLines)
            // https://stackoverflow.com/a/21940339/2826337
            let font = NSFont.systemFont(ofSize: fontSize)
            let attrs = [
                NSAttributedString.Key.font: font,
                NSAttributedString.Key.foregroundColor: NSColor.white
                    .withAlphaComponent(alpha),
            ]
            let size = (title as NSString).size(withAttributes: attrs)
            let xPos = max(0.0, (rect.size.width - size.width) / 2.0)
            let yPos = max(0.0, (rect.size.height - size.height) / 2.0)

            (title as NSString).draw(
                at: NSPoint(x: rect.origin.x + xPos, y: rect.origin.y + yPos),
                withAttributes: attrs)
            return true
        }
    }

    /// Record the current state of the simulation as a new movie frame.
    ///
    /// `alpha` can be used for fade-in/fade-out effects.  A value of 0 produces a black, "faded out," frame.
    /// A value of 1 produces a normal, "faded in," frame.
    ///
    /// - Parameter alpha: the movie frame transparency
    public func writeNextFrame(alpha: Double = 1.0) throws {
        try autoreleasepool {
            try movieWriter.addFrame(frameMaker.createFrame(alpha: alpha))
        }
    }

    /// Get an image showing the current state of the simulation.
    ///
    /// This method is for creating images to be displayed in user interfaces, e.g., to show the
    /// progress of a movie recording.
    ///
    /// - Parameter desiredWidth: the desired width of the image, in points
    /// - Returns: an image depicting the current state of the simulation
    public func getCurrFrame(width desiredWidth: Double) -> NSImage {
        autoreleasepool {
            let scaleFactor = desiredWidth / Double(lattice.width)
            let desiredHeight = Double(lattice.height) * scaleFactor
            let w = Int(desiredWidth)
            let h = Int(desiredHeight)
            let frame = MovieFrame(
                lattice: lattice, foil: foil, width: w, height: h, title: title)
            let result = frame.createFrame()
            return result
        }
    }
}
