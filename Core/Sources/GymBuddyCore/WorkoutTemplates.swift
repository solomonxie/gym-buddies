import Foundation

public enum TemplateCategory: String, CaseIterable, Sendable, Identifiable {
    case gym, strength, daily, sport, swim, pregnancy

    public var id: String { rawValue }

    public var displayName: String {
        switch self {
        case .gym: "Gym basics"
        case .strength: "Strength"
        case .daily: "Around the workday"
        case .sport: "Sport"
        case .swim: "Swim"
        case .pregnancy: "Pregnancy"
        }
    }
}

/// A ready-made workout. Loads are starting points for someone new to the
/// movement — double progression moves them from there.
public struct WorkoutTemplate: Identifiable, Sendable {
    public struct Line: Sendable {
        public let exerciseID: String
        public let sets: Int
        public let count: Int
        public let kilograms: Double
        public let rest: Int?
        public let measure: Measure?
        public let incline: Double?
    }

    public let id: String
    public let name: String
    public let category: TemplateCategory
    public let summary: String
    /// The reasoning, short: what makes it work and what to watch.
    public let notes: [String]
    /// When it promises to fit a time slot, the most minutes it may plan.
    public let fitsIn: Int?
    public let lines: [Line]

    public var usesPool: Bool {
        lines.contains { SeedLibrary.byID[$0.exerciseID]?.equipment == .pool }
    }

    /// A fresh workout: new IDs, every swim line in `pool`.
    public func workout(
        id: String = UUID().uuidString,
        pool: PoolLength = .default,
        catalogue: [String: Exercise] = SeedLibrary.byID,
        newLineID: () -> String = { UUID().uuidString }
    ) -> Workout {
        Workout(id: id, name: name, exercises: lines.map { line in
            let equipment = catalogue[line.exerciseID]?.equipment
            return WorkoutExercise(
                id: newLineID(), exerciseID: line.exerciseID,
                targetSets: line.sets, targetReps: line.count,
                targetWeight: Weight(kilograms: line.kilograms),
                restSeconds: line.rest,
                targetIncline: equipment?.inclineStep == nil ? nil : (line.incline ?? 0),
                measure: line.measure,
                poolLength: equipment == .pool ? pool : nil
            )
        })
    }
}

private func l(
    _ exerciseID: String, _ sets: Int, _ count: Int, kg: Double = 0,
    rest: Int? = nil, in measure: Measure? = nil, incline: Double? = nil
) -> WorkoutTemplate.Line {
    .init(exerciseID: exerciseID, sets: sets, count: count, kilograms: kg,
          rest: rest, measure: measure, incline: incline)
}

/// Built from mainstream guidance: ACSM for strength and hypertrophy (6–15
/// reps near failure, 2–3 min on heavy compounds), ACOG for pregnancy, and
/// the usual warm-up / main set / cool-down shape of a swim session.
public enum TemplateLibrary {
    public static let all: [WorkoutTemplate] = [
        WorkoutTemplate(
            id: "light-gym-30", name: "Light Gym · 30 min", category: .gym,
            summary: "Full body on machines, two easy sets each. For busy days or getting back into it.",
            notes: [
                "End each set with 3–4 reps still in the tank",
                "Machines guide the path, so form mostly takes care of itself",
                "Twice a week keeps the strength you have",
            ],
            fitsIn: 30,
            lines: [
                l("treadmill-walking", 1, 5, rest: 30, incline: 3),
                l("leg-press", 2, 12, kg: 60, rest: 60),
                l("machine-chest-press", 2, 12, kg: 25, rest: 60),
                l("lat-pull-downs", 2, 12, kg: 30, rest: 60),
                l("seated-leg-curls", 2, 12, kg: 25, rest: 60),
                l("seated-machine-presses", 2, 12, kg: 15, rest: 60),
                l("planking", 2, 30, rest: 45),
            ]
        ),
        WorkoutTemplate(
            id: "muscle-upper", name: "Muscle Building · Upper", category: .strength,
            summary: "Heavy upper-body day. Alternate with Lower, four days a week in all.",
            notes: [
                "6–12 reps, stopping each set 1–2 reps short of failure",
                "Top of the rep range on every set? Add weight next time",
                "Rest 2–3 min on the big lifts so the next set stays heavy",
            ],
            fitsIn: nil,
            lines: [
                l("barbell-bench-press", 4, 8, kg: 50, rest: 150),
                l("bent-over-barbell-rows", 4, 8, kg: 45, rest: 150),
                l("seated-dumbbell-shoulder-press", 3, 10, kg: 14, rest: 120),
                l("lat-pull-downs", 3, 10, kg: 45, rest: 90),
                l("incline-dumbbell-press", 3, 10, kg: 16, rest: 90),
                l("dumbbell-lateral-raises", 3, 15, kg: 6, rest: 60),
                l("rope-pushdowns", 3, 12, kg: 20, rest: 60),
                l("dumbbell-curls", 3, 12, kg: 10, rest: 60),
            ]
        ),
        WorkoutTemplate(
            id: "muscle-lower", name: "Muscle Building · Lower", category: .strength,
            summary: "Heavy leg day with a little core. Alternate with Upper.",
            notes: [
                "Squat first, while you're fresh; it's the one that moves the needle",
                "Top of the rep range on every set? Add weight next time",
                "10+ hard sets per muscle a week is the target for growth",
            ],
            fitsIn: nil,
            lines: [
                l("barbell-squats", 4, 6, kg: 60, rest: 180),
                l("romanian-deadlifts", 3, 8, kg: 50, rest: 150),
                l("leg-press", 3, 10, kg: 100, rest: 120),
                l("lying-leg-curls", 3, 12, kg: 30, rest: 90),
                l("walking-lunges", 2, 10, kg: 12, rest: 90),
                l("standing-calf-raises", 4, 12, kg: 40, rest: 60),
                l("hanging-leg-raises", 3, 10, rest: 60),
            ]
        ),
        WorkoutTemplate(
            id: "core-strength", name: "Core Strength", category: .strength,
            summary: "Trains the trunk to resist bending and twisting — what protects the back.",
            notes: [
                "Brace as if about to be poked in the stomach, and keep breathing",
                "Anti-rotation and anti-extension first, crunching last",
                "End a hold when your hips sag, not when the clock says",
            ],
            fitsIn: nil,
            lines: [
                l("dead-bugs", 3, 10, rest: 45),
                l("bird-dogs", 3, 8, rest: 45),
                l("side-plank", 3, 30, rest: 45),
                l("pallof-press", 3, 10, kg: 10, rest: 45),
                l("ab-wheel-rollouts", 3, 8, rest: 60),
                l("suitcase-carries", 3, 40, kg: 16, rest: 60, in: .seconds),
                l("hanging-knee-raises", 3, 10, rest: 60),
            ]
        ),
        WorkoutTemplate(
            id: "pre-work", name: "Pre-Work Wake-Up · 15 min", category: .daily,
            summary: "No equipment, fits in a living room. Loosens the joints and gets the blood moving.",
            notes: [
                "Brisk, short rests; you should feel awake, not tired",
                "Mobility first, then strength",
                "Good on days with no other training",
            ],
            fitsIn: 15,
            lines: [
                l("jumping-jacks", 1, 60, rest: 30),
                l("cat-cow", 1, 10, rest: 15),
                l("worlds-greatest-stretch", 1, 6, rest: 15),
                l("bodyweight-squats", 2, 15, rest: 30),
                l("push-ups", 2, 10, rest: 30),
                l("glute-bridges", 2, 15, rest: 30),
                l("planking", 1, 45, rest: 30),
            ]
        ),
        WorkoutTemplate(
            id: "lunch-break", name: "Lunch Break · 30 min", category: .daily,
            summary: "Dumbbell full body that fits a lunch hour, moderate enough to skip the long shower.",
            notes: [
                "Moderate effort keeps the sweat down and the afternoon sharp",
                "One rack of dumbbells covers all of it",
                "Short on time? Pair squat with press and row with deadlift",
            ],
            fitsIn: 30,
            lines: [
                l("stationary-bike", 1, 5, rest: 30),
                l("goblet-squats", 3, 10, kg: 16, rest: 60),
                l("dumbbell-bench-press", 3, 10, kg: 16, rest: 60),
                l("one-arm-dumbbell-rows", 3, 10, kg: 18, rest: 60),
                l("dumbbell-romanian-deadlifts", 3, 10, kg: 16, rest: 60),
                l("planking", 2, 40, rest: 45),
            ]
        ),
        WorkoutTemplate(
            id: "after-work", name: "After Work · Desk Reset", category: .daily,
            summary: "Undoes a day of sitting: strengthens the back, opens the hips and chest.",
            notes: [
                "More pulling than pushing, to balance hours at a keyboard",
                "Stretches go last, held long and easy",
                "Moderate effort, so it doesn't cost you sleep",
            ],
            fitsIn: nil,
            lines: [
                l("rowing-machine", 1, 8, rest: 60),
                l("face-pulls", 3, 15, kg: 15, rest: 60),
                l("romanian-deadlifts", 3, 10, kg: 40, rest: 90),
                l("lat-pull-downs", 3, 12, kg: 35, rest: 60),
                l("chin-tucks", 2, 10, rest: 30),
                l("thoracic-open-books", 2, 8, rest: 30),
                l("hip-flexor-stretch", 2, 30, rest: 30),
                l("doorway-chest-stretch", 2, 30, rest: 30),
                l("childs-pose", 1, 60),
            ]
        ),
        WorkoutTemplate(
            id: "leisure", name: "Leisure · Easy Movement", category: .daily,
            summary: "Easy cardio and a few light moves. Heart rate where you can still chat.",
            notes: [
                "Keep cardio easy enough to hold a conversation",
                "Light loads only; nothing should feel like a grind",
                "Skip anything you don't feel like today",
            ],
            fitsIn: nil,
            lines: [
                l("elliptical", 1, 15, rest: 60),
                l("kettlebell-swings", 3, 12, kg: 12, rest: 60),
                l("farmer-carries", 3, 40, kg: 16, rest: 60, in: .seconds),
                l("band-pull-aparts", 2, 15, rest: 45),
                l("rowing-machine", 1, 10, rest: 60),
                l("worlds-greatest-stretch", 1, 6),
            ]
        ),
        WorkoutTemplate(
            id: "baseball", name: "Baseball · Off-Season", category: .sport,
            summary: "Rotational power, strong legs and shoulder care for throwing athletes.",
            notes: [
                "Power first while fresh: fast reps, full rest",
                "Landmine and dumbbell presses spare the throwing shoulder",
                "Rotator cuff work comes last and never gets skipped",
            ],
            fitsIn: nil,
            lines: [
                l("worlds-greatest-stretch", 1, 6, rest: 30),
                l("medicine-ball-rotational-throws", 3, 5, rest: 90),
                l("box-jumps", 3, 5, rest: 90),
                l("trap-bar-deadlifts", 4, 5, kg: 70, rest: 150),
                l("bulgarian-split-squats", 3, 8, kg: 12, rest: 90),
                l("lateral-bounds", 3, 6, rest: 60),
                l("one-arm-dumbbell-rows", 3, 10, kg: 20, rest: 60),
                l("landmine-press", 3, 8, kg: 20, rest: 90),
                l("pallof-press", 3, 10, kg: 12.5, rest: 60),
                l("cable-external-rotations", 2, 15, kg: 5, rest: 45),
                l("face-pulls", 2, 15, kg: 15, rest: 45),
            ]
        ),
        WorkoutTemplate(
            id: "swim-freestyle", name: "Swim · Freestyle Endurance", category: .swim,
            summary: "Warm-up, drills, main set, cool-down. 36 lengths: 900 m in a 25 m pool.",
            notes: [
                "Main-set reps should feel steady, not all-out",
                "Rest at the wall between reps; the rest is part of the plan",
                "Kick and pull drills fix the stroke one half at a time",
            ],
            fitsIn: nil,
            lines: [
                l("freestyle-swim", 1, 4, rest: 60),
                l("kickboard-kicks", 4, 1, rest: 20),
                l("pull-buoy-swim", 4, 2, rest: 20),
                l("freestyle-swim", 8, 2, rest: 30),
                l("breaststroke-swim", 1, 4),
            ]
        ),
        WorkoutTemplate(
            id: "swim-strokes", name: "Swim · Four Strokes", category: .swim,
            summary: "Every stroke plus medley. 36 lengths: 900 m in a 25 m pool.",
            notes: [
                "Butterfly in single lengths until it holds together",
                "Medley order: fly, back, breast, free",
                "Easy freestyle either side",
            ],
            fitsIn: nil,
            lines: [
                l("freestyle-swim", 1, 4, rest: 60),
                l("backstroke-swim", 4, 2, rest: 30),
                l("breaststroke-swim", 4, 2, rest: 30),
                l("butterfly-swim", 4, 1, rest: 45),
                l("individual-medley", 2, 4, rest: 60),
                l("freestyle-swim", 1, 4),
            ]
        ),
        WorkoutTemplate(
            id: "pregnancy-strength", name: "Pregnancy · Gentle Strength", category: .pregnancy,
            summary: "Moderate full body with nothing done lying on your back. Aim for about 150 active minutes a week.",
            notes: [
                "Get the OK from your midwife or doctor first",
                "You should be able to talk throughout; never hold your breath to lift",
                "Stop for dizziness, pain, bleeding, leaking fluid or contractions",
                "No lying flat on your back after the first trimester",
            ],
            fitsIn: nil,
            lines: [
                l("stationary-bike", 1, 10, rest: 60),
                l("goblet-squats", 2, 12, kg: 8, rest: 90),
                l("seated-cable-rows", 2, 12, kg: 20, rest: 90),
                l("seated-dumbbell-shoulder-press", 2, 12, kg: 6, rest: 90),
                l("band-pull-aparts", 2, 15, rest: 60),
                l("bird-dogs", 2, 8, rest: 60),
                l("side-lying-leg-raises", 2, 12, rest: 60),
                l("cat-cow", 1, 10, rest: 30),
                l("pelvic-floor-contractions", 2, 10, rest: 60),
            ]
        ),
        WorkoutTemplate(
            id: "pregnancy-pool", name: "Pregnancy · Pool", category: .pregnancy,
            summary: "Water takes the weight off the joints. Easy lengths and walking, no racing.",
            notes: [
                "Get the OK from your midwife or doctor first",
                "Freestyle and kicking are easy on the pelvis; skip breaststroke kick if it twinges",
                "Stop for dizziness, pain, bleeding, leaking fluid or contractions",
            ],
            fitsIn: nil,
            lines: [
                l("water-walking", 1, 10, rest: 60),
                l("freestyle-swim", 6, 2, rest: 45),
                l("kickboard-kicks", 4, 1, rest: 30),
                l("water-walking", 1, 5),
            ]
        ),
    ]

    public static func templates(in category: TemplateCategory) -> [WorkoutTemplate] {
        all.filter { $0.category == category }
    }
}
