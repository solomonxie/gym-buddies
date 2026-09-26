import XCTest
@testable import GymBuddyCore

final class WeightTests: XCTestCase {
    func testRoundTripsThroughBothUnits() {
        let w = Weight(pounds: 50)
        XCTAssertEqual(w.pounds, 50, accuracy: 0.000_001)
        XCTAssertEqual(Weight(kilograms: w.kilograms).pounds, 50, accuracy: 0.000_001)
    }

    func testFormatsLikeAPlateIsLabelled() {
        XCTAssertEqual(Weight(pounds: 50).formatted(in: .pounds), "50.0 lb")
        XCTAssertEqual(Weight(kilograms: 22.5).formatted(in: .kilograms), "22.5 kg")
    }

    func testVolumeMultipliesByReps() {
        XCTAssertEqual((Weight(kilograms: 20) * 10).kilograms, 200, accuracy: 0.000_001)
    }
}

final class EquipmentTests: XCTestCase {
    func testEachEquipmentStepsByWhatItPhysicallyAllows() {
        XCTAssertEqual(Equipment.barbell.increment(in: .kilograms).kilograms, 2.5)
        XCTAssertEqual(Equipment.machine.increment(in: .kilograms).kilograms, 5)
        XCTAssertEqual(Equipment.machine.increment(in: .pounds).pounds, 10, accuracy: 0.000_001)
        XCTAssertEqual(Equipment.dumbbell.increment(in: .pounds).pounds, 5, accuracy: 0.000_001)
    }

    func testUnloadableEquipmentHasNoIncrement() {
        XCTAssertFalse(Equipment.band.isLoadable)
        XCTAssertEqual(Equipment.band.increment(in: .kilograms).kilograms, 0)
        let held = Equipment.band.stepped(Weight(kilograms: 10), by: 3, in: .kilograms)
        XCTAssertEqual(held.kilograms, 10)
    }

    func testSteppingNeverGoesNegative() {
        let w = Equipment.machine.stepped(Weight(kilograms: 5), by: -4, in: .kilograms)
        XCTAssertEqual(w.kilograms, 0)
    }

    func testSteppingInPoundsMovesByPoundIncrements() {
        let start = Weight(pounds: 50)
        let up = Equipment.machine.stepped(start, by: 1, in: .pounds)
        XCTAssertEqual(up.pounds, 60, accuracy: 0.000_001)
    }
}
