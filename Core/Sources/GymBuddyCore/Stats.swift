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
