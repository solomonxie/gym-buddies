import XCTest
@testable import GymBuddyCore

final class StatsTests: XCTestCase {
    private func set(
        _ id: String,
        _ exercise: String,
        reps: Int,
        pounds: Double,
        at date: Date = Fixtures.t0
    ) -> SetLog {
        SetLog(id: id, sessionID: "s", exerciseID: exercise, setNumber: 1,
               reps: reps, weight: Weight(pounds: pounds), completedAt: date)
    }

    /// Weight is stored in kilograms, so pounds never come back bit-exact.
    private func assertClose(
        _ actual: [Double], _ expected: [Double],
        file: StaticString = #filePath, line: UInt = #line
    ) {
        XCTAssertEqual(actual.count, expected.count, file: file, line: line)
        for (a, e) in zip(actual, expected) {
            XCTAssertEqual(a, e, accuracy: 0.000_01, file: file, line: line)
        }
    }

    private func log(_ id: String, day: Int, sets: [SetLog]) -> WorkoutLog {
        let start = Fixtures.t0 + Double(day) * 86_400
        return WorkoutLog(id: id, workoutID: "w", workoutName: "W",
                          startedAt: start, finishedAt: start + 1_800, sets: sets)
    }

    func testVolumeIsRepsTimesLoad() {
        let sets = [set("1", "rows", reps: 10, pounds: 50),
                    set("2", "rows", reps: 8, pounds: 50)]
        XCTAssertEqual(Stats.volume(sets).pounds, 900, accuracy: 0.000_01)
        XCTAssertEqual(Stats.totalReps(sets), 18)
    }

    func testPersonalRecordIsTheHeaviestSet() {
        let sets = [set("1", "rows", reps: 12, pounds: 40),
                    set("2", "rows", reps: 3, pounds: 60),
                    set("3", "pulls", reps: 3, pounds: 90)]
        XCTAssertEqual(Stats.personalRecord(exerciseID: "rows", in: sets)?.id, "2")
    }

    func testPersonalRecordBreaksTiesOnReps() {
        let sets = [set("1", "rows", reps: 3, pounds: 60),
                    set("2", "rows", reps: 5, pounds: 60)]
        XCTAssertEqual(Stats.personalRecord(exerciseID: "rows", in: sets)?.id, "2")
    }

    func testPersonalRecordIsAbsentForAnUntouchedExercise() {
        XCTAssertNil(Stats.personalRecord(exerciseID: "squats", in: []))
    }

    func testSeriesIsOnePointPerSessionOldestFirst() {
        let logs = [
            log("b", day: 7, sets: [set("3", "rows", reps: 10, pounds: 60)]),
            log("a", day: 0, sets: [set("1", "rows", reps: 10, pounds: 50),
                                    set("2", "rows", reps: 10, pounds: 50)]),
        ]
        let top = Stats.series(exerciseID: "rows", metric: .topWeight, from: logs, in: .pounds)
        assertClose(top.map(\.value), [50, 60])

        let volume = Stats.series(exerciseID: "rows", metric: .volume, from: logs, in: .pounds)
        assertClose(volume.map(\.value), [1_000, 600])
    }

    func testSeriesSkipsSessionsThatDidNotTouchTheExercise() {
        let logs = [log("a", day: 0, sets: [set("1", "pulls", reps: 10, pounds: 50)])]
        XCTAssertTrue(Stats.series(exerciseID: "rows", metric: .reps, from: logs, in: .pounds).isEmpty)
    }

    func testVolumeSplitsByMuscleGroup() {
        let sets = [set("1", Fixtures.rows.id, reps: 10, pounds: 50),
                    set("2", Fixtures.walking.id, reps: 5, pounds: 3)]
        let byGroup = Stats.volumeByMuscleGroup(sets, exercises: Fixtures.catalogue, in: .pounds)
        XCTAssertEqual(byGroup[.back] ?? 0, 500, accuracy: 0.000_01)
        XCTAssertEqual(byGroup[.cardio] ?? 0, 15, accuracy: 0.000_01)
    }

    func testStreakCountsConsecutiveDaysBackFromToday() {
        let today = Fixtures.t0 + 2 * 86_400
        let logs = [log("a", day: 0, sets: []), log("b", day: 1, sets: []), log("c", day: 2, sets: [])]
        XCTAssertEqual(Stats.streak(logs, asOf: today), 3)
    }

    func testStreakBreaksOnAMissedDay() {
        let today = Fixtures.t0 + 3 * 86_400
        let logs = [log("a", day: 0, sets: []), log("c", day: 3, sets: [])]
        XCTAssertEqual(Stats.streak(logs, asOf: today), 1)
    }

    func testStreakIsZeroWhenNothingWasLoggedToday() {
        let today = Fixtures.t0 + 5 * 86_400
        XCTAssertEqual(Stats.streak([log("a", day: 0, sets: [])], asOf: today), 0)
    }
}
