import Foundation

/// Everything the app persists. SQLite lands behind this later
/// (docs/IMPLEMENT_PLAN.md T2.3); the in-memory store is what screens and
/// tests run against until then.
public protocol Store: Sendable {
    func exercises() throws -> [Exercise]
    func saveExercise(_ exercise: Exercise) throws
    func workouts() throws -> [Workout]
    func saveWorkout(_ workout: Workout) throws
    func deleteWorkout(id: String) throws
    func logs() throws -> [WorkoutLog]
    func saveLog(_ log: WorkoutLog) throws
}

public final class MemoryStore: Store, @unchecked Sendable {
    private var exercisesByID: [String: Exercise]
    private var workoutsByID: [String: Workout]
    private var logsByID: [String: WorkoutLog]
    private let lock = NSLock()

    public init(
        exercises: [Exercise] = [],
        workouts: [Workout] = [],
        logs: [WorkoutLog] = []
    ) {
        self.exercisesByID = Dictionary(uniqueKeysWithValues: exercises.map { ($0.id, $0) })
        self.workoutsByID = Dictionary(uniqueKeysWithValues: workouts.map { ($0.id, $0) })
        self.logsByID = Dictionary(uniqueKeysWithValues: logs.map { ($0.id, $0) })
    }

    private func sync<T>(_ body: () -> T) -> T {
        lock.lock()
        defer { lock.unlock() }
        return body()
    }

    public func exercises() throws -> [Exercise] {
        sync { exercisesByID.values.sorted { $0.name < $1.name } }
    }

    public func saveExercise(_ exercise: Exercise) throws {
        sync { exercisesByID[exercise.id] = exercise }
    }

    public func workouts() throws -> [Workout] {
        sync { workoutsByID.values.sorted { $0.name < $1.name } }
    }

    public func saveWorkout(_ workout: Workout) throws {
        sync { workoutsByID[workout.id] = workout }
    }

    public func deleteWorkout(id: String) throws {
        sync { workoutsByID[id] = nil }
    }

    public func logs() throws -> [WorkoutLog] {
        sync { logsByID.values.sorted { $0.startedAt > $1.startedAt } }
    }

    public func saveLog(_ log: WorkoutLog) throws {
        sync { logsByID[log.id] = log }
    }
}
