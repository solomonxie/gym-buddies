import SwiftUI
import GymBuddyCore

/// Front and back figure; the first muscle is primary, the rest secondary.
struct MuscleMap: View {
    let highlighted: [Muscle]

    var body: some View {
        HStack(spacing: 0) {
            BodyFigure(side: .front, highlighted: highlighted)
            BodyFigure(side: .back, highlighted: highlighted)
        }
        .aspectRatio(2 * FigureGeometry.size.width / FigureGeometry.size.height, contentMode: .fit)
        .accessibilityElement()
        .accessibilityLabel(accessibilityText)
    }

    private var accessibilityText: String {
        highlighted.isEmpty
            ? "Muscles not listed"
            : "Works: " + highlighted.map(\.displayName).joined(separator: ", ")
    }
}

/// SF Symbol per equipment; every name exists on iOS 17.
enum EquipmentGlyph {
    static func symbol(for equipment: Equipment) -> String {
        switch equipment {
        case .barbell: "figure.strengthtraining.traditional"
        case .dumbbell: "dumbbell.fill"
        case .machine: "gearshape.2.fill"
        case .cable: "figure.strengthtraining.functional"
        case .kettlebell: "scalemass.fill"
        case .band: "figure.flexibility"
        case .bodyweight: "figure.core.training"
        case .treadmill: "figure.run.treadmill"
        case .none: "figure.mixed.cardio"
        }
    }
}

extension Image {
    init(equipment: Equipment) {
        self.init(systemName: EquipmentGlyph.symbol(for: equipment))
    }
}

/// Exercise-detail header: muscle map with an equipment badge, or the
/// equipment glyph alone when no muscles are listed.
struct ExerciseArt: View {
    let exercise: Exercise

    var body: some View {
        Group {
            if exercise.muscles.isEmpty {
                Image(equipment: exercise.equipment)
                    .font(.system(size: 64, weight: .regular))
                    .foregroundStyle(Theme.chrome)
                    .frame(maxWidth: .infinity, minHeight: 160)
                    .accessibilityLabel(exercise.equipment.displayName)
            } else {
                MuscleMap(highlighted: exercise.muscles)
                    .frame(height: 180)
                    .frame(maxWidth: .infinity)
                    .overlay(alignment: .bottomTrailing) { badge }
            }
        }
        .padding(Theme.Metrics.gutter)
    }

    private var badge: some View {
        Image(equipment: exercise.equipment)
            .font(.system(size: 17, weight: .semibold))
            .foregroundStyle(.white)
            .frame(width: 36, height: 36)
            .background(Theme.chrome, in: Circle())
            .accessibilityLabel(exercise.equipment.displayName)
    }
}

// MARK: - Figure

private struct BodyFigure: View {
    enum Side { case front, back }

    let side: Side
    let highlighted: [Muscle]
    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        Canvas { context, canvasSize in
            let scale = min(canvasSize.width / FigureGeometry.size.width, canvasSize.height / FigureGeometry.size.height)
            let dx = (canvasSize.width - FigureGeometry.size.width * scale) / 2
            let dy = (canvasSize.height - FigureGeometry.size.height * scale) / 2
            context.translateBy(x: dx, y: dy)
            context.scaleBy(x: scale, y: scale)

            let outline = GraphicsContext.Shading.color(.primary.opacity(0.28))
            let neutral = GraphicsContext.Shading.color(.primary.opacity(0.10))
            let base = GraphicsContext.Shading.color(.primary.opacity(0.05))
            let lineWidth = 0.8

            let silhouette = FigureGeometry.silhouette
            context.fill(silhouette, with: base)
            context.stroke(silhouette, with: outline, lineWidth: lineWidth)

            for region in FigureGeometry.regions(side) {
                context.fill(region.path, with: fill(for: region.muscle) ?? neutral)
                context.stroke(region.path, with: outline, lineWidth: lineWidth * 0.8)
            }
            for line in FigureGeometry.detailLines(side) {
                context.stroke(line, with: outline, lineWidth: lineWidth * 0.7)
            }
        }
        .accessibilityHidden(true)
    }

    private func fill(for muscle: Muscle) -> GraphicsContext.Shading? {
        guard let index = highlighted.firstIndex(of: muscle) else { return nil }
        return .color(index == 0 ? Theme.chrome : Theme.chrome.opacity(colorScheme == .dark ? 0.6 : 0.42))
    }
}

private enum FigureGeometry {
    struct Region {
        let muscle: Muscle
        let path: Path
    }

    /// Drawing space for one figure; x is mirrored about the centre line.
    static let size = CGSize(width: 100, height: 216)

    static let silhouette: Path = {
        var p = Path()
        p.addEllipse(in: CGRect(x: 41, y: 2, width: 18, height: 22))
        p.addPath(smoothClosed([
            (45, 22), (44, 29), (36, 31), (24, 33), (17, 38), (14, 48), (14, 62),
            (13, 80), (9, 96), (7, 108), (8, 116), (12, 119), (15, 114),
            (17, 106), (22, 92), (26, 78), (28, 62), (30, 56), (32, 68),
            (32, 84), (31, 96), (30, 106), (30, 124), (31, 146), (32, 160),
            (30, 176), (32, 192), (35, 204), (33, 211), (42, 212), (44, 204),
            (44, 188), (45, 170), (45, 158), (48, 132), (49.5, 112),
        ], mirrored: true))
        return p
    }()

    static func regions(_ side: BodyFigure.Side) -> [Region] {
        switch side {
        case .front: front
        case .back: back
        }
    }

    static func detailLines(_ side: BodyFigure.Side) -> [Path] {
        guard side == .front else { return [] }
        return [70, 79, 88].map { y in
            var p = Path()
            p.move(to: CGPoint(x: 42.5, y: y))
            p.addLine(to: CGPoint(x: 57.5, y: y))
            return p
        }
    }

    private static let front: [Region] = [
        region(.chest, [(49, 35), (38, 33.5), (32, 38), (31, 47), (35, 54), (43, 56), (49, 54)]),
        region(.sideDelts, [(28, 33), (21, 36), (17, 43), (17, 52), (20, 50), (22, 42)]),
        region(.frontDelts, [(36, 32.5), (29, 33.5), (24, 39), (22, 47), (22.5, 52), (27, 49), (31, 42)]),
        region(.biceps, [(22, 54), (18, 58), (16, 68), (17, 78), (21, 79), (25, 70), (27, 58)]),
        region(.forearms, [(16.5, 82), (14, 92), (11, 104), (13.5, 107), (18, 98), (22, 88), (23, 82)]),
        region(.obliques, [(40, 58), (33.5, 56), (32, 66), (33, 80), (36, 93), (42, 99), (41.5, 84), (40.5, 70)]),
        region(.abs, [(49.3, 58), (43, 59), (42.5, 72), (43, 88), (45, 98), (49.3, 102)]),
        region(.quads, [(35, 106), (32, 118), (32, 136), (34, 150), (39, 155), (43, 152), (45, 138), (44.5, 122), (42, 110)]),
        region(.adductors, [(48.5, 108), (45, 116), (45.5, 132), (47.5, 138), (49, 124)]),
        region(.calves, [(33.5, 162), (31.5, 172), (33, 188), (37, 198), (41, 196), (43, 180), (42.5, 166), (38, 160)]),
    ].flatMap(mirroredPair)

    private static let back: [Region] = [
        region(.traps, [(49.3, 25), (45, 28), (36, 32), (32, 35), (39, 38), (45, 46), (49.3, 62)]),
        region(.sideDelts, [(27, 33.5), (20, 37), (17, 44), (17, 52), (20, 50), (22, 42)]),
        region(.rearDelts, [(33, 36), (28, 34.5), (23.5, 40), (22, 48), (23, 52), (28, 47), (32, 41)]),
        region(.triceps, [(22, 54), (18, 58), (16, 68), (17, 78), (21, 79), (25, 70), (27, 58)]),
        region(.forearms, [(16.5, 82), (14, 92), (11, 104), (13.5, 107), (18, 98), (22, 88), (23, 82)]),
        region(.lats, [(42, 47), (37.5, 40.5), (32, 43), (30.5, 53), (33, 68), (37.5, 84), (41.5, 80), (44, 66), (44.5, 55)]),
        region(.lowerBack, [(49.3, 66), (47, 70), (44, 84), (43, 98), (49.3, 100)]),
        region(.glutes, [(49.3, 102), (40, 99.5), (33, 105), (32, 116), (37, 124), (45, 124), (49.3, 118)]),
        region(.hamstrings, [(33, 127), (32, 140), (35, 152), (40, 156), (44.5, 150), (47, 136), (47, 127), (40, 126.5)]),
        region(.calves, [(34, 160), (31.5, 172), (33.5, 186), (38, 194), (43, 188), (44, 172), (42, 162), (38, 159)]),
    ].flatMap(mirroredPair)

    private static func region(_ muscle: Muscle, _ points: [(CGFloat, CGFloat)]) -> Region {
        Region(muscle: muscle, path: smoothClosed(points, mirrored: false))
    }

    private static func mirroredPair(_ r: Region) -> [Region] {
        [r, Region(muscle: r.muscle, path: r.path.applying(mirror))]
    }

    private static let mirror = CGAffineTransform(a: -1, b: 0, c: 0, d: 1, tx: FigureGeometry.size.width, ty: 0)

    /// Closed curve through the midpoints of `points`, using each point as a
    /// control. `mirrored` appends the reflection so one side draws the whole.
    private static func smoothClosed(_ points: [(CGFloat, CGFloat)], mirrored: Bool) -> Path {
        var pts = points.map { CGPoint(x: $0.0, y: $0.1) }
        if mirrored {
            pts += pts.reversed().map { CGPoint(x: FigureGeometry.size.width - $0.x, y: $0.y) }
        }
        guard pts.count > 2 else { return Path() }
        func mid(_ a: CGPoint, _ b: CGPoint) -> CGPoint { CGPoint(x: (a.x + b.x) / 2, y: (a.y + b.y) / 2) }
        var p = Path()
        p.move(to: mid(pts[pts.count - 1], pts[0]))
        for i in pts.indices {
            p.addQuadCurve(to: mid(pts[i], pts[(i + 1) % pts.count]), control: pts[i])
        }
        p.closeSubpath()
        return p
    }
}
