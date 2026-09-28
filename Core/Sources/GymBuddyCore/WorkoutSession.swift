import Foundation

/// A workout being performed right now.
///
/// The plan is a suggestion; `logs` is the truth. Nudging reps or weight
/// mid-set changes what gets written down, never the saved workout — pushing a
/// change back into the template is a separate, deliberate act, because "I went
/// lighter today because my shoulder hurt" must not quietly rewrite the plan.
public struct WorkoutSession: Codable, Sendable {
    public struct Entry: Identifiable, Hashable, Codable, Sendable {
        public var exercise: Exercise
        public var plan: WorkoutExercise
        public var isSkipped: Bool = false

        public var id: String { plan.id }
        public var measure: Measure { plan.measure(for: exercise) }

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
    /// Rest after an exercise's last set, unless its line overrides it.
    public let restBetweenExercisesSeconds: Int
    public var notes: String = ""

    public private(set) var entries: [Entry]
    public private(set) var exerciseIndex: Int
    public private(set) var logs: [SetLog]
    /// Counted per plan line, not per exercise — the same movement can legally
    /// appear twice in one workout, and merging their counters strands sets.
    public private(set) var completedByPlan: [String: Int]
    public private(set) var workingReps: Int
    public private(set) var workingWeight: Weight
    /// Treadmill incline for the set about to be logged; nil without one.
    public private(set) var workingIncline: Double?
    /// Exercises left behind, most recent last, for Back. Optional so
    /// sessions saved before it existed still decode.
    private var cameFrom: [Int]?
    /// When Start was tapped for the set about to be logged.
    public private(set) var setStartedAt: Date?
    /// Plan lines whose progression offer has been shown — once per session.
    public private(set) var progressionOffered: Set<String> = []

    public init(
        id: String = UUID().uuidString,
        workout: Workout,
        exercises: [String: Exercise],
        startedAt: Date,
        defaultRestSeconds: Int = 60,
        restBetweenExercisesSeconds: Int? = nil
    ) {
        self.id = id
        self.workoutID = workout.id
        self.workoutName = workout.name
        self.startedAt = startedAt
        self.defaultRestSeconds = defaultRestSeconds
        self.restBetweenExercisesSeconds = restBetweenExercisesSeconds ?? defaultRestSeconds
        self.entries = workout.exercises.compactMap { plan in
            exercises[plan.exerciseID].map { Entry(exercise: $0, plan: plan) }
        }
        self.exerciseIndex = 0
        self.logs = []
        self.completedByPlan = [:]
        self.workingReps = entries.first?.plan.targetReps ?? 0
        self.workingWeight = entries.first?.plan.targetWeight ?? .zero
        self.workingIncline = entries.first.flatMap(Self.startingIncline)
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

    public func isComplete(_ entry: Entry) -> Bool {
        completedSets(for: entry.id) >= entry.plan.targetSets
    }

    /// True when the next logged set ends the whole workout.
    public var isOnFinalSet: Bool {
        guard let entry = currentEntry else { return false }
        let wouldFinishLine = completedSets(for: entry.id) + 1 >= entry.plan.targetSets
        return wouldFinishLine && nextOpenIndex(after: exerciseIndex) == nil
    }

    public var hasLoggedAnything: Bool { !logs.isEmpty }

    /// What the one big button does next: start the set, then log it.
    public enum PrimaryAction: Equatable, Sendable {
        case start(set: Int)
        case logSet
        case logAndNextExercise
        case logAndFinish
    }

    public var primaryAction: PrimaryAction {
        guard let entry = currentEntry else { return .logAndFinish }
        guard isSetRunning else { return .start(set: currentSetNumber) }
        if isOnFinalSet { return .logAndFinish }
        return completedSets(for: entry.id) + 1 >= entry.plan.targetSets ? .logAndNextExercise : .logSet
    }

    // MARK: - Nudging the set about to be logged

    public mutating func adjustReps(by delta: Int) {
        workingReps = max(0, workingReps + delta)
    }

    public mutating func adjustWeight(by steps: Int, in unit: WeightUnit) {
        guard let equipment = currentEntry?.exercise.equipment else { return }
        workingWeight = equipment.stepped(workingWeight, by: steps, in: unit)
    }

    public mutating func adjustIncline(by steps: Int) {
        guard let equipment = currentEntry?.exercise.equipment, equipment.inclineStep != nil else { return }
        workingIncline = equipment.stepped(incline: workingIncline ?? 0, by: steps)
    }

    public mutating func setWorkingValues(reps: Int? = nil, weight: Weight? = nil, incline: Double? = nil) {
        if let reps { workingReps = max(0, reps) }
        if let weight { workingWeight = weight }
        if let incline, let equipment = currentEntry?.exercise.equipment, equipment.inclineStep != nil {
            workingIncline = equipment.stepped(incline: incline, by: 0)
        }
    }

    /// The "CHANGE" under the set counter. Dropping below what's already logged
    /// would strand completed sets, so it can't go lower than that.
    /// Dropping to exactly what's logged finishes the exercise and moves on.
    @discardableResult
    public mutating func changeTargetSets(to count: Int) -> SetOutcome? {
        guard exerciseIndex < entries.count else { return nil }
        let alreadyDone = completedSets(for: entries[exerciseIndex].id)
        entries[exerciseIndex].plan.targetSets = max(max(1, alreadyDone), count)
        guard isComplete(entries[exerciseIndex]) else { return nil }
        return advance(rest: 0)
    }

    /// The smallest set count the change-sets row may offer.
    public var minimumTargetSets: Int {
        guard let entry = currentEntry else { return 1 }
        return max(1, completedSets(for: entry.id))
    }

    public mutating func markProgressionOffered(for planID: String) {
        progressionOffered.insert(planID)
    }

    // MARK: - Timing the set

    public var isSetRunning: Bool { setStartedAt != nil }

    public mutating func startSet(at now: Date) {
        guard currentEntry != nil else { return }
        setStartedAt = now
    }

    public mutating func cancelSet() {
        setStartedAt = nil
    }

    public func setElapsed(at now: Date) -> TimeInterval {
        setStartedAt.map { max(0, now.timeIntervalSince($0)) } ?? 0
    }

    /// The working count as a duration: a treadmill's minutes, a plank's
    /// seconds. Nil for reps, which count up instead.
    public var setDuration: TimeInterval? {
        currentEntry?.measure.duration(workingReps)
    }

    /// Countdown for a timed set; nil for reps or before Start.
    public func setRemaining(at now: Date) -> TimeInterval? {
        guard isSetRunning, let setDuration else { return nil }
        return max(0, setDuration - setElapsed(at: now))
    }

    /// Past the countdown; how far past is `setElapsed - setDuration`.
    public func isSetTimeUp(at now: Date) -> Bool {
        setRemaining(at: now) == 0
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
                weight: entry.exercise.equipment.isLoadable ? workingWeight : .zero,
                completedAt: now,
                planLineID: entry.id,
                targetReps: entry.plan.targetReps,
                incline: entry.exercise.equipment.inclineStep == nil ? nil : (workingIncline ?? 0),
                startedAt: setStartedAt,
                measure: entry.measure
            )
        )
        setStartedAt = nil

        completedByPlan[entry.id, default: 0] += 1

        if completedSets(for: entry.id) < entry.plan.targetSets {
            return .restThenNextSet(seconds: restSecondsForCurrentExercise)
        }
        return advance(rest: entry.plan.restSeconds ?? restBetweenExercisesSeconds)
    }

    /// The long-press: several identical sets at once, for warm-ups. Stops at
    /// the end of the current exercise rather than spilling into the next.
    @discardableResult
    public mutating func completeSets(_ count: Int, at now: Date) -> SetOutcome {
        guard let entry = currentEntry else { return .workoutComplete }
        let room = entry.plan.targetSets - completedSets(for: entry.id)
        var outcome = SetOutcome.workoutComplete
        for _ in 0..<max(1, min(count, room)) {
            outcome = completeSet(at: now)
        }
        return outcome
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
        if index != exerciseIndex { leave() }
        entries[index].isSkipped = false
        exerciseIndex = index
        loadWorkingValues()
    }

    /// Where Back goes: the latest exercise left behind that still has
    /// sets to do. A finished one is history, not somewhere to return to.
    public var backEntry: Entry? {
        backIndex.map { entries[$0] }
    }

    private var backIndex: Int? {
        (cameFrom ?? []).last { entries.indices.contains($0) && $0 != exerciseIndex && !isComplete(entries[$0]) }
    }

    /// Undo a skip, or return to where the list jump came from.
    public mutating func goBack() {
        guard let target = backIndex else { return }
        let position = cameFrom?.lastIndex(of: target) ?? 0
        cameFrom = Array((cameFrom ?? []).prefix(position))
        entries[target].isSkipped = false
        exerciseIndex = target
        loadWorkingValues()
    }

    private mutating func leave() {
        guard entries.indices.contains(exerciseIndex) else { return }
        cameFrom = (cameFrom ?? []) + [exerciseIndex]
    }

    /// Next line with sets still to do, looking forward first and then
    /// wrapping back to anything jumped over. Skipped lines are left alone.
    private func nextOpenIndex(after index: Int) -> Int? {
        let order = Array(entries.indices.dropFirst(index + 1)) + Array(entries.indices.prefix(index))
        return order.first { !entries[$0].isSkipped && !isComplete(entries[$0]) }
    }

    private mutating func advance(rest: Int) -> SetOutcome {
        leave()
        exerciseIndex = nextOpenIndex(after: exerciseIndex) ?? entries.count
        loadWorkingValues()
        guard let next = currentEntry else { return .workoutComplete }
        return .restThenNextExercise(name: next.exercise.name, seconds: rest)
    }

    private mutating func loadWorkingValues() {
        setStartedAt = nil
        guard let entry = currentEntry else { return }
        workingReps = entry.plan.targetReps
        workingWeight = entry.plan.targetWeight
        workingIncline = Self.startingIncline(entry)
    }

    private static func startingIncline(_ entry: Entry) -> Double? {
        entry.exercise.equipment.inclineStep == nil ? nil : (entry.plan.targetIncline ?? 0)
    }

    // MARK: - Finishing

    public func finish(at now: Date, logID: String = UUID().uuidString) -> WorkoutLog {
        WorkoutLog(
            id: logID,
            workoutID: workoutID,
            workoutName: workoutName,
            startedAt: startedAt,
            finishedAt: now,
            sets: logs,
            skippedExerciseIDs: entries
                .filter { completedSets(for: $0.id) == 0 }
                .map(\.exercise.id),
            notes: notes
        )
    }

    /// Plan lines where the last weight lifted isn't the planned one. Only
    /// weight: a short set is a bad day, a different load is a new plan.
    public var weightDrift: [String: Weight] {
        var drift: [String: Weight] = [:]
        for entry in entries where entry.exercise.equipment.isLoadable {
            guard let last = logs.last(where: { $0.planLineID == entry.id }) else { continue }
            if last.weight != entry.plan.targetWeight { drift[entry.id] = last.weight }
        }
        return drift
    }

    /// Same idea for a treadmill's incline: the last one used, where it
    /// isn't the plan's.
    public var inclineDrift: [String: Double] {
        var drift: [String: Double] = [:]
        for entry in entries where entry.exercise.equipment.inclineStep != nil {
            guard let last = logs.last(where: { $0.planLineID == entry.id }), let incline = last.incline else { continue }
            if abs(incline - (entry.plan.targetIncline ?? 0)) > 0.001 { drift[entry.id] = incline }
        }
        return drift
    }

    /// Plan lines where anything would change if the plan were updated.
    public var driftedLineIDs: Set<String> {
        Set(weightDrift.keys).union(inclineDrift.keys)
    }

    /// The separate, explicit act of pushing today's loads into the plan.
    public static func applying(
        _ drift: [String: Weight],
        incline: [String: Double] = [:],
        to workout: Workout
    ) -> Workout {
        var updated = workout
        for index in updated.exercises.indices {
            let id = updated.exercises[index].id
            if let weight = drift[id] { updated.exercises[index].targetWeight = weight }
            if let value = incline[id] { updated.exercises[index].targetIncline = value }
        }
        return updated
    }

    public static func formatElapsed(_ interval: TimeInterval) -> String {
        RestTimer.format(interval)
    }
}
