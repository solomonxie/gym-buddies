import XCTest
@testable import GymBuddyCore

final class GymTests: XCTestCase {
    var calendar: Calendar = {
        var c = Calendar(identifier: .gregorian)
        c.timeZone = TimeZone(identifier: "UTC")!
        return c
    }()

    /// 2026-09-28 is a Monday (weekday 2).
    func date(day: Int = 28, _ hour: Int, _ minute: Int = 0) -> Date {
        calendar.date(from: DateComponents(year: 2026, month: 9, day: day, hour: hour, minute: minute))!
    }

    let weekdays = OpeningHours(periods: (2...6).map { .init(weekday: $0, open: 6 * 60, close: 22 * 60) })

    func testOpenReportsWhenItShuts() {
        XCTAssertEqual(weekdays.status(at: date(12), calendar: calendar), .open(until: date(22)))
    }

    func testClosedReportsTheNextOpening() {
        XCTAssertEqual(weekdays.status(at: date(23), calendar: calendar), .closed(opensAt: date(day: 29, 6)))
        XCTAssertEqual(weekdays.status(at: date(5, 59), calendar: calendar), .closed(opensAt: date(6)))
        // Saturday night waits for Monday.
        XCTAssertEqual(weekdays.status(at: date(day: 26, 10), calendar: calendar), .closed(opensAt: date(6)))
    }

    func testCloseTimeIsExclusive() {
        XCTAssertEqual(weekdays.status(at: date(22), calendar: calendar), .closed(opensAt: date(day: 29, 6)))
    }

    func testPastMidnightBelongsToTheDayItOpened() {
        let late = OpeningHours(periods: [.init(weekday: 2, open: 18 * 60, close: 2 * 60)])
        XCTAssertEqual(late.status(at: date(day: 29, 1), calendar: calendar), .open(until: date(day: 29, 2)))
        XCTAssertEqual(late.status(at: date(day: 29, 3), calendar: calendar), .closed(opensAt: calendar.date(byAdding: .day, value: 7, to: date(18))))
    }

    func testAllDayStretchesMergeIntoOneOpening() {
        let hours = OpeningHours(periods: [
            .init(weekday: 2, open: 0, close: 0),
            .init(weekday: 3, open: 0, close: 20 * 60),
        ])
        XCTAssertEqual(hours.status(at: date(12), calendar: calendar), .open(until: date(day: 29, 20)))
    }

    func testAlwaysNeverShuts() {
        XCTAssertEqual(OpeningHours.always.status(at: date(3), calendar: calendar), .open(until: nil))
        XCTAssertTrue(Gym.home.hours.isAlwaysOpen)
    }

    func testNoHoursMeansNeverOpens() {
        XCTAssertEqual(OpeningHours(periods: []).status(at: date(12), calendar: calendar), .closed(opensAt: nil))
    }

    func testTravelTimeIsCountedBeforeTheDoor() {
        let gym = Gym(id: "g", name: "Gym", hours: weekdays, travelMinutes: 30)
        let a = gym.availability(leaving: date(21, 45), calendar: calendar)
        XCTAssertEqual(a.arrival, date(22, 15))
        XCTAssertFalse(a.isOpen)
        let b = gym.availability(leaving: date(21), calendar: calendar)
        XCTAssertEqual(b.minutesBeforeClose, 30)
    }

    func testSortingPutsOpenAndNearFirst() {
        let far = Gym(id: "far", name: "Far", hours: .always, travelMinutes: 40)
        let near = Gym(id: "near", name: "Near", hours: .always, travelMinutes: 10)
        let shut = Gym(id: "shut", name: "Shut", hours: weekdays)
        let order = Gym.sorted([shut, far, near], leaving: date(23), calendar: calendar).map(\.gym.id)
        XCTAssertEqual(order, ["near", "far", "shut"])
    }

    func testMissingEquipmentIgnoresBodyweight() {
        let exercises = SeedLibrary.byID
        let workout = TemplateLibrary.all.first { $0.id == "lunch-break" }!.workout()
        XCTAssertEqual(Gym.home.missingEquipment(for: workout, exercises: exercises), [.machine, .dumbbell])
        let full = Gym(id: "g", name: "Gym", equipment: [.machine, .dumbbell])
        XCTAssertEqual(full.missingEquipment(for: workout, exercises: exercises), [])
        let preWork = TemplateLibrary.all.first { $0.id == "pre-work" }!.workout()
        XCTAssertEqual(Gym.home.missingEquipment(for: preWork, exercises: exercises), [])
    }

    func testPriceFormatsInCents() {
        let us = Locale(identifier: "en_US")
        XCTAssertEqual(Price(cents: 4500, period: .month).format(locale: us), "$45/month")
        XCTAssertEqual(Price(cents: 1250, period: .visit).format(locale: us), "$12.50/visit")
    }
}
