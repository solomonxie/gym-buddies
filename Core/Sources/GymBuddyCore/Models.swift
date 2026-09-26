import Foundation

public struct Exercise: Identifiable, Hashable, Codable, Sendable {
    public var id: String
    public var name: String
    public var muscleGroup: MuscleGroup
    public var equipment: Equipment
    public var illustration: String?
    public var instructions: String?
    public var isFavourite: Bool

    public init(
        id: String,
        name: String,
        muscleGroup: MuscleGroup,
        equipment: Equipment,
        illustration: String? = nil,
        instructions: String? = nil,
        isFavourite: Bool = false
    ) {
        self.id = id
        self.name = name
        self.muscleGroup = muscleGroup
        self.equipment = equipment
        self.illustration = illustration
        self.instructions = instructions
        self.isFavourite = isFavourite
    }
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

    public init(
        id: String,
        exerciseID: String,
        targetSets: Int,
        targetReps: Int,
        targetWeight: Weight,
        restSeconds: Int? = nil
    ) {
        self.id = id
        self.exerciseID = exerciseID
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

    public init(
        id: String,
        name: String,
        exercises: [WorkoutExercise] = [],
        lastPerformed: Date? = nil
    ) {
        self.id = id
        self.name = name
        self.exercises = exercises
        self.lastPerformed = lastPerformed
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

    public init(
        id: String,
        sessionID: String,
        exerciseID: String,
        setNumber: Int,
        reps: Int,
        weight: Weight,
        completedAt: Date
    ) {
        self.id = id
        self.sessionID = sessionID
        self.exerciseID = exerciseID
        self.setNumber = setNumber
        self.reps = reps
        self.weight = weight
        self.completedAt = completedAt
    }

    /// Reps moved through the full load — the only volume number that survives
    /// comparing a 5×5 against a 3×10.
    public var volume: Weight { weight * reps }
}

public struct WorkoutLog: Identifiable, Hashable, Codable, Sendable {
    public var id: String
    public var workoutID: String
    public var workoutName: String
    public var startedAt: Date
    public var finishedAt: Date
    public var sets: [SetLog]

    public init(
        id: String,
        workoutID: String,
        workoutName: String,
        startedAt: Date,
        finishedAt: Date,
        sets: [SetLog]
    ) {
        self.id = id
        self.workoutID = workoutID
        self.workoutName = workoutName
        self.startedAt = startedAt
        self.finishedAt = finishedAt
        self.sets = sets
    }

    public var duration: TimeInterval { finishedAt.timeIntervalSince(startedAt) }
}
