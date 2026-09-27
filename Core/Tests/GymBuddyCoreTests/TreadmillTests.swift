import SQLite3
import XCTest
@testable import GymBuddyCore

final class TreadmillTests: XCTestCase {
    static let treadmill = Exercise(
        id: "incline-treadmill-walking", name: "Incline Treadmill Walking",
        muscleGroup: .cardio, equipment: .treadmill, measure: .minutes
    )

    static let workout = Workout(id: "w", name: "Cardio", exercises: [
        WorkoutExercise(id: "t", exerciseID: treadmill.id, targetSets: 1, targetReps: 20,
                        targetWeight: .zero, targetIncline: 8),
    ])

    func session() -> WorkoutSession {
        WorkoutSession(id: "s", workout: Self.workout, exercises: [Self.treadmill.id: Self.treadmill], startedAt: Fixtures.t0)
    }

    func testATreadmillHasInclineNotWeight() {
        XCTAssertFalse(Equipment.treadmill.isLoadable)
        XCTAssertEqual(Equipment.treadmill.increment(in: .pounds), .zero)
        XCTAssertEqual(Equipment.treadmill.inclineStep, 0.5)
        XCTAssertNil(Equipment.barbell.inclineStep)
    }

    func testInclineStepsByHalfAPercentAndStaysOnTheMachine() {
        XCTAssertEqual(Equipment.treadmill.stepped(incline: 8, by: 1), 8.5)
        XCTAssertEqual(Equipment.treadmill.stepped(incline: 0, by: -1), 0)
        XCTAssertEqual(Equipment.treadmill.stepped(incline: 29.5, by: 4), Equipment.maxIncline)
        // Typed-in values snap to the grid rather than drifting off it.
        XCTAssertEqual(Equipment.treadmill.stepped(incline: 7.3, by: 0), 7.5)
    }

    func testTheSetLogsMinutesAndIncline() {
        var s = session()
        XCTAssertEqual(s.workingReps, 20)
        XCTAssertEqual(s.workingIncline, 8)
        s.adjustIncline(by: 2)
        s.adjustReps(by: Self.treadmill.repStep * 5)
        s.adjustWeight(by: 3, in: .pounds)
        s.completeSet(at: Fixtures.t0)

        let set = s.logs[0]
        XCTAssertEqual(set.reps, 25)
        XCTAssertEqual(set.incline, 9)
        XCTAssertEqual(set.weight, .zero)
        XCTAssertEqual(s.inclineDrift, ["t": 9])
        XCTAssertTrue(s.weightDrift.isEmpty)

        let updated = WorkoutSession.applying(s.weightDrift, incline: s.inclineDrift, to: Self.workout)
        XCTAssertEqual(updated.exercises[0].targetIncline, 9)
    }

    func testAWeightedLiftLogsNoIncline() {
        var s = Fixtures.session()
        XCTAssertNil(s.workingIncline)
        s.adjustIncline(by: 3)
        s.completeSet(at: Fixtures.t0)
        XCTAssertNil(s.logs[0].incline)
    }

    func testFormat() {
        XCTAssertEqual(Measure.minutes.format(20), "20 min")
        XCTAssertEqual(Measure.seconds.format(60), "60s")
        XCTAssertEqual(Measure.minutes.step, 1)
        XCTAssertEqual(LoadFormat.line(Self.workout.exercises[0], exercise: Self.treadmill, unit: .pounds), "1 × 20 min · 8% incline")
        let flat = WorkoutExercise(id: "f", exerciseID: Self.treadmill.id, targetSets: 1, targetReps: 30, targetWeight: .zero)
        XCTAssertEqual(LoadFormat.line(flat, exercise: Self.treadmill, unit: .kilograms), "1 × 30 min")
    }

    func testCatalogueTreadmillsAreMinutesWithIncline() {
        let treadmills = SeedLibrary.exercises.filter { $0.name.localizedCaseInsensitiveContains("treadmill") }
        XCTAssertGreaterThanOrEqual(treadmills.count, 2)
        for e in treadmills {
            XCTAssertEqual(e.equipment, .treadmill, e.name)
            XCTAssertEqual(e.measure, .minutes, e.name)
        }
        XCTAssertEqual(SeedLibrary.byID["planking"]?.measure, .seconds)
    }

    func testOldSessionsWithIsTimedStillDecode() throws {
        let json = #"{"id":"p","name":"Plank","muscleGroup":"core","equipment":"bodyweight","isFavourite":false,"isTimed":true}"#
        let e = try JSONDecoder().decode(Exercise.self, from: Data(json.utf8))
        XCTAssertEqual(e.measure, .seconds)
    }

    func testStoreRoundTripsMeasureAndIncline() throws {
        let url = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString + ".sqlite")
        defer { try? FileManager.default.removeItem(at: url) }
        let store = try SQLiteStore(url: url, catalogue: [Self.treadmill])
        try store.saveWorkout(Self.workout)
        var s = session()
        s.completeSet(at: Fixtures.t0)
        try store.saveLog(s.finish(at: Fixtures.t0 + 1200, logID: "log"))

        XCTAssertEqual(try store.exercises().first?.measure, .minutes)
        XCTAssertEqual(try store.workouts().first?.exercises.first?.targetIncline, 8)
        XCTAssertEqual(try store.logs().first?.sets.first?.incline, 8)
    }

    /// A database written before migration 2 opens, keeps its data, and
    /// its timed exercises come back measured in seconds.
    func testVersionOneDatabaseMigrates() throws {
        let url = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString + ".sqlite")
        defer { try? FileManager.default.removeItem(at: url) }
        var db: OpaquePointer?
        XCTAssertEqual(sqlite3_open(url.path, &db), SQLITE_OK)
        let v1 = """
            CREATE TABLE migrations (version INTEGER PRIMARY KEY, applied_at REAL NOT NULL);
            \(SQLiteStore.migrations[0])
            INSERT INTO migrations VALUES (1, 0);
            INSERT INTO exercises (id, name, muscle_group, equipment, is_custom, is_timed)
                VALUES ('my-hold', 'My Hold', 'core', 'bodyweight', 1, 1);
            INSERT INTO workouts VALUES ('w', 'Old', NULL);
            INSERT INTO workout_lines VALUES ('l', 'w', 0, 'my-hold', 3, 45, 0, NULL);
            """
        XCTAssertEqual(sqlite3_exec(db, v1, nil, nil, nil), SQLITE_OK)
        sqlite3_close(db)

        let store = try SQLiteStore(url: url, catalogue: [])
        XCTAssertEqual(try store.exercises().first?.measure, .seconds)
        XCTAssertEqual(try store.workouts().first?.exercises.first?.targetReps, 45)
        XCTAssertNil(try store.workouts().first?.exercises.first?.targetIncline)
    }
}
