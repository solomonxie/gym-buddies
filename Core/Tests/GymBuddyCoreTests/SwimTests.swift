import XCTest
@testable import GymBuddyCore

final class SwimTests: XCTestCase {
    static let freestyle = SeedLibrary.byID["freestyle-swim"]!

    func testLapsAreOfferedOnlyInAPool() {
        XCTAssertEqual(Measure.options(for: .pool), [.laps, .minutes])
        XCTAssertFalse(Measure.options(for: .barbell).contains(.laps))
        XCTAssertEqual(Self.freestyle.measure, .laps)
        XCTAssertFalse(Equipment.pool.isLoadable)
    }

    func testSetsRememberThePoolAndBecomeDistance() {
        let workout = Workout(id: "w", name: "Swim", exercises: [
            WorkoutExercise(id: "l", exerciseID: Self.freestyle.id, targetSets: 2, targetReps: 4,
                            targetWeight: .zero, poolLength: .m50),
        ])
        var s = WorkoutSession(id: "s", workout: workout, exercises: [Self.freestyle.id: Self.freestyle],
                               startedAt: Fixtures.t0, defaultRestSeconds: 30)
        s.completeSet(at: Fixtures.t0)
        s.completeSet(at: Fixtures.t0)
        XCTAssertEqual(s.logs.map(\.poolLength), [.m50, .m50])
        XCTAssertEqual(s.logs[0].distance, 200)
        XCTAssertEqual(LoadFormat.summary(s.logs, exercise: Self.freestyle, unit: .kilograms), "2 × 4 laps · 400 m")
    }

    func testLineShowsThePoolAndDefaultsToTwentyFiveMetres() {
        let line = WorkoutExercise(id: "l", exerciseID: Self.freestyle.id, targetSets: 8, targetReps: 2, targetWeight: .zero)
        XCTAssertEqual(LoadFormat.line(line, exercise: Self.freestyle, unit: .pounds), "8 × 2 laps · 25 m pool")
        XCTAssertEqual(line.pool(for: Fixtures.rows), nil)
    }

    func testYardPoolsCountInYards() {
        XCTAssertEqual(PoolLength.yd25.distance(laps: 40), "1,000 yd")
        XCTAssertEqual(PoolLength.m33.distance(laps: 3), "100 m")
        XCTAssertEqual(Measure.laps.format(1), "1 lap")
    }

    func testPlannedMinutesUseLapPaceAndTimedLengths() {
        let w = Workout(id: "w", name: "Mix", exercises: [
            WorkoutExercise(id: "a", exerciseID: Self.freestyle.id, targetSets: 4, targetReps: 2,
                            targetWeight: .zero, restSeconds: 30, poolLength: .m25),
            WorkoutExercise(id: "b", exerciseID: "walking", targetSets: 1, targetReps: 20,
                            targetWeight: .zero, restSeconds: 60),
        ])
        // 4 × (60 + 30) + (1200 + 60) = 1620 s.
        XCTAssertEqual(Stats.plannedMinutes(w, defaultRest: 60, exercises: SeedLibrary.byID), 27)
    }
}
