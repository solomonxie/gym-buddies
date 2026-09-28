#if DEBUG
import Foundation
import GymBuddyCore

/// Launch with `-demo` for a phone full of plausible history in memory — the
/// real database is never opened, so QA and store screenshots can't touch it.
/// `-screen <name>` opens straight onto one screen; see `initialPath`.
enum DemoData {
    static var arguments: [String] { ProcessInfo.processInfo.arguments }

    static var screen: String? {
        guard let i = arguments.firstIndex(of: "-screen"), i + 1 < arguments.count else { return nil }
        return arguments[i + 1]
    }

    @MainActor
    static func modelIfRequested() -> AppModel? {
        guard arguments.contains("-demo") else { return nil }
        let store = makeStore(empty: arguments.contains("-empty"))
        var settings = Settings()
        settings.unit = arguments.contains("-kg") ? .kilograms : .pounds
        settings.lastBackup = Date.now.addingTimeInterval(-5 * 86_400)
        settings.lastBackupBytes = 86_016
        try? store.saveSettings(settings)
        let model = AppModel(store: store)
        route(model)
        return model
    }

    @MainActor
    private static func route(_ model: AppModel) {
        switch screen {
        case "treadmill":
            guard let workout = model.workouts.first(where: { $0.name == "Fraiser Heights" }) else { return }
            model.start(workout, at: .now.addingTimeInterval(-7 * 60))
            model.startSet(at: .now.addingTimeInterval(-6 * 60 - 38))
        case "session", "resting", "summary", "jump", "progression", "set", "background":
            guard let workout = model.workouts.first(where: { $0.name == "Fraiser Heights" }) else { return }
            model.start(workout, at: .now.addingTimeInterval(-14 * 60 - 22))
            model.updateSession { $0.skipExercise() }
            if screen == "progression" { return }
            model.updateSession { $0.markProgressionOffered(for: $0.currentEntry?.id ?? "") }
            if screen == "resting" || screen == "jump" {
                model.completeSets(1, at: .now.addingTimeInterval(-32))
            }
            if screen == "set" { model.startSet(at: .now.addingTimeInterval(-41)) }
            if screen == "background" {
                model.completeSets(1, at: .now.addingTimeInterval(-32))
                model.isSessionPresented = false
            }
            if screen == "summary" {
                model.updateSession { s in
                    while !s.isFinished {
                        if s.currentEntry?.exercise.id == "lat-pull-downs" { s.adjustWeight(by: 1, in: .pounds) }
                        s.completeSet(at: .now)
                    }
                }
                model.pendingSummary = model.session
            }
        default: model.path = path
        }
    }

    private static var path: [Route] {
        switch screen {
        case "exercises", "favourites": [.exercises]
        case "exercise": [.exercises, .exercise("lat-pull-downs")]
        case "gyms": [.gyms]
        case "settings": [.settings]
        case "workout": [.workout("demo-fraiser")]
        case "add": [.workout("demo-fraiser"), .addExercises("demo-fraiser")]
        case "logs": [.progress]
        case "log": [.progress, .log("demo-log-1")]
        case "trend": [.progress, .trend("lat-pull-downs")]
        default: []
        }
    }

    // MARK: - Content

    static func line(_ id: String, _ exercise: String, _ sets: Int, _ reps: Int, _ lb: Double,
                     rest: Int? = nil, incline: Double? = nil) -> WorkoutExercise {
        WorkoutExercise(id: id, exerciseID: exercise, targetSets: sets, targetReps: reps,
                        targetWeight: Weight(pounds: lb), restSeconds: rest, targetIncline: incline)
    }

    static let workouts: [Workout] = [
        Workout(id: "demo-fraiser", name: "Fraiser Heights", exercises: [
            line("f1", "incline-treadmill-walking", 1, 10, 0, incline: 8),
            line("f2", "seated-machine-rows", 3, 10, 50),
            line("f3", "lat-pull-downs", 3, 10, 60, rest: 90),
            line("f4", "seated-leg-curls", 3, 10, 50),
            line("f5", "seated-machine-presses", 3, 10, 40),
            line("f6", "planking", 3, 60, 0),
        ]),
        Workout(id: "demo-push", name: "Push Day", exercises: [
            line("p1", "barbell-bench-press", 5, 5, 155, rest: 150),
            line("p2", "barbell-overhead-press", 3, 8, 85),
            line("p3", "dumbbell-flyes", 3, 12, 25),
            line("p4", "dumbbell-lateral-raises", 3, 15, 15),
            line("p5", "cable-tricep-extensions", 3, 12, 40),
        ]),
        Workout(id: "demo-legs", name: "Legs", exercises: [
            line("l1", "barbell-squats", 5, 5, 185, rest: 180),
            line("l2", "leg-press", 3, 10, 270),
            line("l3", "seated-leg-curls", 3, 12, 60),
            line("l4", "walking-lunges", 3, 10, 30),
        ]),
    ]

    static func makeStore(empty: Bool) -> MemoryStore {
        let favourites: Set = ["barbell-deadlifts", "pull-ups", "barbell-bench-press", "lat-pull-downs", "barbell-squats"]
        let exercises = SeedLibrary.exercises.map { e -> Exercise in
            var e = e
            e.isFavourite = !empty && favourites.contains(e.id)
            return e
        }
        guard !empty else { return MemoryStore(exercises: exercises) }
        let catalogue = Dictionary(uniqueKeysWithValues: exercises.map { ($0.id, $0) })

        var logs: [WorkoutLog] = []
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: .now)
        // Rotation over ten weeks, heavier as it goes, with a bad day or two.
        let schedule: [(daysAgo: Int, workout: Int)] = stride(from: 70, through: 1, by: -1).compactMap { day in
            let weekday = calendar.component(.weekday, from: calendar.date(byAdding: .day, value: -day, to: today)!)
            switch weekday {
            case 2: return (day, 0)
            case 4: return (day, 1)
            case 6: return (day, 2)
            case 7 where day % 3 == 0: return (day, 0)
            default: return nil
            }
        }
        var lastPerformed: [String: Date] = [:]
        for (index, entry) in schedule.enumerated() {
            let workout = workouts[entry.workout]
            let progress = Double(index) / Double(schedule.count)
            let start = calendar.date(byAdding: .day, value: -entry.daysAgo, to: today)!
                .addingTimeInterval(TimeInterval(17 * 3600 + (index % 4) * 900))
            var clock = start.addingTimeInterval(120)
            var sets: [SetLog] = []
            var skipped: [String] = []
            for (lineIndex, plan) in workout.exercises.enumerated() {
                if entry.workout == 0 && lineIndex == 3 && index % 5 == 2 {
                    skipped.append(plan.exerciseID)
                    continue
                }
                let equipment = catalogue[plan.exerciseID]?.equipment ?? .none
                let steps = Int((progress * 4).rounded(.down)) - 3
                let weight = equipment.isLoadable
                    ? equipment.stepped(plan.targetWeight, by: steps, in: .pounds) : .zero
                for n in 1...plan.targetSets {
                    let short = (index % 7 == 3 && n == plan.targetSets) ? 2 : 0
                    sets.append(SetLog(
                        id: "demo-\(index)-\(lineIndex)-\(n)", sessionID: "demo-log-\(index)",
                        exerciseID: plan.exerciseID, setNumber: n, reps: plan.targetReps - short,
                        weight: weight, completedAt: clock, planLineID: plan.id, targetReps: plan.targetReps,
                        incline: plan.targetIncline.map { max(0, $0 - Double(3 - steps.clamped) * 0.5) }
                    ))
                    clock.addTimeInterval(TimeInterval(40 + (plan.restSeconds ?? 60)))
                }
                clock.addTimeInterval(60)
            }
            let notes = index == schedule.count - 1 ? "Left shoulder tight on the rows, went light on the third set." : ""
            logs.append(WorkoutLog(
                id: "demo-log-\(schedule.count - index)", workoutID: workout.id, workoutName: workout.name,
                startedAt: start, finishedAt: clock, sets: sets, skippedExerciseIDs: skipped, notes: notes
            ))
            lastPerformed[workout.id] = start
        }
        let dated = workouts.map { w -> Workout in
            var w = w
            w.lastPerformed = lastPerformed[w.id]
            return w
        }
        return MemoryStore(exercises: exercises, workouts: dated, logs: logs)
    }
}
private extension Int {
    var clamped: Int { Swift.max(0, Swift.min(3, self + 3)) }
}
#endif
