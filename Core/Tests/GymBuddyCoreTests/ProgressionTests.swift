import XCTest
@testable import GymBuddyCore

final class ProgressionTests: XCTestCase {
    private let plan = WorkoutExercise(
        id: "p-rows", exerciseID: "rows",
        targetSets: 3, targetReps: 10, targetWeight: Weight(pounds: 50)
    )

    private func session(_ id: String, day: Int, reps: [Int], pounds: Double) -> WorkoutLog {
        let start = Fixtures.t0 + Double(day) * 86_400
        let sets = reps.enumerated().map { i, r in
            SetLog(id: "\(id)-\(i)", sessionID: id, exerciseID: "rows",
                   setNumber: i + 1, reps: r, weight: Weight(pounds: pounds),
                   completedAt: start)
        }
        return WorkoutLog(id: id, workoutID: "w", workoutName: "W",
                          startedAt: start, finishedAt: start + 1_800, sets: sets)
    }

    private func suggest(_ history: [WorkoutLog]) -> Progression.Suggestion {
        Progression.suggest(for: plan, equipment: .machine, history: history, unit: .pounds)
    }

    func testHittingEveryTargetRepStepsTheLoadUpByOneRealIncrement() {
        let result = suggest([session("a", day: 0, reps: [10, 10, 10], pounds: 50)])
        XCTAssertEqual(result, .increase(to: Weight(pounds: 60), from: Weight(pounds: 50)))
        XCTAssertEqual(result.weight.pounds, 60, accuracy: 0.000_01)
    }

    func testFallingShortOnceHoldsTheSameLoad() {
        let result = suggest([session("a", day: 0, reps: [10, 10, 7], pounds: 50)])
        XCTAssertEqual(result, .hold(Weight(pounds: 50)))
    }

    func testMissingASetCountsAsFallingShort() {
        let result = suggest([session("a", day: 0, reps: [10, 10], pounds: 50)])
        XCTAssertEqual(result, .hold(Weight(pounds: 50)))
    }

    func testFallingShortTwiceRunningDeloads() {
        let result = suggest([
            session("a", day: 0, reps: [10, 9, 8], pounds: 50),
            session("b", day: 3, reps: [10, 8, 6], pounds: 50),
        ])
        XCTAssertEqual(result, .deload(to: Weight(pounds: 40), from: Weight(pounds: 50)))
    }

    func testAGoodSessionResetsTheMissCount() {
        let result = suggest([
            session("a", day: 0, reps: [10, 9, 8], pounds: 50),
            session("b", day: 3, reps: [10, 10, 10], pounds: 50),
            session("c", day: 6, reps: [10, 10, 9], pounds: 60),
        ])
        XCTAssertEqual(result, .hold(Weight(pounds: 60)))
    }

    func testNoHistoryMeansNoOpinion() {
        XCTAssertEqual(suggest([]), .hold(plan.targetWeight))
    }

    func testUnloadableEquipmentIsNeverGivenANumberToChase() {
        let result = Progression.suggest(
            for: plan, equipment: .band,
            history: [session("a", day: 0, reps: [10, 10, 10], pounds: 50)],
            unit: .pounds
        )
        XCTAssertEqual(result, .hold(plan.targetWeight))
    }
}
