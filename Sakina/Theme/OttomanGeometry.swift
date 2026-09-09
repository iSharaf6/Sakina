import SwiftUI

// MARK: - Ottoman geometry
//
// Everything here is constructed, not drawn: eight-fold symmetry from two
// overlapping squares, tiled on a square lattice so the negative space forms
// the classic cross between stars. The field sits behind every screen at
// roughly ten percent, so the app has texture without the content competing.

enum GeometricPattern: Hashable {
    /// Eight-point stars on a square lattice; crosses appear between them.
    case starAndCross
    /// Stars plus the inner octagon and construction squares of each khatam.
    case khatam
    /// No pattern.
    case none
}

/// One eight-point star (octagram {8/2}) built from two squares.
struct OctagramStar: Shape {
    /// Ratio of inner to outer radius. 0.7654 is the geometric value for two
    /// overlapping squares; smaller values give sharper points.
    var innerRatio: CGFloat = 0.7654

    func path(in rect: CGRect) -> Path {
        let center = CGPoint(x: rect.midX, y: rect.midY)
        let outer = min(rect.width, rect.height) / 2
        let inner = outer * innerRatio
        var path = Path()
        for index in 0..<16 {
            let angle = CGFloat(index) * .pi / 8
            let radius = index.isMultiple(of: 2) ? outer : inner
            let point = CGPoint(x: center.x + cos(angle) * radius, y: center.y + sin(angle) * radius)
            if index == 0 { path.move(to: point) } else { path.addLine(to: point) }
        }
        path.closeSubpath()
        return path
    }
}

/// A single khatam rosette: octagram, inner octagon and the two squares.
struct KhatamRosette: Shape {
    func path(in rect: CGRect) -> Path {
        let center = CGPoint(x: rect.midX, y: rect.midY)
        let outer = min(rect.width, rect.height) / 2
        func point(_ angle: CGFloat, _ radius: CGFloat) -> CGPoint {
            CGPoint(x: center.x + cos(angle) * radius, y: center.y + sin(angle) * radius)
        }
        var path = Path()
        // Two squares, one rotated 45°.
        for turn in [CGFloat(0), .pi / 4] {
            for index in 0..<4 {
                let p = point(turn + CGFloat(index) * .pi / 2, outer)
                if index == 0 { path.move(to: p) } else { path.addLine(to: p) }
            }
            path.closeSubpath()
        }
        // Inner octagon through the crossing points.
        let inner = outer * 0.7654
        for index in 0..<8 {
            let p = point(CGFloat(index) * .pi / 4 + .pi / 8, inner)
            if index == 0 { path.move(to: p) } else { path.addLine(to: p) }
        }
        path.closeSubpath()
        // A small central octagon.
        let core = outer * 0.32
        for index in 0..<8 {
            let p = point(CGFloat(index) * .pi / 4 + .pi / 8, core)
            if index == 0 { path.move(to: p) } else { path.addLine(to: p) }
        }
        path.closeSubpath()
        return path
    }
}

/// The tiled field. Drawn once per size with `Canvas` and rasterised.
struct GeometricField: View {
    var pattern: GeometricPattern = .starAndCross
    var unit: CGFloat = 92
    var color: Color = .yqAccent
    var opacity: Double = 0.10
    var lineWidth: CGFloat = 0.8

    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        if pattern == .none {
            Color.clear
        } else {
            Canvas(opaque: false, rendersAsynchronously: true) { context, size in
                let stroke = color.opacity(colorScheme == .dark ? opacity * 0.9 : opacity)
                let columns = Int(ceil(size.width / unit)) + 2
                let rows = Int(ceil(size.height / unit)) + 2
                for row in -1..<rows {
                    for column in -1..<columns {
                        // Stars sit on the lattice; the lattice spacing equals the
                        // star diameter so neighbouring points touch and the
                        // gaps between four stars form a cross.
                        let rect = CGRect(
                            x: CGFloat(column) * unit - unit / 2,
                            y: CGFloat(row) * unit - unit / 2,
                            width: unit, height: unit
                        )
                        switch pattern {
                        case .starAndCross:
                            context.stroke(OctagramStar().path(in: rect), with: .color(stroke), lineWidth: lineWidth)
                        case .khatam:
                            context.stroke(OctagramStar().path(in: rect), with: .color(stroke), lineWidth: lineWidth)
                            context.stroke(KhatamRosette().path(in: rect.insetBy(dx: unit * 0.16, dy: unit * 0.16)),
                                           with: .color(stroke.opacity(0.7)), lineWidth: lineWidth * 0.8)
                        case .none:
                            break
                        }
                    }
                }
            }
            .drawingGroup()
            .allowsHitTesting(false)
            .accessibilityHidden(true)
        }
    }
}

/// A single rosette that draws itself to completion. Used for finishing a
/// collection and as the reading-progress mark.
struct RosetteProgress: View {
    var progress: Double
    var size: CGFloat = 96
    var color: Color = .yqAccent
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        ZStack {
            KhatamRosette().stroke(color.opacity(0.14), lineWidth: 1)
            KhatamRosette()
                .trim(from: 0, to: min(1, max(0, progress)))
                .stroke(color, style: StrokeStyle(lineWidth: 1.6, lineCap: .round, lineJoin: .round))
        }
        .frame(width: size, height: size)
        .animation(reduceMotion ? nil : .easeOut(duration: 0.9), value: progress)
        .accessibilityHidden(true)
    }
}

/// Legacy alias used by screens outside this pass.
typealias OttomanRosette = KhatamRosette

struct OttomanPattern: View {
    var color: Color = .yqAccent
    var opacity: Double = 0.09
    var body: some View { GeometricField(color: color, opacity: opacity) }
}
