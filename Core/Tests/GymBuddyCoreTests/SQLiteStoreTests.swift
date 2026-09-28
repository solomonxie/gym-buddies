import XCTest
@testable import GymBuddyCore

final class SQLiteStoreTests: XCTestCase {
    var dir: URL!

    override func setUpWithError() throws {
        dir = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        try FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
    }

    override func tearDownWithError() throws {
        try? FileManager.default.removeItem(at: dir)
    }

    func store(_ name: String = "db.sqlite") throws -> SQLiteStore {
        try SQLiteStore(url: dir.appendingPathComponent(name), catalogue: Array(Fixtures.catalogue.values))
    }

    func testSeedsTheCatalogueAndKeepsFavouritesAcrossReopen() throws {
        var s = try store()
        XCTAssertEqual(try s.exercises().count, 3)
        var rows = try XCTUnwrap(try s.exercises().first { $0.id == Fixtures.rows.id })
        rows.isFavourite = true
        try s.saveExercise(rows)

        s = try store()
        XCTAssertTrue(try s.exercises().first { $0.id == Fixtures.rows.id }!.isFavourite)
        XCTAssertEqual(try s.exercises().count, 3)
    }

    func testWorkoutRoundTripsWithLineOrderAndRest() throws {
        let s = try store()
        try s.saveWorkout(Fixtures.workout)
        let loaded = try XCTUnwrap(try s.workouts().first)
        XCTAssertEqual(loaded.exercises.map(\.id), ["p-walking", "p-rows", "p-pulldowns"])
        XCTAssertEqual(loaded.exercises[2].restSeconds, 90)
        XCTAssertEqual(loaded.exercises[1].targetWeight, Weight(pounds: 50))

        var reordered = loaded
        reordered.exercises.swapAt(0, 2)
        try s.saveWorkout(reordered)
        XCTAssertEqual(try s.workouts().first?.exercises.first?.id, "p-pulldowns")
    }

    func testDeletingAWorkoutKeepsItsLogs() throws {
        let s = try store()
        try s.saveWorkout(Fixtures.workout)
        var session = Fixtures.session()
        session.completeSet(at: Fixtures.t0 + 10)
        try s.saveLog(session.finish(at: Fixtures.t0 + 100, logID: "log"))
        try s.deleteWorkout(id: Fixtures.workout.id)
        XCTAssertEqual(try s.workouts().count, 0)
        XCTAssertEqual(try s.logs().first?.sets.count, 1)
    }

    func testLogRoundTripsSkipsNotesAndTargets() throws {
        let s = try store()
        var session = Fixtures.session()
        session.skipExercise()
        session.adjustReps(by: -2)
        session.completeSet(at: Fixtures.t0 + 10)
        session.notes = "Shoulder tight"
        try s.saveLog(session.finish(at: Fixtures.t0 + 100, logID: "log"))

        let log = try XCTUnwrap(try s.logs().first)
        XCTAssertEqual(log.notes, "Shoulder tight")
        XCTAssertEqual(log.skippedExerciseIDs, [Fixtures.walking.id, Fixtures.pullDowns.id])
        XCTAssertEqual(log.sets.first?.targetReps, 10)
        XCTAssertTrue(log.sets.first!.isUnderTarget)
        XCTAssertEqual(log.sets.first?.planLineID, "p-rows")
    }

    func testActiveSessionSurvivesAKilledApp() throws {
        var s = try store()
        var session = Fixtures.session()
        session.skipExercise()
        session.completeSet(at: Fixtures.t0 + 10)
        try s.saveActiveSession(session)

        s = try store()
        let resumed = try XCTUnwrap(try s.activeSession())
        XCTAssertEqual(resumed.currentEntry?.id, "p-rows")
        XCTAssertEqual(resumed.currentSetNumber, 2)
        XCTAssertEqual(resumed.logs.count, 1)

        try s.saveActiveSession(nil)
        XCTAssertNil(try s.activeSession())
    }

    func testSettingsPersist() throws {
        var s = try store()
        XCTAssertNil(try s.settings())
        var settings = Settings()
        settings.unit = .kilograms
        settings.restBetweenSets = 90
        try s.saveSettings(settings)
        s = try store()
        XCTAssertEqual(try s.settings(), settings)
    }

    func testBackupThenReplaceRestoresEverything() throws {
        let s = try store()
        try s.saveWorkout(Fixtures.workout)
        try s.saveLog(Fixtures.session().finish(at: Fixtures.t0 + 60, logID: "a"))
        let backup = dir.appendingPathComponent("backup.sqlite")
        try s.backup(to: backup)
        XCTAssertEqual(try SQLiteStore.inspect(backup), BackupSummary(sessions: 1, workouts: 1))

        try s.deleteWorkout(id: Fixtures.workout.id)
        try s.deleteLog(id: "a")
        try s.replace(with: backup)
        XCTAssertEqual(try s.workouts().count, 1)
        XCTAssertEqual(try s.logs().count, 1)
    }

    func testANonBackupFileIsRefusedBeforeAnythingIsReplaced() throws {
        let s = try store()
        try s.saveWorkout(Fixtures.workout)
        let junk = dir.appendingPathComponent("junk.sqlite")
        try Data("not a database".utf8).write(to: junk)
        XCTAssertThrowsError(try s.replace(with: junk))
        XCTAssertEqual(try s.workouts().count, 1)
    }

    func testResetHistoryRemovesOnlyThatExercisesSets() throws {
        let s = try store()
        var session = Fixtures.session()
        session.completeSet(at: Fixtures.t0)
        session.completeSet(at: Fixtures.t0 + 60)
        try s.saveLog(session.finish(at: Fixtures.t0 + 100, logID: "a"))
        try s.deleteSets(exerciseID: Fixtures.walking.id)
        XCTAssertEqual(try s.logs().first?.sets.map(\.exerciseID), [Fixtures.rows.id])
    }
}

final class GymStoreTests: XCTestCase {
    func testHomeIsSeededAndCannotBeDeleted() throws {
        let url = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString + ".sqlite")
        defer { try? FileManager.default.removeItem(at: url) }
        var s = try SQLiteStore(url: url, catalogue: Array(Fixtures.catalogue.values))
        XCTAssertEqual(try s.gyms().map(\.id), [Gym.homeID])
        try s.deleteGym(id: Gym.homeID)
        XCTAssertEqual(try s.gyms().map(\.id), [Gym.homeID])

        let gym = Gym(id: "g", name: "Anytime", equipment: [.barbell, .pool],
                      price: Price(cents: 4500, period: .month),
                      hours: .daily(open: 6 * 60, close: 22 * 60), travelMinutes: 15, notes: "Bring a lock")
        try s.saveGym(gym)
        var w = Fixtures.workout
        w.gymIDs = ["home", "g"]
        w.exercises[0].poolLength = .yd25
        try s.saveWorkout(w)

        s = try SQLiteStore(url: url, catalogue: Array(Fixtures.catalogue.values))
        XCTAssertEqual(try s.gyms(), [.home, gym])
        let loaded = try XCTUnwrap(try s.workouts().first)
        XCTAssertEqual(loaded.gymIDs, ["home", "g"])
        XCTAssertEqual(loaded.exercises[0].poolLength, .yd25)

        try s.deleteGym(id: "g")
        XCTAssertEqual(try s.gyms().map(\.id), [Gym.homeID])
    }

    func testSetsKeepTheirPool() throws {
        let url = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString + ".sqlite")
        defer { try? FileManager.default.removeItem(at: url) }
        let s = try SQLiteStore(url: url, catalogue: [])
        let set = SetLog(id: "x", sessionID: "l", exerciseID: "freestyle-swim", setNumber: 1, reps: 4,
                         weight: .zero, completedAt: Fixtures.t0, measure: .laps, poolLength: .m50)
        try s.saveLog(WorkoutLog(id: "l", workoutID: "w", workoutName: "Swim",
                                 startedAt: Fixtures.t0, finishedAt: Fixtures.t0, sets: [set]))
        XCTAssertEqual(try s.logs().first?.sets.first?.poolLength, .m50)
    }

    func testOldSessionsWithoutGymsStillDecode() throws {
        let json = #"{"id":"w","name":"Old","exercises":[]}"#
        let w = try JSONDecoder().decode(Workout.self, from: Data(json.utf8))
        XCTAssertEqual(w.gymIDs, [])
    }
}
