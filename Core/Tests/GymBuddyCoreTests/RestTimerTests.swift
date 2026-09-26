import XCTest
@testable import GymBuddyCore

final class RestTimerTests: XCTestCase {
    private let t0 = Date(timeIntervalSince1970: 1_000_000)

    func testCountsDownFromTheDurationItWasStartedWith() {
        var timer = RestTimer()
        timer.start(60, at: t0)
        XCTAssertEqual(timer.remaining(at: t0), 60)
        XCTAssertEqual(timer.remaining(at: t0 + 32), 28)
    }

    func testNeverReportsNegativeTimeLeft() {
        var timer = RestTimer()
        timer.start(30, at: t0)
        XCTAssertEqual(timer.remaining(at: t0 + 500), 0)
        XCTAssertTrue(timer.hasFired(at: t0 + 500))
    }

    func testRingFillsRatherThanDrains() {
        var timer = RestTimer()
        timer.start(60, at: t0)
        XCTAssertEqual(timer.progress(at: t0), 0)
        XCTAssertEqual(timer.progress(at: t0 + 30), 0.5, accuracy: 0.000_001)
        XCTAssertEqual(timer.progress(at: t0 + 90), 1)
    }

    func testExtendingKeepsTheTimeAlreadyRested() {
        var timer = RestTimer()
        timer.start(60, at: t0)
        timer.extend(by: 30)
        // 40s in, 90s total — not a fresh 90 from now.
        XCTAssertEqual(timer.remaining(at: t0 + 40), 50)
    }

    func testExtendingADismissedTimerDoesNothing() {
        var timer = RestTimer()
        timer.extend(by: 30)
        XCTAssertFalse(timer.isRunning)
        XCTAssertEqual(timer.remaining(at: t0), 0)
    }

    func testDismissStopsIt() {
        var timer = RestTimer()
        timer.start(60, at: t0)
        timer.dismiss()
        XCTAssertFalse(timer.isRunning)
        XCTAssertFalse(timer.hasFired(at: t0 + 500))
    }

    func testFormatsAsHoursMinutesSeconds() {
        XCTAssertEqual(RestTimer.format(28), "00:00:28")
        XCTAssertEqual(RestTimer.format(5), "00:00:05")
        XCTAssertEqual(RestTimer.format(3_661), "01:01:01")
    }
}
