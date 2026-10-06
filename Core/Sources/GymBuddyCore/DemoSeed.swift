import Foundation

/// Demo mode's content, read from `demo/seed.json`. History is generated
/// relative to `now`, so the demo always looks like last week.
public struct DemoSeed: Decodable, Sendable {
    public struct GymSeed: Decodable, Sendable {
        public var id: String
        public var name: String
        /// `"all"` or a list of `Kit` IDs.
        public var kit: KitChoice
        public var price: Price?
        public var open: Int?
        public var close: Int?
        public var travelMinutes: Int?
        public var notes: String?
    }

    public enum KitChoice: Decodable, Sendable {
        case all
        case some([String])

        public init(from decoder: Decoder) throws {
            let c = try decoder.singleValueContainer()
            if let list = try? c.decode([String].self) { self = .some(list); return }
            guard try c.decode(String.self) == "all" else {
                throw DecodingError.dataCorruptedError(in: c, debugDescription: "kit is \"all\" or a list")
            }
            self = .all
        }
    }

    public struct Line: Decodable, Sendable {
        public var exercise: String
        public var sets: Int
        public var reps: Int
        public var lb: Double
        public var rest: Int?
        public var incline: Double?
    }

    public struct WorkoutSeed: Decodable, Sendable {
        public var id: String
        public var name: String
        public var gyms: [String]
        public var lines: [Line]
    }

    public struct History: Decodable, Sendable {
        public struct Day: Decodable, Sendable {
            /// `Calendar` numbering: 1 is Sunday.
            public var weekday: Int
            public var workout: String
            public var everyOtherWeek: Bool?
        }
        public var weeks: Int
        public var days: [Day]
        public var lastNote: String?
    }

    public struct InProgress: Decodable, Sendable {
        public var workout: String
        public var minutesAgo: Int
        public var skip: Int
        public var sets: Int
    }

    public var unit: WeightUnit
    public var favourites: [String]
    public var gyms: [GymSeed]
    public var workouts: [WorkoutSeed]
    public var history: History
    public var inProgress: InProgress?

    public static func load(_ url: URL) throws -> DemoSeed {
        try JSONDecoder().decode(DemoSeed.self, from: Data(contentsOf: url))
    }

    // MARK: - Building

    public func plans() -> [Workout] {
        workouts.map { w in
            Workout(id: w.id, name: w.name, exercises: w.lines.enumerated().map { i, line in
                WorkoutExercise(id: "\(w.id)-\(i)", exerciseID: line.exercise, targetSets: line.sets,
                                targetReps: line.reps, targetWeight: Weight(pounds: line.lb),
                                restSeconds: line.rest, targetIncline: line.incline)
            }, gymIDs: w.gyms)
        }
    }

    public func places(catalogue: [Exercise]) -> [Gym] {
        let allKit = Set(Kit.catalogue(for: catalogue).map(\.id))
        return gyms.map { g in
            let kit: Set<String> = switch g.kit {
            case .all: allKit
            case .some(let ids): Set(ids)
            }
            let hours: OpeningHours = if let open = g.open, let close = g.close { .daily(open: open, close: close) } else { .always }
            return Gym(id: g.id, name: g.name, kitIDs: kit, price: g.price, hours: hours,
                       travelMinutes: g.travelMinutes ?? 0, notes: g.notes ?? "")
        }
    }

    /// Weeks of sessions on the seed's weekdays up to yesterday, a step
    /// lighter the further back, with the odd short set and skipped line.
    public func logs(plans: [Workout], catalogue: [String: Exercise], now: Date, calendar: Calendar = .current) -> [WorkoutLog] {
        let today = calendar.startOfDay(for: now)
        let byID = Dictionary(uniqueKeysWithValues: plans.map { ($0.id, $0) })
        let schedule: [(daysAgo: Int, workout: Workout)] = stride(from: history.weeks * 7, through: 1, by: -1).compactMap { day in
            let date = calendar.date(byAdding: .day, value: -day, to: today)!
            let weekday = calendar.component(.weekday, from: date)
            guard let slot = history.days.first(where: { $0.weekday == weekday }),
                  let workout = byID[slot.workout] else { return nil }
            if slot.everyOtherWeek == true && (day / 7) % 2 == 1 { return nil }
            return (day, workout)
        }
        return schedule.enumerated().map { index, entry in
            let progress = Double(index) / Double(schedule.count)
            let steps = Int((progress * 4).rounded(.down)) - 3
            let logID = "demo-log-\(schedule.count - index)"
            let start = calendar.date(byAdding: .day, value: -entry.daysAgo, to: today)!
                .addingTimeInterval(TimeInterval(17 * 3600 + (index % 4) * 900))
            var clock = start.addingTimeInterval(120)
            var sets: [SetLog] = []
            var skipped: [String] = []
            for (lineIndex, plan) in entry.workout.exercises.enumerated() {
                if lineIndex == 3 && index % 6 == 2 {
                    skipped.append(plan.exerciseID)
                    continue
                }
                let exercise = catalogue[plan.exerciseID]
                let equipment = exercise?.equipment ?? .none
                let weight = equipment.isLoadable ? equipment.stepped(plan.targetWeight, by: steps, in: unit) : .zero
                for n in 1...plan.targetSets {
                    let short = (index % 7 == 3 && n == plan.targetSets) ? 2 : 0
                    let began = clock
                    clock.addTimeInterval(exercise?.measure == .minutes ? TimeInterval(plan.targetReps * 60) : 40)
                    sets.append(SetLog(
                        id: "\(logID)-\(lineIndex)-\(n)", sessionID: logID, exerciseID: plan.exerciseID,
                        setNumber: n, reps: plan.targetReps - short, weight: weight, completedAt: clock,
                        planLineID: plan.id, targetReps: plan.targetReps,
                        incline: plan.targetIncline.map { max(0, $0 + Double(steps) * 0.5) },
                        startedAt: began
                    ))
                    clock.addTimeInterval(TimeInterval(plan.restSeconds ?? 60))
                }
                clock.addTimeInterval(60)
            }
            return WorkoutLog(
                id: logID, workoutID: entry.workout.id, workoutName: entry.workout.name,
                startedAt: start, finishedAt: clock, sets: sets, skippedExerciseIDs: skipped,
                notes: index == schedule.count - 1 ? history.lastNote ?? "" : ""
            )
        }
    }

    /// Writes everything into an empty store.
    public func populate(_ store: Store, now: Date = .now, calendar: Calendar = .current) throws {
        let favourites = Set(self.favourites)
        var exercises = try store.exercises()
        for i in exercises.indices where favourites.contains(exercises[i].id) {
            exercises[i].isFavourite = true
            try store.saveExercise(exercises[i])
        }
        let catalogue = Dictionary(uniqueKeysWithValues: exercises.map { ($0.id, $0) })
        for gym in places(catalogue: exercises) { try store.saveGym(gym) }

        var plans = plans()
        let logs = logs(plans: plans, catalogue: catalogue, now: now, calendar: calendar)
        for log in logs { try store.saveLog(log) }
        for i in plans.indices {
            plans[i].lastPerformed = logs.filter { $0.workoutID == plans[i].id }.map(\.startedAt).max()
            try store.saveWorkout(plans[i])
        }

        var settings = Settings()
        settings.unit = unit
        try store.saveSettings(settings)

        if let inProgress, let plan = plans.first(where: { $0.id == inProgress.workout }) {
            var session = WorkoutSession(
                workout: plan, exercises: catalogue,
                startedAt: now.addingTimeInterval(TimeInterval(-inProgress.minutesAgo * 60)),
                defaultRestSeconds: settings.restBetweenSets,
                restBetweenExercisesSeconds: settings.restBetweenExercises
            )
            for _ in 0..<inProgress.skip { _ = session.skipExercise() }
            if inProgress.sets > 0 {
                _ = session.completeSets(inProgress.sets, at: now.addingTimeInterval(-90))
            }
            try store.saveActiveSession(session)
        }
    }
}

/// Demo mode's own database, beside the real one and never the same file.
public enum DemoStore {
    public static let fileName = "GymBuddy-demo.sqlite"

    public static func url(in directory: URL) -> URL {
        directory.appending(path: fileName)
    }

    /// Opens the demo database, seeding it when it's new or `reset` is set.
    public static func open(in directory: URL, seed: DemoSeed, reset: Bool = false,
                            now: Date = .now, catalogue: [Exercise] = SeedLibrary.exercises) throws -> SQLiteStore {
        let url = url(in: directory)
        if reset { remove(url) }
        let fresh = !FileManager.default.fileExists(atPath: url.path)
        let store = try SQLiteStore(url: url, catalogue: catalogue)
        guard fresh else { return store }
        do {
            try seed.populate(store, now: now)
        } catch {
            remove(url)
            throw error
        }
        return store
    }

    private static func remove(_ url: URL) {
        for suffix in ["", "-wal", "-shm", "-journal"] {
            try? FileManager.default.removeItem(atPath: url.path + suffix)
        }
    }
}
