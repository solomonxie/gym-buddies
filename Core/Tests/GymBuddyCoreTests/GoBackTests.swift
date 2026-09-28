import XCTest
@testable import GymBuddyCore

final class GoBackTests: XCTestCase {
    func testNothingToGoBackToAtTheStart() {
        var s = Fixtures.session()
        XCTAssertNil(s.backEntry)
        s.goBack()
        XCTAssertEqual(s.exerciseIndex, 0)
    }

    func testBackUndoesASkip() {
        var s = Fixtures.session()
        s.skipExercise()
        XCTAssertEqual(s.exerciseIndex, 1)
        XCTAssertEqual(s.backEntry?.id, "p-walking")
        s.goBack()
        XCTAssertEqual(s.exerciseIndex, 0)
        XCTAssertFalse(s.entries[0].isSkipped)
        XCTAssertNil(s.backEntry)
    }

    func testBackReturnsToAPartlyDoneExerciseAndKeepsItsSets() {
        var s = Fixtures.session()
        s.completeSet(at: Fixtures.t0)           // walking done → rows
        s.completeSet(at: Fixtures.t0 + 60)      // rows 1 of 3
        s.skipExercise()                          // → pull-downs
        s.goBack()
        XCTAssertEqual(s.currentEntry?.id, "p-rows")
        XCTAssertEqual(s.currentSetNumber, 2)
        XCTAssertEqual(s.completedSets(for: "p-rows"), 1)
    }

    func testAFinishedExerciseIsNotSomewhereToGoBackTo() {
        var s = Fixtures.session()
        s.completeSet(at: Fixtures.t0)           // walking done → rows
        XCTAssertNil(s.backEntry)
    }

    func testBackStepsThroughSeveralSkips() {
        var s = Fixtures.session()
        s.skipExercise()
        s.skipExercise()
        XCTAssertEqual(s.exerciseIndex, 2)
        s.goBack()
        XCTAssertEqual(s.exerciseIndex, 1)
        s.goBack()
        XCTAssertEqual(s.exerciseIndex, 0)
    }

    func testBackAfterAJumpReturnsToWhereItCameFrom() {
        var s = Fixtures.session()
        s.jump(toExerciseAt: 2)
        s.goBack()
        XCTAssertEqual(s.exerciseIndex, 0)
    }

    func testBackSurvivesAKilledApp() throws {
        var s = Fixtures.session()
        s.skipExercise()
        var back = try JSONDecoder().decode(WorkoutSession.self, from: JSONEncoder().encode(s))
        back.goBack()
        XCTAssertEqual(back.exerciseIndex, 0)
    }
}
