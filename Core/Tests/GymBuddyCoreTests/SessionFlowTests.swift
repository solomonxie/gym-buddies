import XCTest
@testable import GymBuddyCore

final class SessionFlowTests: XCTestCase {
    func testRestBetweenExercisesAppliesAfterTheLastSet() {
        var session = WorkoutSession(
            workout: Fixtures.workout, exercises: Fixtures.catalogue, startedAt: Fixtures.t0,
            defaultRestSeconds: 60, restBetweenExercisesSeconds: 120
        )
        XCTAssertEqual(session.completeSet(at: Fixtures.t0), .restThenNextExercise(name: "Seated Machine Rows", seconds: 120))
        XCTAssertEqual(session.completeSet(at: Fixtures.t0), .restThenNextSet(seconds: 60))
    }

    func testJumpingAheadThenFinishingWrapsBackToWhatWasJumpedOver() {
        var session = Fixtures.session()
        session.jump(toExerciseAt: 2)
        for _ in 0..<3 { session.completeSet(at: Fixtures.t0) }
        XCTAssertEqual(session.currentEntry?.exercise.id, Fixtures.walking.id)
    }

    func testFinalSetIsKnownBeforeItIsLogged() {
        var session = Fixtures.session()
        session.skipExercise()
        session.skipExercise()
        session.completeSet(at: Fixtures.t0)
        XCTAssertFalse(session.isOnFinalSet)
        session.completeSet(at: Fixtures.t0)
        XCTAssertTrue(session.isOnFinalSet)
    }

    func testDroppingSetsToWhatIsLoggedMovesOn() {
        var session = Fixtures.session()
        session.skipExercise()
        session.completeSet(at: Fixtures.t0)
        XCTAssertEqual(session.minimumTargetSets, 1)
        session.changeTargetSets(to: 1)
        XCTAssertEqual(session.currentEntry?.id, "p-pulldowns")
    }

    func testLongPressLogsSeveralButNotPastTheExercise() {
        var session = Fixtures.session()
        session.skipExercise()
        session.completeSets(5, at: Fixtures.t0)
        XCTAssertEqual(session.logs.count, 3)
        XCTAssertEqual(session.currentEntry?.id, "p-pulldowns")
    }

    func testDriftIsOnlyWeightAndPushesToTheRightLine() {
        var session = Fixtures.session()
        session.skipExercise()
        session.adjustWeight(by: 1, in: .pounds)
        session.completeSet(at: Fixtures.t0)
        session.skipExercise()
        session.adjustReps(by: -3)
        session.completeSet(at: Fixtures.t0)

        let drift = session.weightDrift
        XCTAssertEqual(drift.keys.sorted(), ["p-rows"])
        let updated = WorkoutSession.applying(drift, to: Fixtures.workout)
        XCTAssertEqual(updated.exercises[1].targetWeight, Weight(pounds: 60))
        XCTAssertEqual(updated.exercises[2].targetWeight, Weight(pounds: 50))
        XCTAssertEqual(Fixtures.workout.exercises[1].targetWeight, Weight(pounds: 50))
    }

    func testJumpingBackToASkippedExerciseUnskipsIt() {
        var session = Fixtures.session()
        session.skipExercise()
        session.jump(toExerciseAt: 0)
        XCTAssertFalse(session.entries[0].isSkipped)
    }

    func testSessionEncodesAndDecodes() throws {
        var session = Fixtures.session()
        session.completeSet(at: Fixtures.t0)
        session.markProgressionOffered(for: "p-rows")
        let data = try JSONEncoder().encode(session)
        let back = try JSONDecoder().decode(WorkoutSession.self, from: data)
        XCTAssertEqual(back.logs, session.logs)
        XCTAssertEqual(back.currentEntry?.id, "p-rows")
        XCTAssertTrue(back.progressionOffered.contains("p-rows"))
    }
}

final class StatsExtrasTests: XCTestCase {
    func log(_ id: String, day: Double, weight: Double, reps: Int = 10) -> WorkoutLog {
        let start = Fixtures.t0 + day * 86_400
        return WorkoutLog(
            id: id, workoutID: "w", workoutName: "W", startedAt: start, finishedAt: start + 1800,
            sets: [SetLog(id: id + "s", sessionID: id, exerciseID: "rows", setNumber: 1,
                          reps: reps, weight: Weight(pounds: weight), completedAt: start)]
        )
    }

    func testFirstTimeIsNotARecordButBeatingItIs() {
        let a = log("a", day: 0, weight: 50), b = log("b", day: 1, weight: 60), c = log("c", day: 2, weight: 55)
        let all = [a, b, c]
        XCTAssertTrue(Stats.records(in: a, history: all).isEmpty)
        XCTAssertEqual(Stats.records(in: b, history: all).first?.weight, Weight(pounds: 60))
        XCTAssertTrue(Stats.records(in: c, history: all).isEmpty)
    }

    func testLastTimeUsesTheMostRecentSession() {
        let all = [log("a", day: 0, weight: 50), log("b", day: 3, weight: 55, reps: 8)]
        let last = Stats.lastTime(exerciseID: "rows", setNumber: 1, in: all)
        XCTAssertEqual(last?.reps, 8)
        XCTAssertNil(Stats.lastTime(exerciseID: "nope", setNumber: 1, in: all))
    }

    func testEstimatedMinutesComesFromRealSessions() {
        XCTAssertEqual(Stats.estimatedMinutes(workoutID: "w", logs: [log("a", day: 0, weight: 50)]), 30)
        XCTAssertNil(Stats.estimatedMinutes(workoutID: "x", logs: []))
    }

    func testVolumeRowsKeepEmptyGroupsLast() {
        let rows = Stats.volumeRows(log("a", day: 0, weight: 50).sets, exercises: ["rows": Fixtures.rows], in: .pounds)
        XCTAssertEqual(rows.first?.group, .back)
        XCTAssertEqual(rows.first?.volume ?? 0, 500, accuracy: 0.01)
        XCTAssertEqual(rows.count, MuscleGroup.allCases.count - 1)
        XCTAssertEqual(rows.last?.volume, 0)
    }

    func testCompactFormat() {
        let plan = WorkoutExercise(id: "p", exerciseID: "rows", targetSets: 3, targetReps: 10,
                                   targetWeight: Weight(pounds: 50), restSeconds: 90)
        XCTAssertEqual(LoadFormat.line(plan, exercise: Fixtures.rows, unit: .pounds), "3 × 10 · 50 lb · rest 90s")
        XCTAssertEqual(LoadFormat.number(52.5), "52.5")
        XCTAssertEqual(LoadFormat.number(1.25), "1.25")
        XCTAssertEqual(LoadFormat.readout(Weight(pounds: 50), .pounds), "50.0")
        XCTAssertEqual(LoadFormat.volume(12400, .pounds), "12,400 lb")
        XCTAssertEqual(LoadFormat.duration(42 * 60 + 18), "42:18")
    }

    func testCSVHasOneRowPerSetAndEscapes() {
        var l = log("a", day: 0, weight: 50)
        l.workoutName = "Push, Pull"
        let csv = CSVExport.sessions([l], exercises: ["rows": Fixtures.rows], unit: .pounds)
        let lines = csv.split(separator: "\n")
        XCTAssertEqual(lines.count, 2)
        XCTAssertTrue(lines[1].contains("\"Push, Pull\",Seated Machine Rows,Back,1,10,50,500"))
    }
}
