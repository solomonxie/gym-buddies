import XCTest
@testable import GymBuddyCore

final class WorkoutSessionTests: XCTestCase {
    func testStartsOnTheFirstExerciseWithItsPlannedValues() {
        let session = Fixtures.session()
        XCTAssertEqual(session.currentEntry?.exercise.name, "Walking")
        XCTAssertEqual(session.currentSetNumber, 1)
        XCTAssertEqual(session.workingReps, 5)
        XCTAssertEqual(session.workingWeight.pounds, 3, accuracy: 0.000_001)
        XCTAssertEqual(session.upcoming.count, 2)
    }

    func testLoggingASetAdvancesTheCounterAndRests() {
        var session = Fixtures.session()
        session.skipExercise()  // past Walking, onto the rows

        let outcome = session.completeSet(at: Fixtures.t0 + 40, logID: "l1")
        XCTAssertEqual(outcome, .restThenNextSet(seconds: 60))
        XCTAssertEqual(session.currentSetNumber, 2)
        XCTAssertEqual(session.logs.count, 1)
        XCTAssertEqual(session.logs[0].setNumber, 1)
        XCTAssertEqual(session.logs[0].reps, 10)
    }

    func testFinishingTheLastSetMovesToTheNextExercise() {
        var session = Fixtures.session()
        session.skipExercise()

        session.completeSet(at: Fixtures.t0 + 40, logID: "l1")
        session.completeSet(at: Fixtures.t0 + 120, logID: "l2")
        let outcome = session.completeSet(at: Fixtures.t0 + 200, logID: "l3")

        XCTAssertEqual(outcome, .restThenNextExercise(name: "Lat Pull Downs", seconds: 60))
        XCTAssertEqual(session.currentEntry?.exercise.name, "Lat Pull Downs")
        XCTAssertEqual(session.currentSetNumber, 1)
    }

    func testMovingOnReloadsTheNextExercisesPlannedValues() {
        var session = Fixtures.session()
        session.skipExercise()
        session.adjustReps(by: -4)
        session.adjustWeight(by: 2, in: .pounds)
        XCTAssertEqual(session.workingReps, 6)
        XCTAssertEqual(session.workingWeight.pounds, 70, accuracy: 0.000_001)

        session.skipExercise()
        XCTAssertEqual(session.workingReps, 10)
        XCTAssertEqual(session.workingWeight.pounds, 50, accuracy: 0.000_001)
    }

    func testWeightStepsByTheEquipmentNotByOne() {
        var session = Fixtures.session()
        session.skipExercise()  // rows, a machine: 10 lb a pin
        session.adjustWeight(by: 1, in: .pounds)
        XCTAssertEqual(session.workingWeight.pounds, 60, accuracy: 0.000_001)
    }

    func testTheLogRecordsWhatWasLiftedNotWhatWasPlanned() {
        var session = Fixtures.session()
        session.skipExercise()
        session.adjustReps(by: -2)
        session.adjustWeight(by: -1, in: .pounds)
        session.completeSet(at: Fixtures.t0 + 40, logID: "l1")

        XCTAssertEqual(session.logs[0].reps, 8)
        XCTAssertEqual(session.logs[0].weight.pounds, 40, accuracy: 0.000_001)
        // The saved plan is untouched.
        XCTAssertEqual(session.entries[1].plan.targetReps, 10)
        XCTAssertEqual(session.entries[1].plan.targetWeight.pounds, 50, accuracy: 0.000_001)
    }

    func testRepsCannotGoNegative() {
        var session = Fixtures.session()
        session.adjustReps(by: -99)
        XCTAssertEqual(session.workingReps, 0)
    }

    func testChangingTargetSetsCannotStrandCompletedSets() {
        var session = Fixtures.session()
        session.skipExercise()
        session.completeSet(at: Fixtures.t0 + 40, logID: "l1")
        session.completeSet(at: Fixtures.t0 + 120, logID: "l2")

        session.changeTargetSets(to: 5)
        XCTAssertEqual(session.currentEntry?.plan.targetSets, 5)
        XCTAssertEqual(session.currentSetNumber, 3)

        // Below what's logged clamps to it, which finishes the line.
        session.changeTargetSets(to: 1)
        XCTAssertEqual(session.entries[1].plan.targetSets, 2)
        XCTAssertEqual(session.completedSets(for: "p-rows"), 2)
        XCTAssertEqual(session.currentEntry?.id, "p-pulldowns")
    }

    func testPerExerciseRestOverridesTheDefault() {
        var session = Fixtures.session()
        session.jump(toExerciseAt: 2)
        XCTAssertEqual(session.restSecondsForCurrentExercise, 90)
        XCTAssertEqual(session.completeSet(at: Fixtures.t0, logID: "l1"),
                       .restThenNextSet(seconds: 90))
    }

    func testSkippingKeepsAnythingAlreadyLogged() {
        var session = Fixtures.session()
        session.skipExercise()
        session.completeSet(at: Fixtures.t0 + 40, logID: "l1")
        session.skipExercise()

        XCTAssertEqual(session.logs.count, 1)
        XCTAssertFalse(session.entries[1].isSkipped)
        XCTAssertTrue(session.entries[0].isSkipped)
    }

    func testJumpingOutOfOrderIsAllowedWhenTheRackIsBusy() {
        var session = Fixtures.session()
        session.jump(toExerciseAt: 2)
        XCTAssertEqual(session.currentEntry?.exercise.name, "Lat Pull Downs")
        session.jump(toExerciseAt: 99)
        XCTAssertEqual(session.currentEntry?.exercise.name, "Lat Pull Downs")
    }

    func testTheSameExerciseTwiceKeepsSeparateSetCounters() {
        let doubled = Workout(
            id: "w", name: "Doubled",
            exercises: [
                WorkoutExercise(id: "a", exerciseID: Fixtures.rows.id,
                                targetSets: 2, targetReps: 10,
                                targetWeight: Weight(pounds: 50)),
                WorkoutExercise(id: "b", exerciseID: Fixtures.rows.id,
                                targetSets: 2, targetReps: 10,
                                targetWeight: Weight(pounds: 50)),
            ]
        )
        var session = WorkoutSession(
            id: "s", workout: doubled, exercises: Fixtures.catalogue, startedAt: Fixtures.t0
        )
        session.completeSet(at: Fixtures.t0, logID: "l1")
        session.completeSet(at: Fixtures.t0 + 60, logID: "l2")
        XCTAssertEqual(session.currentEntry?.id, "b")
        XCTAssertEqual(session.currentSetNumber, 1)
    }

    func testRunningOutOfExercisesEndsTheWorkout() {
        var session = Fixtures.session()
        session.skipExercise()
        session.skipExercise()
        let outcome = session.skipExercise()

        XCTAssertEqual(outcome, .workoutComplete)
        XCTAssertTrue(session.isFinished)
        XCTAssertNil(session.currentEntry)
        XCTAssertEqual(session.completeSet(at: Fixtures.t0), .workoutComplete)
    }

    func testFinishingProducesALogSpanningTheWholeSession() {
        var session = Fixtures.session()
        session.skipExercise()
        session.completeSet(at: Fixtures.t0 + 40, logID: "l1")

        let log = session.finish(at: Fixtures.t0 + 300, logID: "log1")
        XCTAssertEqual(log.workoutName, "Fraiser Heights")
        XCTAssertEqual(log.duration, 300)
        XCTAssertEqual(log.sets.count, 1)
    }

    func testElapsedNeverRunsBackwards() {
        let session = Fixtures.session()
        XCTAssertEqual(session.elapsed(at: Fixtures.t0 + 5), 5)
        XCTAssertEqual(session.elapsed(at: Fixtures.t0 - 100), 0)
    }
}
