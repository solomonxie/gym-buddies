import Foundation

/// Everything the app persists. `SQLiteStore` on device; `MemoryStore` for
/// tests and demo data.
public protocol Store: AnyObject, Sendable {
    func exercises() throws -> [Exercise]
    func saveExercise(_ exercise: Exercise) throws
    func deleteExercise(id: String) throws
    func workouts() throws -> [Workout]
    func saveWorkout(_ workout: Workout) throws
    func deleteWorkout(id: String) throws
    func logs() throws -> [WorkoutLog]
    func saveLog(_ log: WorkoutLog) throws
    func deleteLog(id: String) throws
    /// "Reset history" on one exercise: its sets go, the sessions stay.
    func deleteSets(exerciseID: String) throws
    /// Written on every logged set, so a killed app resumes where it was.
    func activeSession() throws -> WorkoutSession?
    func saveActiveSession(_ session: WorkoutSession?) throws
    /// Nil until first saved, so first launch can pick units from the locale.
    func settings() throws -> Settings?
    func saveSettings(_ settings: Settings) throws
}

public final class MemoryStore: Store, @unchecked Sendable {
    private var exercisesByID: [String: Exercise]
    private var workoutsByID: [String: Workout]
    private var logsByID: [String: WorkoutLog]
    private var session: WorkoutSession?
    private var storedSettings: Settings?
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

    public func deleteExercise(id: String) throws {
        sync { exercisesByID[id] = nil }
    }

    public func deleteLog(id: String) throws {
        sync { logsByID[id] = nil }
    }

    public func deleteSets(exerciseID: String) throws {
        sync {
            for id in logsByID.keys {
                logsByID[id]?.sets.removeAll { $0.exerciseID == exerciseID }
            }
        }
    }

    public func activeSession() throws -> WorkoutSession? { sync { session } }

    public func saveActiveSession(_ session: WorkoutSession?) throws {
        sync { self.session = session }
    }

    public func settings() throws -> Settings? { sync { storedSettings } }

    public func saveSettings(_ settings: Settings) throws {
        sync { storedSettings = settings }
    }
}
