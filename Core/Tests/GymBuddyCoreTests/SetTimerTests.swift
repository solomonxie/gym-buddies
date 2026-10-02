import XCTest
@testable import GymBuddyCore

final class SetTimerTests: XCTestCase {
    func treadmill() -> WorkoutSession {
        TreadmillTests().session()
    }

    func testARepSetCountsUpAndHasNoCountdown() {
        var s = Fixtures.session()
        XCTAssertFalse(s.isSetRunning)
        XCTAssertNil(s.setDuration)
        s.startSet(at: Fixtures.t0)
        XCTAssertEqual(s.setElapsed(at: Fixtures.t0 + 42), 42)
        XCTAssertNil(s.setRemaining(at: Fixtures.t0 + 42))
        XCTAssertFalse(s.isSetTimeUp(at: Fixtures.t0 + 9999))
    }

    func testATreadmillSetCountsDownItsMinutes() {
        var s = treadmill()
        XCTAssertEqual(s.setDuration, 20 * 60)
        XCTAssertNil(s.setRemaining(at: Fixtures.t0))
        s.startSet(at: Fixtures.t0)
        XCTAssertEqual(s.setRemaining(at: Fixtures.t0 + 60), 19 * 60)
        XCTAssertFalse(s.isSetTimeUp(at: Fixtures.t0 + 1199))
        XCTAssertTrue(s.isSetTimeUp(at: Fixtures.t0 + 1200))
        XCTAssertEqual(s.setRemaining(at: Fixtures.t0 + 1500), 0)
    }

    /// Nudging minutes mid-walk moves the finish line, not the start.
    func testNudgingTheCountMovesTheCountdown() {
        var s = treadmill()
        s.startSet(at: Fixtures.t0)
        s.adjustReps(by: 5)
        XCTAssertEqual(s.setRemaining(at: Fixtures.t0 + 60), 24 * 60)
    }

    func testTheLogRecordsWhenTheSetStartedAndTheClockResets() {
        var s = Fixtures.session()
        s.startSet(at: Fixtures.t0)
        s.completeSet(at: Fixtures.t0 + 45)
        XCTAssertEqual(s.logs[0].startedAt, Fixtures.t0)
        XCTAssertEqual(s.logs[0].duration, 45)
        XCTAssertFalse(s.isSetRunning)

        s.completeSet(at: Fixtures.t0 + 100)
        XCTAssertNil(s.logs[1].startedAt)
        XCTAssertNil(s.logs[1].duration)
    }

    func testMovingToAnotherExerciseDropsARunningSet() {
        var s = Fixtures.session()
        s.startSet(at: Fixtures.t0)
        s.skipExercise()
        XCTAssertFalse(s.isSetRunning)
        s.startSet(at: Fixtures.t0)
        s.jump(toExerciseAt: 0)
        XCTAssertFalse(s.isSetRunning)
    }

    func testCancelLeavesNothingLogged() {
        var s = Fixtures.session()
        s.startSet(at: Fixtures.t0)
        s.cancelSet()
        XCTAssertFalse(s.isSetRunning)
        XCTAssertTrue(s.logs.isEmpty)
    }

    func testARunningSetSurvivesAKilledApp() throws {
        var s = Fixtures.session()
        s.startSet(at: Fixtures.t0)
        let back = try JSONDecoder().decode(WorkoutSession.self, from: JSONEncoder().encode(s))
        XCTAssertEqual(back.setStartedAt, Fixtures.t0)
    }

    func testStoreRoundTripsStartedAt() throws {
        let url = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString + ".sqlite")
        defer { try? FileManager.default.removeItem(at: url) }
        let store = try SQLiteStore(url: url, catalogue: Array(Fixtures.catalogue.values))
        var s = Fixtures.session()
        s.startSet(at: Fixtures.t0)
        s.completeSet(at: Fixtures.t0 + 30)
        s.completeSet(at: Fixtures.t0 + 90)
        try store.saveLog(s.finish(at: Fixtures.t0 + 100, logID: "log"))
        let sets = try XCTUnwrap(store.logs().first?.sets)
        XCTAssertEqual(sets[0].duration, 30)
        XCTAssertNil(sets[1].startedAt)
    }
}

final class PrimaryActionTests: XCTestCase {
    func testARepSetNeedsNoStartOutsideRest() {
        var s = Fixtures.session()
        var seen: [WorkoutSession.PrimaryAction] = []
        var t = Fixtures.t0
        while !s.isFinished {
            seen.append(s.primaryAction(resting: false))
            s.completeSet(at: t)
            t += 60
        }
        XCTAssertEqual(seen.first, .endSetAndNextExercise)
        XCTAssertTrue(seen.contains(.endSet(2)))
        XCTAssertFalse(seen.contains { if case .startSet = $0 { true } else { false } })
        XCTAssertEqual(seen.filter { $0 == .endSetAndFinish }.count, 1)
        XCTAssertEqual(seen.last, .endSetAndFinish)
    }

    func testRestingAlwaysOffersStart() {
        var s = Fixtures.session()
        s.completeSet(at: Fixtures.t0)
        XCTAssertEqual(s.primaryAction(resting: true), .startSet(1))
        s.startSet(at: Fixtures.t0 + 30)
        XCTAssertNotEqual(s.primaryAction(resting: true), .startSet(1))
    }

    func testATimedSetStartsThenEnds() {
        var s = TreadmillTests().session()
        XCTAssertTrue(s.isTimed)
        XCTAssertEqual(s.primaryAction(resting: false), .startSet(1))
        XCTAssertEqual(s.primaryAction(resting: true), .startSet(1))
        s.startSet(at: Fixtures.t0)
        XCTAssertEqual(s.primaryAction(resting: false), .endSetAndFinish)
    }

    func testARepExerciseIsNotTimed() {
        XCTAssertFalse(Fixtures.session().isTimed)
    }
}

final class RepSetStartTests: XCTestCase {
    func testARepSetStartsWhenTheRestBeforeItRanOut() {
        var s = Fixtures.session()
        s.completeSets(1, at: Fixtures.t0 + 100, restEndedAt: Fixtures.t0 + 60)
        XCTAssertEqual(s.logs[0].startedAt, Fixtures.t0 + 60)
        XCTAssertEqual(s.logs[0].duration, 40)
    }

    func testEndingASetDuringRestLeavesItsStartBlank() {
        var s = Fixtures.session()
        s.completeSets(1, at: Fixtures.t0 + 30, restEndedAt: nil)
        XCTAssertNil(s.logs[0].startedAt)
    }

    func testAStartedTimedSetKeepsItsOwnStart() {
        var s = TreadmillTests().session()
        s.startSet(at: Fixtures.t0 + 90)
        s.completeSets(1, at: Fixtures.t0 + 120, restEndedAt: Fixtures.t0 + 60)
        XCTAssertEqual(s.logs[0].startedAt, Fixtures.t0 + 90)
    }

    func testARepSetBeganWhenRestRanOutButATimedOneWaitsForStart() {
        XCTAssertEqual(Fixtures.session().setBegan(restEndedAt: Fixtures.t0), Fixtures.t0)
        XCTAssertNil(TreadmillTests().session().setBegan(restEndedAt: Fixtures.t0))
    }

    func testEndsAtIsStartPlusDuration() {
        var r = RestTimer()
        XCTAssertNil(r.endsAt)
        r.start(60, at: Fixtures.t0)
        r.extend(by: 30)
        XCTAssertEqual(r.endsAt, Fixtures.t0 + 90)
    }
}
