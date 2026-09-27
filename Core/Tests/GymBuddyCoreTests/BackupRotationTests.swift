import XCTest
@testable import GymBuddyCore

final class BackupRotationTests: XCTestCase {
    let calendar = Calendar.current
    lazy var noon = calendar.date(bySettingHour: 12, minute: 0, second: 0, of: Date(timeIntervalSince1970: 1_790_000_000))!

    func testNamesRoundTripToTheMillisecond() {
        let t = noon.addingTimeInterval(0.123)
        let name = BackupRotation.localName(at: t)
        XCTAssertEqual(BackupRotation.date(fromLocalName: name)!.timeIntervalSince1970, t.timeIntervalSince1970, accuracy: 0.001)
        XCTAssertNotEqual(name, BackupRotation.localName(at: t.addingTimeInterval(0.01)))
        XCTAssertEqual(BackupRotation.cloudName(at: noon), BackupRotation.cloudName(at: noon.addingTimeInterval(3600)))
    }

    func testKeepsTheNewestTwentyOfADay() {
        let names = (0..<25).map { BackupRotation.localName(at: noon.addingTimeInterval(Double($0) * 60)) }
        let expired = BackupRotation.localExpired(names, now: noon.addingTimeInterval(3600))
        XCTAssertEqual(expired, Array(names.prefix(5)).sorted())
    }

    func testKeepsSevenDaysIncludingToday() {
        let names = (0..<10).map { day in
            BackupRotation.localName(at: calendar.date(byAdding: .day, value: -day, to: noon)!)
        }
        let expired = Set(BackupRotation.localExpired(names, now: noon))
        XCTAssertEqual(expired, Set(names.suffix(3)))
    }

    func testNeverTouchesFilesItDidNotWrite() {
        let names = ["notes.txt", "GymBuddy-latest.sqlite", "GymBuddy-2020-01-01.sqlite"]
        XCTAssertTrue(BackupRotation.localExpired(names, now: noon).isEmpty)
    }

    func testCloudKeepsThirtyDays() {
        let names = (0..<35).map { day in
            BackupRotation.cloudName(at: calendar.date(byAdding: .day, value: -day, to: noon)!)
        }
        XCTAssertEqual(BackupRotation.cloudExpired(names, now: noon).count, 5)
    }

    func testAddingASettingDoesNotResetSavedOnes() throws {
        let old = #"{"unit":"kilograms","restBetweenSets":90}"#
        let settings = try JSONDecoder().decode(Settings.self, from: Data(old.utf8))
        XCTAssertEqual(settings.unit, .kilograms)
        XCTAssertEqual(settings.restBetweenSets, 90)
        XCTAssertFalse(settings.iCloudBackup)
    }
}
