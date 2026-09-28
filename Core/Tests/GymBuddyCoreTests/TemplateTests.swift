import XCTest
@testable import GymBuddyCore

final class TemplateTests: XCTestCase {
    let catalogue = SeedLibrary.byID

    func testEveryLinePointsAtARealExercise() {
        for t in TemplateLibrary.all {
            for line in t.lines {
                XCTAssertNotNil(catalogue[line.exerciseID], "\(t.name): \(line.exerciseID)")
            }
        }
        XCTAssertEqual(Set(TemplateLibrary.all.map(\.id)).count, TemplateLibrary.all.count)
    }

    /// A load one `+` can't reach would be the first number the user fixes.
    func testLoadsSitOnTheEquipmentGrid() throws {
        for t in TemplateLibrary.all {
            for line in t.lines {
                let equipment = try XCTUnwrap(catalogue[line.exerciseID]).equipment
                let step = equipment.increment(in: .kilograms).kilograms
                if step == 0 {
                    XCTAssertEqual(line.kilograms, 0, "\(t.name): \(line.exerciseID)")
                } else {
                    let steps = line.kilograms / step
                    XCTAssertEqual(steps, steps.rounded(), accuracy: 0.0001, "\(t.name): \(line.exerciseID)")
                }
            }
        }
    }

    func testCountsMakeSenseForWhatTheyCount() throws {
        for t in TemplateLibrary.all {
            for line in t.lines {
                let exercise = try XCTUnwrap(catalogue[line.exerciseID])
                let measure = line.measure ?? exercise.measure
                XCTAssertTrue(Measure.options(for: exercise.equipment).contains(measure), "\(t.name): \(exercise.name)")
                XCTAssertGreaterThan(line.sets, 0)
                XCTAssertGreaterThan(line.count, 0)
                if measure == .seconds { XCTAssertEqual(line.count % measure.step, 0, exercise.name) }
            }
        }
    }

    func testTimeBoxedTemplatesFitTheirSlot() {
        for t in TemplateLibrary.all {
            guard let limit = t.fitsIn else { continue }
            let minutes = Stats.plannedMinutes(t.workout(), defaultRest: 60, exercises: catalogue)
            XCTAssertLessThanOrEqual(minutes, limit, t.name)
        }
    }

    func testEveryCategoryHasATemplate() {
        for c in TemplateCategory.allCases {
            XCTAssertFalse(TemplateLibrary.templates(in: c).isEmpty, c.rawValue)
        }
    }

    func testWorkoutGetsFreshLinesAndOnePoolForEverySwim() throws {
        let t = try XCTUnwrap(TemplateLibrary.all.first { $0.id == "swim-freestyle" })
        XCTAssertTrue(t.usesPool)
        let w = t.workout(pool: .m50)
        XCTAssertEqual(Set(w.exercises.map(\.id)).count, w.exercises.count)
        XCTAssertTrue(w.exercises.allSatisfy { $0.poolLength == .m50 })
        XCTAssertNotEqual(t.workout().exercises[0].id, w.exercises[0].id)
    }

    func testDryLinesGetNoPoolAndTreadmillsGetAnIncline() throws {
        let t = try XCTUnwrap(TemplateLibrary.all.first { $0.id == "light-gym-30" })
        XCTAssertFalse(t.usesPool)
        let w = t.workout()
        XCTAssertTrue(w.exercises.allSatisfy { $0.poolLength == nil })
        XCTAssertEqual(w.exercises[0].targetIncline, 3)
        XCTAssertNil(w.exercises[1].targetIncline)
        XCTAssertEqual(w.exercises[1].targetWeight, Weight(kilograms: 60))
    }

    /// Nothing done lying face-up past the first trimester.
    func testPregnancyTemplatesAvoidLyingOnYourBack() {
        let supine: Set = ["glute-bridges", "dead-bugs", "crunches", "barbell-bench-press", "dumbbell-bench-press", "backstroke-swim"]
        for t in TemplateLibrary.templates(in: .pregnancy) {
            XCTAssertTrue(t.lines.allSatisfy { !supine.contains($0.exerciseID) }, t.name)
        }
    }
}
