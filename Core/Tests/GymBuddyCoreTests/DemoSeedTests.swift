import XCTest
@testable import GymBuddyCore

final class DemoSeedTests: XCTestCase {
    var dir: URL!
    let now = Date(timeIntervalSince1970: 1_790_000_000)

    static let seedURL = URL(fileURLWithPath: #filePath)
        .deletingLastPathComponent().deletingLastPathComponent().deletingLastPathComponent()
        .deletingLastPathComponent().appending(path: "demo/seed.json")

    override func setUpWithError() throws {
        dir = FileManager.default.temporaryDirectory.appending(path: UUID().uuidString)
        try FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
    }

    override func tearDownWithError() throws {
        try? FileManager.default.removeItem(at: dir)
    }

    func seed() throws -> DemoSeed { try DemoSeed.load(Self.seedURL) }

    func testSeedOnlyNamesRealExercisesAndKit() throws {
        let seed = try seed()
        let ids = Set(SeedLibrary.exercises.map(\.id))
        let kit = Set(Kit.catalogue(for: SeedLibrary.exercises).map(\.id))
        for line in seed.workouts.flatMap(\.lines) { XCTAssertTrue(ids.contains(line.exercise), line.exercise) }
        for id in seed.favourites { XCTAssertTrue(ids.contains(id), id) }
        for gym in seed.gyms {
            if case .some(let list) = gym.kit { for id in list { XCTAssertTrue(kit.contains(id), id) } }
        }
        let gymIDs = Set(seed.gyms.map(\.id))
        for id in seed.workouts.flatMap(\.gyms) { XCTAssertTrue(gymIDs.contains(id), id) }
    }

    func testDemoStoreIsSeparateFromTheRealDatabase() throws {
        let real = try SQLiteStore(url: dir.appending(path: "GymBuddy.sqlite"))
        try real.saveWorkout(Workout(id: "mine", name: "Mine"))

        let demo = try DemoStore.open(in: dir, seed: seed(), now: now)
        XCTAssertNotEqual(demo.url, real.url)
        XCTAssertEqual(try real.workouts().map(\.id), ["mine"])
        XCTAssertTrue(try real.logs().isEmpty)
        XCTAssertFalse(try demo.workouts().contains { $0.id == "mine" })
    }

    func testSeedFillsEveryScreen() throws {
        let demo = try DemoStore.open(in: dir, seed: seed(), now: now)
        let logs = try demo.logs()
        XCTAssertGreaterThan(logs.count, 25)
        XCTAssertTrue(logs.allSatisfy { $0.startedAt < now })
        XCTAssertGreaterThanOrEqual(try demo.workouts().count, 4)
        XCTAssertTrue(try demo.workouts().allSatisfy { $0.lastPerformed != nil })
        XCTAssertGreaterThanOrEqual(try demo.gyms().count, 3)
        XCTAssertFalse(try demo.exercises().filter(\.isFavourite).isEmpty)
        XCTAssertEqual(try demo.settings()?.unit, .pounds)
        let session = try XCTUnwrap(try demo.activeSession())
        XCTAssertTrue(session.hasLoggedAnything)
    }

    func testHistoryTrendsHeavier() throws {
        let demo = try DemoStore.open(in: dir, seed: seed(), now: now)
        let sets = try demo.logs().sorted { $0.startedAt < $1.startedAt }
            .flatMap(\.sets).filter { $0.exerciseID == "lat-pull-downs" }
        let first = try XCTUnwrap(sets.first), last = try XCTUnwrap(sets.last)
        XCTAssertLessThan(first.weight, last.weight)
    }

    func testReopenKeepsChangesAndResetReseeds() throws {
        var demo = try DemoStore.open(in: dir, seed: seed(), now: now)
        let count = try demo.logs().count
        try demo.deleteLog(id: XCTUnwrap(try demo.logs().first).id)

        demo = try DemoStore.open(in: dir, seed: seed(), now: now)
        XCTAssertEqual(try demo.logs().count, count - 1)

        demo = try DemoStore.open(in: dir, seed: seed(), reset: true, now: now)
        XCTAssertEqual(try demo.logs().count, count)
    }
}
