import Foundation

/// What the count on a set means. A plank is held in seconds, a treadmill
/// is walked in minutes, a pool is swum in lengths; calling any of them
/// "reps" puts the wrong number on screen.
public enum Measure: String, Codable, Sendable, CaseIterable {
    case reps, seconds, minutes, laps

    /// What a line on this equipment can count in. Laps need a pool to be a distance.
    public static func options(for equipment: Equipment) -> [Measure] {
        equipment == .pool ? [.laps, .minutes] : [.reps, .seconds, .minutes]
    }

    public var displayName: String {
        switch self {
        case .reps: "Reps"
        case .seconds: "Seconds"
        case .minutes: "Minutes"
        case .laps: "Laps"
        }
    }

    /// One tap of the stepper.
    public var step: Int { self == .seconds ? 5 : 1 }

    /// Where a new plan line starts.
    public var defaultTarget: Int {
        switch self {
        case .reps: 10
        case .seconds: 30
        case .minutes: 20
        case .laps: 4
        }
    }

    /// How long a set of `count` lasts; nil when the count is reps.
    public func duration(_ count: Int) -> TimeInterval? {
        switch self {
        case .reps, .laps: nil
        case .seconds: TimeInterval(count)
        case .minutes: TimeInterval(count * 60)
        }
    }

    /// `10`, `60s`, `20 min`.
    public func format(_ count: Int) -> String {
        switch self {
        case .reps: "\(count)"
        case .seconds: "\(count)s"
        case .minutes: "\(count) min"
        case .laps: count == 1 ? "1 lap" : "\(count) laps"
        }
    }
}

public struct Exercise: Identifiable, Hashable, Codable, Sendable {
    public var id: String
    public var name: String
    public var muscleGroup: MuscleGroup
    public var equipment: Equipment
    /// Primary muscles first; drives the muscle-map highlight.
    public var muscles: [Muscle]
    /// Reviewed how-to steps, one per line. Absent rather than guessed.
    public var instructions: String?
    public var isFavourite: Bool
    public var isCustom: Bool
    /// What the reps field counts.
    public var measure: Measure

    public init(
        id: String,
        name: String,
        muscleGroup: MuscleGroup,
        equipment: Equipment,
        muscles: [Muscle] = [],
        instructions: String? = nil,
        isFavourite: Bool = false,
        isCustom: Bool = false,
        measure: Measure = .reps
    ) {
        self.id = id
        self.name = name
        self.muscleGroup = muscleGroup
        self.equipment = equipment
        self.muscles = muscles
        self.instructions = instructions
        self.isFavourite = isFavourite
        self.isCustom = isCustom
        self.measure = measure
    }

    private enum CodingKeys: String, CodingKey {
        case id, name, muscleGroup, equipment, muscles, instructions, isFavourite, isCustom, measure, isTimed
    }

    /// Reads sessions saved before `measure` existed, when a Bool said "seconds".
    public init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        id = try c.decode(String.self, forKey: .id)
        name = try c.decode(String.self, forKey: .name)
        muscleGroup = try c.decode(MuscleGroup.self, forKey: .muscleGroup)
        equipment = try c.decode(Equipment.self, forKey: .equipment)
        muscles = try c.decodeIfPresent([Muscle].self, forKey: .muscles) ?? []
        instructions = try c.decodeIfPresent(String.self, forKey: .instructions)
        isFavourite = try c.decodeIfPresent(Bool.self, forKey: .isFavourite) ?? false
        isCustom = try c.decodeIfPresent(Bool.self, forKey: .isCustom) ?? false
        if let measure = try c.decodeIfPresent(Measure.self, forKey: .measure) {
            self.measure = measure
        } else {
            self.measure = try c.decodeIfPresent(Bool.self, forKey: .isTimed) == true ? .seconds : .reps
        }
    }

    public func encode(to encoder: Encoder) throws {
        var c = encoder.container(keyedBy: CodingKeys.self)
        try c.encode(id, forKey: .id)
        try c.encode(name, forKey: .name)
        try c.encode(muscleGroup, forKey: .muscleGroup)
        try c.encode(equipment, forKey: .equipment)
        try c.encode(muscles, forKey: .muscles)
        try c.encodeIfPresent(instructions, forKey: .instructions)
        try c.encode(isFavourite, forKey: .isFavourite)
        try c.encode(isCustom, forKey: .isCustom)
        try c.encode(measure, forKey: .measure)
    }

    public var isTimed: Bool { measure != .reps }

    public var steps: [String] {
        (instructions ?? "").split(separator: "\n").map(String.init)
    }

    /// One tap of the reps stepper: a rep, or five seconds of a hold.
    public var repStep: Int { measure.step }
}

/// One line of a workout: an exercise plus what you intend to do to it.
public struct WorkoutExercise: Identifiable, Hashable, Codable, Sendable {
    public var id: String
    public var exerciseID: String
    public var targetSets: Int
    public var targetReps: Int
    public var targetWeight: Weight
    /// Overrides the app-wide default when this movement needs longer.
    public var restSeconds: Int?
    /// Treadmill incline, percent. Nil for equipment without one.
    public var targetIncline: Double?
    /// Overrides the exercise's measure — an air bike in minutes in one
    /// workout, in reps in another. Nil means the exercise's own.
    public var measure: Measure?
    /// One length of the pool. Nil for anything that isn't swum.
    public var poolLength: PoolLength?

    public init(
        id: String,
        exerciseID: String,
        targetSets: Int,
        targetReps: Int,
        targetWeight: Weight,
        restSeconds: Int? = nil,
        targetIncline: Double? = nil,
        measure: Measure? = nil,
        poolLength: PoolLength? = nil
    ) {
        self.measure = measure
        self.poolLength = poolLength
        self.id = id
        self.exerciseID = exerciseID
        self.targetIncline = targetIncline
        self.targetSets = targetSets
        self.targetReps = targetReps
        self.targetWeight = targetWeight
        self.restSeconds = restSeconds
    }
}

public struct Workout: Identifiable, Hashable, Codable, Sendable {
    public var id: String
    public var name: String
    public var exercises: [WorkoutExercise]
    public var lastPerformed: Date?
    /// Where it's meant to be done. Empty means anywhere.
    public var gymIDs: [String]

    public init(
        id: String,
        name: String,
        exercises: [WorkoutExercise] = [],
        lastPerformed: Date? = nil,
        gymIDs: [String] = []
    ) {
        self.id = id
        self.name = name
        self.exercises = exercises
        self.lastPerformed = lastPerformed
        self.gymIDs = gymIDs
    }

    private enum CodingKeys: String, CodingKey {
        case id, name, exercises, lastPerformed, gymIDs
    }

    /// Reads sessions saved before workouts had gyms.
    public init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        id = try c.decode(String.self, forKey: .id)
        name = try c.decode(String.self, forKey: .name)
        exercises = try c.decode([WorkoutExercise].self, forKey: .exercises)
        lastPerformed = try c.decodeIfPresent(Date.self, forKey: .lastPerformed)
        gymIDs = try c.decodeIfPresent([String].self, forKey: .gymIDs) ?? []
    }
}

extension WorkoutExercise {
    public func measure(for exercise: Exercise) -> Measure {
        measure ?? exercise.measure
    }

    /// Switching what the line counts restarts its target: 20 minutes
    /// doesn't become 20 reps.
    public mutating func count(in newMeasure: Measure, for exercise: Exercise) {
        guard newMeasure != measure(for: exercise) else { return }
        measure = newMeasure == exercise.measure ? nil : newMeasure
        targetReps = newMeasure.defaultTarget
    }

    /// The pool this line is swum in; nil when the exercise isn't swum.
    public func pool(for exercise: Exercise) -> PoolLength? {
        exercise.equipment == .pool ? (poolLength ?? .default) : nil
    }
}

/// What actually happened, which is never assumed to match the plan.
public struct SetLog: Identifiable, Hashable, Codable, Sendable {
    public var id: String
    public var sessionID: String
    public var exerciseID: String
    /// 1-based, so it reads the same as "Set 2/3" on screen.
    public var setNumber: Int
    public var reps: Int
    public var weight: Weight
    public var completedAt: Date
    /// The plan line it was logged against, so a movement listed twice keeps
    /// its two lines apart and drift can be pushed back to the right one.
    public var planLineID: String?
    /// What the plan asked for, kept so "under target" survives plan edits.
    public var targetReps: Int?
    /// Treadmill incline, percent — a setting, not a load, so never a `Weight`.
    public var incline: Double?
    /// When Start was tapped; nil if the set was logged without it.
    public var startedAt: Date?
    /// What `reps` counted. Nil on sets logged before lines could override it.
    public var measure: Measure?
    /// The pool the laps were swum in, so they stay a distance.
    public var poolLength: PoolLength?

    public init(
        id: String,
        sessionID: String,
        exerciseID: String,
        setNumber: Int,
        reps: Int,
        weight: Weight,
        completedAt: Date,
        planLineID: String? = nil,
        targetReps: Int? = nil,
        incline: Double? = nil,
        startedAt: Date? = nil,
        measure: Measure? = nil,
        poolLength: PoolLength? = nil
    ) {
        self.measure = measure
        self.poolLength = poolLength
        self.incline = incline
        self.startedAt = startedAt
        self.id = id
        self.sessionID = sessionID
        self.exerciseID = exerciseID
        self.setNumber = setNumber
        self.reps = reps
        self.weight = weight
        self.completedAt = completedAt
        self.planLineID = planLineID
        self.targetReps = targetReps
    }

    public var isUnderTarget: Bool {
        targetReps.map { reps < $0 } ?? false
    }

    /// Reps moved through the full load — the only volume number that survives
    /// comparing a 5×5 against a 3×10.
    public var volume: Weight { weight * reps }

    public func measure(for exercise: Exercise?) -> Measure {
        measure ?? exercise?.measure ?? .reps
    }

    /// Laps times the pool; nil for anything not counted in laps.
    public var distance: Double? {
        guard measure == .laps, let poolLength else { return nil }
        return Double(reps) * poolLength.length
    }

    public var duration: TimeInterval? {
        startedAt.map { max(0, completedAt.timeIntervalSince($0)) }
    }
}

public struct WorkoutLog: Identifiable, Hashable, Codable, Sendable {
    public var id: String
    public var workoutID: String
    public var workoutName: String
    public var startedAt: Date
    public var finishedAt: Date
    public var sets: [SetLog]
    /// Exercises passed over with nothing logged, in plan order.
    public var skippedExerciseIDs: [String]
    public var notes: String

    public init(
        id: String,
        workoutID: String,
        workoutName: String,
        startedAt: Date,
        finishedAt: Date,
        sets: [SetLog],
        skippedExerciseIDs: [String] = [],
        notes: String = ""
    ) {
        self.id = id
        self.workoutID = workoutID
        self.workoutName = workoutName
        self.startedAt = startedAt
        self.finishedAt = finishedAt
        self.sets = sets
        self.skippedExerciseIDs = skippedExerciseIDs
        self.notes = notes
    }

    /// Exercise IDs in the order they were first logged.
    public var exerciseOrder: [String] {
        var seen = Set<String>()
        return sets.map(\.exerciseID).filter { seen.insert($0).inserted }
    }

    public var duration: TimeInterval { finishedAt.timeIntervalSince(startedAt) }
}
