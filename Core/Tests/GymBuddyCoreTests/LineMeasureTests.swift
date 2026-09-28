import XCTest
@testable import GymBuddyCore

/// An air bike by the clock in one workout, by reps in another.
final class LineMeasureTests: XCTestCase {
    static let bike = Exercise(id: "air-bike", name: "Air Bike", muscleGroup: .cardio,
                               equipment: .machine, measure: .minutes)

    func line(_ measure: Measure? = nil, reps: Int = 20) -> WorkoutExercise {
        WorkoutExercise(id: "b", exerciseID: Self.bike.id, targetSets: 3, targetReps: reps,
                        targetWeight: .zero, measure: measure)
    }

    func session(_ line: WorkoutExercise) -> WorkoutSession {
        WorkoutSession(id: "s", workout: Workout(id: "w", name: "W", exercises: [line]),
                       exercises: [Self.bike.id: Self.bike], startedAt: Fixtures.t0)
    }

    func testALineFallsBackToItsExercise() {
        XCTAssertEqual(line().measure(for: Self.bike), .minutes)
        XCTAssertEqual(line(.reps).measure(for: Self.bike), .reps)
    }

    func testSwitchingRestartsTheTargetAndBackClearsTheOverride() {
        var l = line()
        l.count(in: .reps, for: Self.bike)
        XCTAssertEqual(l.measure, .reps)
        XCTAssertEqual(l.targetReps, Measure.reps.defaultTarget)
        l.targetReps = 40
        l.count(in: .reps, for: Self.bike)
        XCTAssertEqual(l.targetReps, 40)
        l.count(in: .minutes, for: Self.bike)
        XCTAssertNil(l.measure)
        XCTAssertEqual(l.targetReps, Measure.minutes.defaultTarget)
    }

    func testARepLineHasNoCountdownAndLogsReps() {
        var s = session(line(.reps, reps: 50))
        XCTAssertNil(s.setDuration)
        s.startSet(at: Fixtures.t0)
        XCTAssertNil(s.setRemaining(at: Fixtures.t0 + 10))
        s.completeSet(at: Fixtures.t0 + 60)
        XCTAssertEqual(s.logs[0].measure, .reps)
        XCTAssertEqual(LoadFormat.summary(s.logs, exercise: Self.bike, unit: .kilograms), "1 × 50")
    }

    func testATimedLineCountsDown() {
        var s = session(line())
        s.startSet(at: Fixtures.t0)
        XCTAssertEqual(s.setRemaining(at: Fixtures.t0), 20 * 60)
        s.completeSet(at: Fixtures.t0 + 1200)
        XCTAssertEqual(s.logs[0].measure, .minutes)
    }

    func testFormatUsesTheLine() {
        XCTAssertEqual(LoadFormat.line(line(.reps, reps: 50), exercise: Self.bike, unit: .kilograms), "3 × 50")
        XCTAssertEqual(LoadFormat.line(line(), exercise: Self.bike, unit: .kilograms), "3 × 20 min")
    }

    func testLastTimeOnlyComparesLikeWithLike() {
        func log(_ id: String, _ at: TimeInterval, _ measure: Measure?, reps: Int) -> WorkoutLog {
            WorkoutLog(id: id, workoutID: "w", workoutName: "W", startedAt: Fixtures.t0 + at, finishedAt: Fixtures.t0 + at + 1,
                       sets: [SetLog(id: id + "1", sessionID: id, exerciseID: Self.bike.id, setNumber: 1, reps: reps,
                                     weight: .zero, completedAt: Fixtures.t0 + at, measure: measure)])
        }
        let logs = [log("a", 0, .minutes, reps: 20), log("b", 100, .reps, reps: 50)]
        XCTAssertEqual(Stats.lastTime(exerciseID: Self.bike.id, setNumber: 1, measure: .minutes, in: logs)?.reps, 20)
        XCTAssertEqual(Stats.lastTime(exerciseID: Self.bike.id, setNumber: 1, measure: .reps, in: logs)?.reps, 50)
        let old = [log("c", 0, nil, reps: 15)]
        XCTAssertEqual(Stats.lastTime(exerciseID: Self.bike.id, setNumber: 1, measure: .reps, in: old)?.reps, 15)
    }

    func testStoreRoundTripsLineAndSetMeasure() throws {
        let url = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString + ".sqlite")
        defer { try? FileManager.default.removeItem(at: url) }
        let store = try SQLiteStore(url: url, catalogue: [Self.bike])
        let w = Workout(id: "w", name: "W", exercises: [line(.reps, reps: 50)])
        try store.saveWorkout(w)
        var s = session(w.exercises[0])
        s.completeSet(at: Fixtures.t0)
        try store.saveLog(s.finish(at: Fixtures.t0 + 1, logID: "log"))
        XCTAssertEqual(try store.workouts().first?.exercises.first?.measure, .reps)
        XCTAssertEqual(try store.logs().first?.sets.first?.measure, .reps)
    }
}
