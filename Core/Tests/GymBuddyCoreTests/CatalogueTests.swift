import XCTest
@testable import GymBuddyCore

final class CatalogueTests: XCTestCase {
    let all = SeedLibrary.exercises

    func testIDsAreUniqueAndStable() {
        XCTAssertEqual(Set(all.map(\.id)).count, all.count)
        // Seed IDs are what saved workouts point at; renaming one orphans them.
        for id in ["barbell-curls", "lat-pull-downs", "seated-machine-rows", "planking", "walking", "burpees"] {
            XCTAssertNotNil(SeedLibrary.byID[id], id)
        }
    }

    func testEveryGroupIsCovered() {
        XCTAssertGreaterThanOrEqual(all.count, 280)
        for group in MuscleGroup.allCases {
            XCTAssertTrue(all.contains { $0.muscleGroup == group }, group.rawValue)
        }
    }

    /// Three steps or none — never a paragraph, never filler.
    func testHowToIsThreeStepsOrAbsent() {
        for e in all where e.instructions != nil {
            XCTAssertEqual(e.steps.count, 3, e.name)
        }
    }

    func testEveryMovementNamesTheMusclesItWorks() {
        for e in all {
            XCTAssertFalse(e.muscles.isEmpty, e.name)
            XCTAssertFalse(e.isCustom, e.name)
        }
    }
}
