import XCTest
@testable import GymBuddyCore

final class AddMidSessionTests: XCTestCase {
    private let extra = WorkoutExercise(
        id: "p-extra", exerciseID: Fixtures.rows.id, targetSets: 2, targetReps: 8, targetWeight: Weight(pounds: 40)
    )

    func testAddedGoesToTheEndAndLeavesTheCurrentAlone() {
        var s = Fixtures.session()
        s.add(Fixtures.rows, plan: extra)
        XCTAssertEqual(s.entries.last?.id, "p-extra")
        XCTAssertTrue(s.entries.last!.isAdded)
        XCTAssertEqual(s.exerciseIndex, 0)
    }

    func testAddingAfterEverythingIsDoneContinuesWithIt() {
        var s = Fixtures.session()
        for i in 0..<7 { s.completeSet(at: Fixtures.t0 + Double(i * 60)) }
        XCTAssertTrue(s.isFinished)
        s.add(Fixtures.rows, plan: extra)
        XCTAssertEqual(s.currentEntry?.id, "p-extra")
        XCTAssertEqual(s.workingReps, 8)
        XCTAssertEqual(s.workingWeight, Weight(pounds: 40))
    }

    func testAddedLinesNeverDriftIntoThePlan() {
        var s = Fixtures.session()
        s.add(Fixtures.rows, plan: extra)
        s.jump(toExerciseAt: 3)
        s.adjustWeight(by: 2, in: .pounds)
        s.completeSet(at: Fixtures.t0)
        XCTAssertTrue(s.driftedLineIDs.isEmpty)
        XCTAssertEqual(s.finish(at: Fixtures.t0).sets.last?.planLineID, "p-extra")
    }

    func testAddedSurvivesAKilledApp() throws {
        var s = Fixtures.session()
        s.add(Fixtures.rows, plan: extra)
        let back = try JSONDecoder().decode(WorkoutSession.self, from: JSONEncoder().encode(s))
        XCTAssertTrue(back.entries.last!.isAdded)
        XCTAssertFalse(back.entries[0].isAdded)
    }
}
