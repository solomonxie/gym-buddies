import XCTest
@testable import GymBuddyCore

final class UndoSetTests: XCTestCase {
    func testNothingToRewindAtTheStart() {
        let s = Fixtures.session()
        XCTAssertNil(s.rewind)
    }

    func testUndoesASetMidExercise() {
        var s = Fixtures.session()
        s.completeSet(at: Fixtures.t0)            // walking → rows
        s.adjustReps(by: -2)
        s.completeSet(at: Fixtures.t0 + 60)       // rows 1 of 3, 8 reps
        guard case .set = s.rewind else { return XCTFail() }
        s.rewindOne()
        XCTAssertEqual(s.currentEntry?.id, "p-rows")
        XCTAssertEqual(s.currentSetNumber, 1)
        XCTAssertEqual(s.completedSets(for: "p-rows"), 0)
        XCTAssertEqual(s.workingReps, 8)
        XCTAssertEqual(s.logs.count, 1)
    }

    func testUndoingAnExercisesLastSetReturnsToIt() {
        var s = Fixtures.session()
        s.completeSet(at: Fixtures.t0)            // walking done → rows
        XCTAssertEqual(s.currentEntry?.id, "p-rows")
        s.rewindOne()
        XCTAssertEqual(s.currentEntry?.id, "p-walking")
        XCTAssertEqual(s.completedSets(for: "p-walking"), 0)
        XCTAssertNil(s.backEntry)
    }

    func testUndoesTheFinishingSet() {
        var s = Fixtures.session()
        for i in 0..<7 { s.completeSet(at: Fixtures.t0 + Double(i * 60)) }
        XCTAssertTrue(s.isFinished)
        s.rewindOne()
        XCTAssertFalse(s.isFinished)
        XCTAssertEqual(s.currentEntry?.id, "p-pulldowns")
        XCTAssertEqual(s.currentSetNumber, 3)
    }

    func testASkipAfterTheSetIsUndoneFirst() {
        var s = Fixtures.session()
        s.completeSet(at: Fixtures.t0)            // walking → rows
        s.completeSet(at: Fixtures.t0 + 60)       // rows 1 of 3
        s.skipExercise()                           // → pull-downs
        guard case .exercise(let e) = s.rewind else { return XCTFail() }
        XCTAssertEqual(e.id, "p-rows")
        s.rewindOne()
        XCTAssertEqual(s.currentEntry?.id, "p-rows")
        XCTAssertEqual(s.completedSets(for: "p-rows"), 1)
        s.rewindOne()
        XCTAssertEqual(s.completedSets(for: "p-rows"), 0)
    }

    func testASetAfterAJumpIsUndoneBeforeTheJump() {
        var s = Fixtures.session()
        s.completeSet(at: Fixtures.t0)            // walking → rows
        s.completeSet(at: Fixtures.t0 + 60)       // rows 1 of 3
        s.jump(toExerciseAt: 2)
        s.completeSet(at: Fixtures.t0 + 120)      // pull-downs 1 of 3
        s.rewindOne()
        XCTAssertEqual(s.currentEntry?.id, "p-pulldowns")
        XCTAssertEqual(s.completedSets(for: "p-pulldowns"), 0)
        s.rewindOne()
        XCTAssertEqual(s.currentEntry?.id, "p-rows")
        XCTAssertEqual(s.completedSets(for: "p-rows"), 1)
    }

    func testUndoSurvivesAKilledApp() throws {
        var s = Fixtures.session()
        s.completeSet(at: Fixtures.t0)
        s.skipExercise()
        var back = try JSONDecoder().decode(WorkoutSession.self, from: JSONEncoder().encode(s))
        back.rewindOne()
        XCTAssertEqual(back.currentEntry?.id, "p-rows")
        back.rewindOne()
        XCTAssertEqual(back.currentEntry?.id, "p-walking")
    }
}
