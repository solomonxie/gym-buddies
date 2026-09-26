import Foundation
import GymBuddyCore
import Observation

/// One place the screens read from. Backed by `MemoryStore` until SQLite lands
/// (docs/IMPLEMENT_PLAN.md T2.3), so the shell runs today.
@Observable
final class AppModel {
    private(set) var store: Store
    private(set) var exercises: [Exercise] = []
    private(set) var workouts: [Workout] = []
    private(set) var logs: [WorkoutLog] = []

    var unit: WeightUnit = .pounds
    var defaultRestSeconds: Int = 60

    /// Non-nil exactly while a workout is being performed.
    var session: WorkoutSession?
    var restTimer = RestTimer()

    init(store: Store = MemoryStore(exercises: SeedLibrary.exercises)) {
        self.store = store
        reload()
    }

    func reload() {
        exercises = (try? store.exercises()) ?? []
        workouts = (try? store.workouts()) ?? []
        logs = (try? store.logs()) ?? []
    }

    var exercisesByID: [String: Exercise] {
        Dictionary(uniqueKeysWithValues: exercises.map { ($0.id, $0) })
    }

    func start(_ workout: Workout, at now: Date = .now) {
        session = WorkoutSession(
            workout: workout,
            exercises: exercisesByID,
            startedAt: now,
            defaultRestSeconds: defaultRestSeconds
        )
        restTimer.dismiss()
    }

    /// Logs the set, then starts the rest the outcome asked for — the timer is
    /// never started by a screen directly, so it can't drift from the session.
    func completeSet(at now: Date = .now) {
        guard var current = session else { return }
        let outcome = current.completeSet(at: now)
        session = current

        switch outcome {
        case .restThenNextSet(let seconds), .restThenNextExercise(_, let seconds):
            if seconds > 0 { restTimer.start(TimeInterval(seconds), at: now) }
        case .workoutComplete:
            restTimer.dismiss()
        }
    }

    func finishSession(at now: Date = .now) {
        guard let current = session else { return }
        try? store.saveLog(current.finish(at: now))
        session = nil
        restTimer.dismiss()
        reload()
    }
}
