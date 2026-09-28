import Foundation

/// Everything the Logs & Graphs tab draws. Pure functions over logs, so a chart
/// and a test see exactly the same number.
public enum Stats {
    public static func volume(_ sets: [SetLog]) -> Weight {
        Weight(kilograms: sets.reduce(0) { $0 + $1.volume.kilograms })
    }

    public static func totalReps(_ sets: [SetLog]) -> Int {
        sets.reduce(0) { $0 + $1.reps }
    }

    /// Heaviest set, ties broken by reps — 100×5 beats 100×3, and both beat 95×8.
    public static func personalRecord(
        exerciseID: String,
        in sets: [SetLog]
    ) -> SetLog? {
        sets
            .filter { $0.exerciseID == exerciseID }
            .max { a, b in
                a.weight == b.weight ? a.reps < b.reps : a.weight < b.weight
            }
    }

    public enum Metric: String, CaseIterable, Sendable {
        case topWeight, volume, reps

        public var displayName: String {
            switch self {
            case .topWeight: "Top set"
            case .volume: "Volume"
            case .reps: "Reps"
            }
        }
    }

    public struct Point: Equatable, Sendable {
        public let date: Date
        public let value: Double

        public init(date: Date, value: Double) {
            self.date = date
            self.value = value
        }
    }

    /// One point per session, oldest first — a line chart of an exercise over time.
    public static func series(
        exerciseID: String,
        metric: Metric,
        from logs: [WorkoutLog],
        in unit: WeightUnit
    ) -> [Point] {
        logs
            .sorted { $0.startedAt < $1.startedAt }
            .compactMap { log in
                let sets = log.sets.filter { $0.exerciseID == exerciseID }
                guard !sets.isEmpty else { return nil }
                let value: Double = switch metric {
                case .topWeight: sets.map { $0.weight.value(in: unit) }.max() ?? 0
                case .volume: volume(sets).value(in: unit)
                case .reps: Double(totalReps(sets))
                }
                return Point(date: log.startedAt, value: value)
            }
    }

    public static func volumeByMuscleGroup(
        _ sets: [SetLog],
        exercises: [String: Exercise],
        in unit: WeightUnit
    ) -> [MuscleGroup: Double] {
        sets.reduce(into: [:]) { totals, set in
            guard let group = exercises[set.exerciseID]?.muscleGroup else { return }
            totals[group, default: 0] += set.volume.value(in: unit)
        }
    }

    /// Consecutive days, counting back from today, on which something was logged.
    public static func streak(
        _ logs: [WorkoutLog],
        asOf now: Date,
        calendar: Calendar = .current
    ) -> Int {
        let days = Set(logs.map { calendar.startOfDay(for: $0.startedAt) })
        var day = calendar.startOfDay(for: now)
        var count = 0
        while days.contains(day) {
            count += 1
            guard let previous = calendar.date(byAdding: .day, value: -1, to: day)
            else { break }
            day = previous
        }
        return count
    }
}

extension Stats {
    /// "last time:" — the same set number from the most recent session that
    /// did this exercise, else that session's last set.
    public static func lastTime(
        exerciseID: String,
        setNumber: Int,
        measure: Measure? = nil,
        in logs: [WorkoutLog]
    ) -> SetLog? {
        // 20 minutes last time says nothing about 50 reps today.
        let matches = { (set: SetLog) in
            set.exerciseID == exerciseID && (measure == nil || set.measure == nil || set.measure == measure)
        }
        guard let recent = logs
            .filter({ $0.sets.contains(where: matches) })
            .max(by: { $0.startedAt < $1.startedAt })
        else { return nil }
        let sets = recent.sets.filter(matches)
        return sets.first { $0.setNumber == setNumber } ?? sets.last
    }

    /// Most recent session containing the exercise.
    public static func lastSession(exerciseID: String, in logs: [WorkoutLog]) -> WorkoutLog? {
        logs
            .filter { $0.sets.contains { $0.exerciseID == exerciseID } }
            .max { $0.startedAt < $1.startedAt }
    }

    /// Records set in `log`: exercises whose best set beat everything before it.
    /// The first time you do something is not a record — there's nothing to beat.
    public static func records(in log: WorkoutLog, history: [WorkoutLog]) -> [SetLog] {
        let earlier = history.filter { $0.id != log.id && $0.startedAt < log.startedAt }.flatMap(\.sets)
        return log.exerciseOrder.compactMap { exerciseID in
            guard let best = personalRecord(exerciseID: exerciseID, in: log.sets),
                  let previous = personalRecord(exerciseID: exerciseID, in: earlier)
            else { return nil }
            return beats(best, previous) ? best : nil
        }
    }

    /// The set a record beat, for the ★ popover.
    public static func previousBest(before set: SetLog, in log: WorkoutLog, history: [WorkoutLog]) -> SetLog? {
        let earlier = history.filter { $0.id != log.id && $0.startedAt < log.startedAt }.flatMap(\.sets)
        return personalRecord(exerciseID: set.exerciseID, in: earlier)
    }

    static func beats(_ a: SetLog, _ b: SetLog) -> Bool {
        a.weight == b.weight ? a.reps > b.reps : a.weight > b.weight
    }

    public static func logs(_ logs: [WorkoutLog], since start: Date?) -> [WorkoutLog] {
        guard let start else { return logs }
        return logs.filter { $0.startedAt >= start }
    }

    /// Mon…Sun of the week containing `now`, true where something was logged.
    public static func weekDots(
        _ logs: [WorkoutLog],
        asOf now: Date,
        calendar: Calendar = .current
    ) -> [Bool] {
        var calendar = calendar
        calendar.firstWeekday = 2
        guard let week = calendar.dateInterval(of: .weekOfYear, for: now) else {
            return Array(repeating: false, count: 7)
        }
        let days = Set(logs.map { calendar.startOfDay(for: $0.startedAt) })
        return (0..<7).map { offset in
            let day = calendar.date(byAdding: .day, value: offset, to: week.start)!
            return days.contains(calendar.startOfDay(for: day))
        }
    }

    public static func thisWeek(
        _ logs: [WorkoutLog],
        asOf now: Date,
        calendar: Calendar = .current
    ) -> [WorkoutLog] {
        var calendar = calendar
        calendar.firstWeekday = 2
        guard let week = calendar.dateInterval(of: .weekOfYear, for: now) else { return [] }
        return logs.filter { week.contains($0.startedAt) }
    }

    /// Every group, zero rows kept and sorted last — the empty one is the
    /// useful one.
    public static func volumeRows(
        _ sets: [SetLog],
        exercises: [String: Exercise],
        in unit: WeightUnit
    ) -> [(group: MuscleGroup, volume: Double)] {
        let totals = volumeByMuscleGroup(sets, exercises: exercises, in: unit)
        return MuscleGroup.allCases
            .filter { $0 != .cardio }
            .map { ($0, totals[$0] ?? 0) }
            .sorted { $0.1 == $1.1 ? $0.0.displayName < $1.0.displayName : $0.1 > $1.1 }
    }

    /// Minutes, from this workout's real sessions; nil until there is one.
    public static func estimatedMinutes(workoutID: String, logs: [WorkoutLog]) -> Int? {
        let durations = logs.filter { $0.workoutID == workoutID }
            .sorted { $0.startedAt > $1.startedAt }
            .prefix(5)
            .map(\.duration)
        guard !durations.isEmpty else { return nil }
        let mean = durations.reduce(0, +) / Double(durations.count)
        return max(1, Int((mean / 60).rounded()))
    }

    /// Fallback before any real session: sets × (a set + its rest).
    public static func plannedMinutes(_ workout: Workout, defaultRest: Int) -> Int {
        let seconds = workout.exercises.reduce(0) {
            $0 + $1.targetSets * (40 + ($1.restSeconds ?? defaultRest))
        }
        return max(1, Int((Double(seconds) / 60).rounded()))
    }

    public static func workouts(using exerciseID: String, in workouts: [Workout]) -> [Workout] {
        workouts.filter { $0.exercises.contains { $0.exerciseID == exerciseID } }
    }

    /// Per session, sets that one exercise got — the trend's "every session" list.
    public static func sessions(
        exerciseID: String,
        in logs: [WorkoutLog]
    ) -> [(log: WorkoutLog, sets: [SetLog])] {
        logs.sorted { $0.startedAt > $1.startedAt }.compactMap { log in
            let sets = log.sets.filter { $0.exerciseID == exerciseID }
            return sets.isEmpty ? nil : (log, sets)
        }
    }
}

/// `3 × 10 · 50 lb` — the app's one number format.
public enum LoadFormat {
    public static func weight(_ weight: Weight, _ unit: WeightUnit) -> String {
        "\(number(weight.value(in: unit))) \(unit.abbreviation)"
    }

    /// Whole numbers bare, halves and quarters kept: 50, 52.5, 1.25.
    public static func number(_ value: Double) -> String {
        let rounded = (value * 100).rounded() / 100
        if rounded == rounded.rounded() { return String(Int(rounded)) }
        var text = String(format: "%.2f", rounded)
        while text.hasSuffix("0") { text.removeLast() }
        return text
    }

    /// Big readout on the stepper: always one decimal so it doesn't jump width.
    public static func readout(_ weight: Weight, _ unit: WeightUnit) -> String {
        let value = weight.value(in: unit)
        let rounded = (value * 100).rounded() / 100
        return rounded * 10 == (rounded * 10).rounded()
            ? String(format: "%.1f", rounded) : String(format: "%.2f", rounded)
    }

    public static func reps(_ reps: Int, measure: Measure) -> String {
        measure.format(reps)
    }

    /// `8%`, `8.5%`.
    public static func incline(_ percent: Double) -> String {
        "\(number(percent))%"
    }

    /// The set's load, whichever kind the equipment has; nil when it has none.
    public static func load(weight: Weight, incline: Double?, exercise: Exercise?, unit: WeightUnit) -> String? {
        if exercise?.equipment.inclineStep != nil {
            guard let incline, incline > 0 else { return nil }
            return "\(self.incline(incline)) incline"
        }
        guard exercise?.equipment.isLoadable ?? true, weight.kilograms > 0 else { return nil }
        return self.weight(weight, unit)
    }

    public static func line(
        sets: Int, reps: Int, weight: Weight, exercise: Exercise,
        unit: WeightUnit, restOverride: Int? = nil, incline: Double? = nil, measure: Measure? = nil
    ) -> String {
        var parts = ["\(sets) × \(self.reps(reps, measure: measure ?? exercise.measure))"]
        if let load = load(weight: weight, incline: incline, exercise: exercise, unit: unit) {
            parts.append(load)
        }
        if let restOverride { parts.append("rest \(restOverride)s") }
        return parts.joined(separator: " · ")
    }

    public static func line(_ plan: WorkoutExercise, exercise: Exercise, unit: WeightUnit) -> String {
        line(sets: plan.targetSets, reps: plan.targetReps, weight: plan.targetWeight,
             exercise: exercise, unit: unit, restOverride: plan.restSeconds, incline: plan.targetIncline,
             measure: plan.measure)
    }

    /// Summary of what a session did for one exercise: `3 × 10 · 60 lb`, or
    /// `3 × 9 · 55 lb` when reps varied (the lowest, honestly).
    public static func summary(_ sets: [SetLog], exercise: Exercise?, unit: WeightUnit) -> String {
        guard !sets.isEmpty else { return "" }
        let top = sets.map(\.weight).max() ?? .zero
        let reps = sets.map(\.reps).min() ?? 0
        var text = "\(sets.count) × \(self.reps(reps, measure: sets[0].measure(for: exercise)))"
        let incline = sets.compactMap(\.incline).max()
        if let load = load(weight: top, incline: incline, exercise: exercise, unit: unit) {
            text += " · " + load
        }
        return text
    }

    /// Big volumes with grouping: `12,400 lb`.
    public static func volume(_ value: Double, _ unit: WeightUnit) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.maximumFractionDigits = 0
        formatter.locale = Locale(identifier: "en_US")
        return "\(formatter.string(from: NSNumber(value: value.rounded())) ?? "0") \(unit.abbreviation)"
    }

    /// `42:18`, or `1:02:05` past the hour.
    public static func duration(_ interval: TimeInterval) -> String {
        let total = max(0, Int(interval))
        let h = total / 3600, m = (total % 3600) / 60, s = total % 60
        return h > 0 ? String(format: "%d:%02d:%02d", h, m, s) : String(format: "%d:%02d", m, s)
    }
}

/// Sessions as a spreadsheet: one row per set.
public enum CSVExport {
    public static func sessions(
        _ logs: [WorkoutLog],
        exercises: [String: Exercise],
        unit: WeightUnit
    ) -> String {
        let iso = ISO8601DateFormatter()
        var rows = ["date,workout,exercise,muscle_group,set,reps,weight_\(unit.abbreviation),volume_\(unit.abbreviation),completed_at,measure,incline_pct"]
        for log in logs.sorted(by: { $0.startedAt < $1.startedAt }) {
            for set in log.sets {
                let exercise = exercises[set.exerciseID]
                rows.append([
                    iso.string(from: log.startedAt),
                    escape(log.workoutName),
                    escape(exercise?.name ?? set.exerciseID),
                    exercise?.muscleGroup.displayName ?? "",
                    String(set.setNumber),
                    String(set.reps),
                    LoadFormat.number(set.weight.value(in: unit)),
                    LoadFormat.number(set.volume.value(in: unit)),
                    iso.string(from: set.completedAt),
                    set.measure(for: exercise).rawValue,
                    set.incline.map(LoadFormat.number) ?? "",
                ].joined(separator: ","))
            }
        }
        return rows.joined(separator: "\n") + "\n"
    }

    static func escape(_ field: String) -> String {
        guard field.contains(where: { ",\"\n".contains($0) }) else { return field }
        return "\"" + field.replacingOccurrences(of: "\"", with: "\"\"") + "\""
    }
}
