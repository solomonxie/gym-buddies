import Foundation

/// A workout being performed right now.
///
/// The plan is a suggestion; `logs` is the truth. Nudging reps or weight
/// mid-set changes what gets written down, never the saved workout — pushing a
/// change back into the template is a separate, deliberate act, because "I went
/// lighter today because my shoulder hurt" must not quietly rewrite the plan.
public struct WorkoutSession: Sendable {
    public struct Entry: Identifiable, Hashable, Sendable {
        public var exercise: Exercise
        public var plan: WorkoutExercise
        public var isSkipped: Bool = false

        public var id: String { plan.id }

        public init(exercise: Exercise, plan: WorkoutExercise, isSkipped: Bool = false) {
            self.exercise = exercise
            self.plan = plan
            self.isSkipped = isSkipped
        }
    }

    public enum SetOutcome: Equatable, Sendable {
        case restThenNextSet(seconds: Int)
        case restThenNextExercise(name: String, seconds: Int)
        case workoutComplete
    }

    public let id: String
    public let workoutID: String
    public let workoutName: String
    public let startedAt: Date
    public let defaultRestSeconds: Int

    public private(set) var entries: [Entry]
    public private(set) var exerciseIndex: Int
    public private(set) var logs: [SetLog]
    /// Counted per plan line, not per exercise — the same movement can legally
    /// appear twice in one workout, and merging their counters strands sets.
    public private(set) var completedByPlan: [String: Int]
    public private(set) var workingReps: Int
    public private(set) var workingWeight: Weight

    public init(
        id: String = UUID().uuidString,
        workout: Workout,
        exercises: [String: Exercise],
        startedAt: Date,
        defaultRestSeconds: Int = 60
    ) {
        self.id = id
        self.workoutID = workout.id
        self.workoutName = workout.name
        self.startedAt = startedAt
        self.defaultRestSeconds = defaultRestSeconds
        self.entries = workout.exercises.compactMap { plan in
            exercises[plan.exerciseID].map { Entry(exercise: $0, plan: plan) }
        }
        self.exerciseIndex = 0
        self.logs = []
        self.completedByPlan = [:]
        self.workingReps = entries.first?.plan.targetReps ?? 0
        self.workingWeight = entries.first?.plan.targetWeight ?? .zero
    }

    // MARK: - Where we are

    public var currentEntry: Entry? {
        entries.indices.contains(exerciseIndex) ? entries[exerciseIndex] : nil
    }

    public var isFinished: Bool { currentEntry == nil }

    public func completedSets(for planID: String) -> Int {
        completedByPlan[planID] ?? 0
    }

    /// 1-based, so it reads as the "Set 2/3" on screen rather than an index.
    public var currentSetNumber: Int {
        guard let entry = currentEntry else { return 0 }
        return min(completedSets(for: entry.id) + 1, entry.plan.targetSets)
    }

    public var upcoming: [Entry] {
        guard exerciseIndex + 1 < entries.count else { return [] }
        return Array(entries[(exerciseIndex + 1)...])
    }

    public func elapsed(at now: Date) -> TimeInterval {
        max(0, now.timeIntervalSince(startedAt))
    }

    public var restSecondsForCurrentExercise: Int {
        currentEntry?.plan.restSeconds ?? defaultRestSeconds
    }

    // MARK: - Nudging the set about to be logged

    public mutating func adjustReps(by delta: Int) {
        workingReps = max(0, workingReps + delta)
    }

    public mutating func adjustWeight(by steps: Int, in unit: WeightUnit) {
        guard let equipment = currentEntry?.exercise.equipment else { return }
        workingWeight = equipment.stepped(workingWeight, by: steps, in: unit)
    }

    public mutating func setWorkingValues(reps: Int? = nil, weight: Weight? = nil) {
        if let reps { workingReps = max(0, reps) }
        if let weight { workingWeight = weight }
    }

    /// The "CHANGE" under the set counter. Dropping below what's already logged
    /// would strand completed sets, so it can't go lower than that.
    public mutating func changeTargetSets(to count: Int) {
        guard exerciseIndex < entries.count else { return }
        let alreadyDone = completedSets(for: entries[exerciseIndex].id)
        entries[exerciseIndex].plan.targetSets = max(max(1, alreadyDone), count)
    }

    // MARK: - Moving through it

    @discardableResult
    public mutating func completeSet(
        at now: Date,
        logID: String = UUID().uuidString
    ) -> SetOutcome {
        guard let entry = currentEntry else { return .workoutComplete }

        logs.append(
            SetLog(
                id: logID,
                sessionID: id,
                exerciseID: entry.exercise.id,
                setNumber: currentSetNumber,
                reps: workingReps,
                weight: workingWeight,
                completedAt: now
            )
        )

        completedByPlan[entry.id, default: 0] += 1

        let rest = restSecondsForCurrentExercise
        if completedSets(for: entry.id) < entry.plan.targetSets {
            return .restThenNextSet(seconds: rest)
        }
        return advance(rest: rest)
    }

    /// The ▶| button. Anything already logged for the exercise stays logged.
    @discardableResult
    public mutating func skipExercise() -> SetOutcome {
        guard exerciseIndex < entries.count else { return .workoutComplete }
        entries[exerciseIndex].isSkipped = completedSets(for: entries[exerciseIndex].id) == 0
        return advance(rest: 0)
    }

    /// Picking a different exercise out of the list — order is a suggestion
    /// when the rack you wanted is busy.
    public mutating func jump(toExerciseAt index: Int) {
        guard entries.indices.contains(index) else { return }
        exerciseIndex = index
        loadWorkingValues()
    }

    private mutating func advance(rest: Int) -> SetOutcome {
        exerciseIndex += 1
        loadWorkingValues()
        guard let next = currentEntry else { return .workoutComplete }
        return .restThenNextExercise(name: next.exercise.name, seconds: rest)
    }

    private mutating func loadWorkingValues() {
        guard let entry = currentEntry else { return }
        workingReps = entry.plan.targetReps
        workingWeight = entry.plan.targetWeight
    }

    // MARK: - Finishing

    public func finish(at now: Date, logID: String = UUID().uuidString) -> WorkoutLog {
        WorkoutLog(
            id: logID,
            workoutID: workoutID,
            workoutName: workoutName,
            startedAt: startedAt,
            finishedAt: now,
            sets: logs
        )
    }

    public static func formatElapsed(_ interval: TimeInterval) -> String {
        RestTimer.format(interval)
    }
}
