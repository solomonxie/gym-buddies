import Foundation
import GymBuddyCore
import Observation
import UIKit

/// One place the screens read from and send events to. Holds no rules of its
/// own: every number comes from `GymBuddyCore`.
@MainActor
@Observable
final class AppModel {
    private(set) var store: Store = MemoryStore()
    /// Set when the database couldn't be opened — the app shows one screen
    /// offering a restore, never a silent empty list.
    private(set) var loadError: String?
    /// Demo mode: a separate, seeded database. The real one is left alone.
    private(set) var isDemo = false

    private(set) var exercises: [Exercise] = []
    private(set) var workouts: [Workout] = []
    private(set) var logs: [WorkoutLog] = []
    private(set) var gyms: [Gym] = []
    private(set) var exercisesByID: [String: Exercise] = [:]

    var settings = Settings() {
        didSet {
            guard settings != oldValue else { return }
            try? store.saveSettings(settings)
            applyScreenAwake()
            if settings.withoutBackupStamps != oldValue.withoutBackupStamps { backupSoon() }
        }
    }

    /// Nil in demo mode — demo data is never backed up over the real backups.
    private var autoBackup: AutoBackup?
    private(set) var iCloudUnavailable = false

    /// The one navigation stack; Train is its root.
    var path: [Route] = []
    /// Present while a workout is being performed; persisted on every change
    /// so a killed app resumes where it was.
    private(set) var session: WorkoutSession? {
        didSet {
            try? store.saveActiveSession(session)
            applyScreenAwake()
        }
    }
    var isSessionPresented = false
    private(set) var restTimer = RestTimer()
    /// Set when the last set is logged; the summary sheet reads it.
    var pendingSummary: WorkoutSession?

    var unit: WeightUnit { settings.unit }

    static let demoKey = "demoMode"
    /// Off for DEBUG screenshot launches, so no permission alert covers the screen.
    var asksForNotifications = true

    /// A given `store` (tests, `-empty`) counts as demo: no backups, no export.
    init(store: Store? = nil, demo: Bool? = nil, resetDemo: Bool = false) {
        if let store {
            asksForNotifications = false
            use(store, demo: true)
        } else {
            open(demo: demo ?? UserDefaults.standard.bool(forKey: Self.demoKey), reset: resetDemo)
        }
    }

    static var databaseURL: URL {
        try? FileManager.default.createDirectory(at: .applicationSupportDirectory, withIntermediateDirectories: true)
        return URL.applicationSupportDirectory.appending(path: "GymBuddy.sqlite")
    }

    /// `make <target> STORE=cn` → Info.plist `AppStoreRegion`.
    static var storeRegion: String {
        Bundle.main.object(forInfoDictionaryKey: "AppStoreRegion") as? String ?? "us"
    }

    func setDemoMode(_ on: Bool) {
        guard on != isDemo else { return }
        UserDefaults.standard.set(on, forKey: Self.demoKey)
        open(demo: on, reset: false)
    }

    func resetDemoData() {
        guard isDemo else { return }
        open(demo: true, reset: true)
    }

    private func open(demo: Bool, reset: Bool) {
        dismissRest()
        store = MemoryStore()
        do {
            use(try demo ? Self.openDemoStore(reset: reset) : SQLiteStore(url: Self.databaseURL), demo: demo)
            loadError = nil
        } catch {
            use(MemoryStore(exercises: SeedLibrary.exercises), demo: demo)
            loadError = String(describing: error)
        }
    }

    private static func openDemoStore(reset: Bool) throws -> Store {
        guard let url = Bundle.main.url(forResource: "seed", withExtension: "json", subdirectory: "demo") else {
            throw StoreError(description: "Demo data is missing from the app.")
        }
        var seed = try DemoSeed.load(url)
        if storeRegion == "cn" { seed.unit = .kilograms }
        try FileManager.default.createDirectory(at: .applicationSupportDirectory, withIntermediateDirectories: true)
        return try DemoStore.open(in: .applicationSupportDirectory, seed: seed, reset: reset)
    }

    private func use(_ newStore: Store, demo: Bool) {
        store = newStore
        isDemo = demo
        autoBackup = demo ? nil : (newStore as? SQLiteStore).map { AutoBackup(store: $0) }
        pendingSummary = nil
        isSessionPresented = false
        if let saved = try? newStore.settings() {
            settings = saved
        } else {
            settings = Settings()
            settings.unit = Locale.current.measurementSystem == .us ? .pounds : .kilograms
        }
        session = try? newStore.activeSession()
        refresh()
    }

    /// Re-reads the store after a change, then schedules a backup of it.
    func reload() {
        refresh()
        backupSoon()
    }

    func backupSoon() {
        autoBackup?.changed(iCloud: settings.iCloudBackup) { [weak self] outcome in
            guard let self else { return }
            switch outcome {
            case .local(let date): settings.lastAutoBackup = date
            case .cloud(let date):
                settings.lastICloudBackup = date
                iCloudUnavailable = false
            case .cloudUnavailable: iCloudUnavailable = true
            }
        }
    }

    private func refresh() {
        exercises = (try? store.exercises()) ?? []
        workouts = (try? store.workouts()) ?? []
        logs = (try? store.logs()) ?? []
        gyms = (try? store.gyms()) ?? [.home]
        exercisesByID = Dictionary(uniqueKeysWithValues: exercises.map { ($0.id, $0) })
    }

    // MARK: - Exercises

    func toggleFavourite(_ exercise: Exercise) {
        guard var current = exercisesByID[exercise.id] else { return }
        current.isFavourite.toggle()
        try? store.saveExercise(current)
        reload()
    }

    func saveExercise(_ exercise: Exercise) {
        try? store.saveExercise(exercise)
        reload()
    }

    func deleteCustomExercise(_ exercise: Exercise) {
        try? store.deleteExercise(id: exercise.id)
        for var workout in workouts where workout.exercises.contains(where: { $0.exerciseID == exercise.id }) {
            workout.exercises.removeAll { $0.exerciseID == exercise.id }
            try? store.saveWorkout(workout)
        }
        reload()
    }

    func resetHistory(of exercise: Exercise) {
        try? store.deleteSets(exerciseID: exercise.id)
        reload()
    }

    // MARK: - Workouts

    func workout(id: String) -> Workout? {
        workouts.first { $0.id == id }
    }

    func saveWorkout(_ workout: Workout) {
        try? store.saveWorkout(workout)
        reload()
    }

    @discardableResult
    func createWorkout(named name: String) -> Workout {
        let workout = Workout(id: UUID().uuidString, name: name)
        saveWorkout(workout)
        return workout
    }

    @discardableResult
    func createWorkout(from template: WorkoutTemplate, pool: PoolLength) -> Workout {
        let workout = template.workout(pool: pool, catalogue: exercisesByID)
        saveWorkout(workout)
        return workout
    }

    func deleteWorkout(_ workout: Workout) {
        try? store.deleteWorkout(id: workout.id)
        reload()
    }

    func duplicate(_ workout: Workout) {
        var copy = workout
        copy.id = UUID().uuidString
        copy.name = workout.name + " copy"
        copy.lastPerformed = nil
        copy.exercises = workout.exercises.map {
            var line = $0
            line.id = UUID().uuidString
            return line
        }
        saveWorkout(copy)
    }

    /// New lines take the default sets/reps and the weight you last lifted.
    func add(_ exerciseIDs: [String], to workoutID: String) {
        guard var workout = workout(id: workoutID) else { return }
        for id in exerciseIDs {
            let last = Stats.lastSession(exerciseID: id, in: logs)?.sets.last { $0.exerciseID == id }
            let exercise = exercisesByID[id]
            let measure = exercise?.measure ?? .reps
            workout.exercises.append(WorkoutExercise(
                id: UUID().uuidString,
                exerciseID: id,
                // One long bout for cardio; the usual sets for everything else.
                targetSets: measure == .minutes ? 1 : settings.defaultSets,
                targetReps: last?.reps ?? (measure == .reps ? settings.defaultReps : measure.defaultTarget),
                targetWeight: last?.weight ?? .zero,
                targetIncline: exercise?.equipment.inclineStep == nil ? nil : (last?.incline ?? 0)
            ))
        }
        saveWorkout(workout)
    }

    // MARK: - Gyms

    func gym(id: String) -> Gym? {
        gyms.first { $0.id == id }
    }

    func saveGym(_ gym: Gym) {
        try? store.saveGym(gym)
        reload()
    }

    @discardableResult
    func createGym() -> Gym {
        let gym = Gym(id: UUID().uuidString, name: "New gym", hours: .daily(open: 6 * 60, close: 22 * 60))
        saveGym(gym)
        return gym
    }

    /// Workouts that pointed at it stop pointing; Home is never deleted.
    func deleteGym(_ gym: Gym) {
        guard !gym.isHome else { return }
        for var workout in workouts where workout.gymIDs.contains(gym.id) {
            workout.gymIDs.removeAll { $0 == gym.id }
            try? store.saveWorkout(workout)
        }
        try? store.deleteGym(id: gym.id)
        reload()
    }

    func workouts(at gymID: String) -> [Workout] {
        workouts.filter { $0.gymIDs.contains(gymID) }
    }

    func toggle(gymID: String, for workoutID: String) {
        guard var workout = workout(id: workoutID) else { return }
        if workout.gymIDs.contains(gymID) {
            workout.gymIDs.removeAll { $0 == gymID }
        } else {
            workout.gymIDs.append(gymID)
        }
        saveWorkout(workout)
    }

    func sessionCount(for workoutID: String) -> Int {
        logs.filter { $0.workoutID == workoutID }.count
    }

    // MARK: - Session

    func start(_ workout: Workout, at now: Date = .now) {
        guard session == nil else {
            isSessionPresented = true
            return
        }
        session = WorkoutSession(
            workout: workout,
            exercises: exercisesByID,
            startedAt: now,
            defaultRestSeconds: settings.restBetweenSets,
            restBetweenExercisesSeconds: settings.restBetweenExercises
        )
        restTimer.dismiss()
        isSessionPresented = true
        if settings.alertWhenRestOver && asksForNotifications { RestAlerts.requestAuthorization() }
    }

    func resume() {
        isSessionPresented = session != nil
    }

    /// Every change to the session goes through here so it is persisted.
    func updateSession(_ change: (inout WorkoutSession) -> Void) {
        guard var current = session else { return }
        let wasTiming = current.isSetRunning
        change(&current)
        session = current
        if current.isSetRunning { scheduleSetAlert() }
        else if wasTiming { RestAlerts.cancel() }
    }

    /// Start ends any rest: the next set is underway.
    func startSet(at now: Date = .now) {
        dismissRest()
        updateSession { $0.startSet(at: now) }
        if settings.vibrate { UIImpactFeedbackGenerator(style: .light).impactOccurred() }
    }

    func cancelSet() {
        updateSession { $0.cancelSet() }
    }

    /// A treadmill in the cup holder still needs to say when the time is up.
    private func scheduleSetAlert(at now: Date = .now) {
        guard settings.alertWhenRestOver, let current = session, let entry = current.currentEntry,
              let remaining = current.setRemaining(at: now) else { return }
        RestAlerts.schedule(after: remaining, body: "Time's up · \(entry.exercise.name) \(current.currentSetNumber) of \(entry.plan.targetSets)")
    }

    /// Logs the set, then starts the rest the outcome asked for — the timer is
    /// never started by a screen directly, so it can't drift from the session.
    func completeSets(_ count: Int = 1, at now: Date = .now) {
        guard var current = session, let entry = current.currentEntry else { return }
        let setNumber = current.currentSetNumber + count - 1
        let restEndedAt = restTimer.hasFired(at: now) ? restTimer.endsAt : nil
        let outcome = current.completeSets(count, at: now, restEndedAt: restEndedAt)
        session = current
        backupSoon()
        if settings.vibrate { UIImpactFeedbackGenerator(style: .medium).impactOccurred() }

        switch outcome {
        case .restThenNextSet(let seconds):
            startRest(seconds, at: now, label: "\(entry.exercise.name) \(setNumber + 1) of \(entry.plan.targetSets)")
        case .restThenNextExercise(let name, let seconds):
            let next = current.currentEntry
            startRest(seconds, at: now, label: "\(name) 1 of \(next?.plan.targetSets ?? 1)")
        case .workoutComplete:
            dismissRest()
            pendingSummary = current
        }
    }

    private func startRest(_ seconds: Int, at now: Date, label: String) {
        guard seconds > 0 else {
            dismissRest()
            return
        }
        restTimer.start(TimeInterval(seconds), at: now)
        restLabel = label
        scheduleRestAlert(at: now)
    }

    private var restLabel = ""

    private func scheduleRestAlert(at now: Date) {
        guard settings.alertWhenRestOver else { return }
        RestAlerts.schedule(after: restTimer.remaining(at: now), body: "Rest over · \(restLabel)")
    }

    func extendRest(at now: Date = .now) {
        restTimer.extend(by: 30)
        scheduleRestAlert(at: now)
    }

    func dismissRest() {
        restTimer.dismiss()
        RestAlerts.cancel()
    }

    func skipExercise() {
        updateSession { $0.skipExercise() }
        dismissRest()
        if session?.isFinished == true { pendingSummary = session }
    }

    func goBack() {
        updateSession { $0.goBack() }
        dismissRest()
    }

    func changeTargetSets(to count: Int) {
        updateSession { $0.changeTargetSets(to: count) }
        if session?.isFinished == true { pendingSummary = session }
    }

    /// Save the log; optionally push today's weights into the plan.
    func saveSession(updatingPlan: Bool, at now: Date = .now) {
        guard let current = session else { return }
        let log = current.finish(at: now)
        if !log.sets.isEmpty { try? store.saveLog(log) }
        if var workout = workout(id: current.workoutID) {
            if updatingPlan {
                workout = WorkoutSession.applying(current.weightDrift, incline: current.inclineDrift, to: workout)
            }
            if !log.sets.isEmpty { workout.lastPerformed = current.startedAt }
            try? store.saveWorkout(workout)
        }
        endSession()
    }

    func discardSession() {
        endSession()
    }

    private func endSession() {
        dismissRest()
        pendingSummary = nil
        isSessionPresented = false
        session = nil
        reload()
    }

    private func applyScreenAwake() {
        UIApplication.shared.isIdleTimerDisabled = session != nil && settings.keepScreenAwake
    }

    // MARK: - Logs

    func deleteLog(_ log: WorkoutLog) {
        try? store.deleteLog(id: log.id)
        reload()
    }

    func saveLog(_ log: WorkoutLog) {
        try? store.saveLog(log)
        reload()
    }

    // MARK: - Backup

    var sqliteStore: SQLiteStore? { isDemo ? nil : store as? SQLiteStore }

    func exportBackup() throws -> URL {
        guard let sqlite = sqliteStore else { throw StoreError(description: "Demo data has no file to export.") }
        let stamp = Date.now.formatted(.iso8601.year().month().day())
        let url = FileManager.default.temporaryDirectory.appending(path: "GymBuddy-\(stamp).sqlite")
        try sqlite.backup(to: url)
        let size = (try? FileManager.default.attributesOfItem(atPath: url.path)[.size] as? Int) ?? 0
        settings.lastBackup = .now
        settings.lastBackupBytes = size
        return url
    }

    func importBackup(from url: URL) throws {
        guard let sqlite = sqliteStore else { throw StoreError(description: "Demo data can't be replaced.") }
        let keep = settings
        // Set the chosen file aside first: the safety backup below may rotate
        // out the oldest local snapshot, which could be this one.
        let chosen = FileManager.default.temporaryDirectory.appending(path: "restore-\(UUID().uuidString).sqlite")
        try FileManager.default.copyItem(at: url, to: chosen)
        defer { try? FileManager.default.removeItem(at: chosen) }
        // A restore is undoable: what's here now becomes the newest local backup.
        _ = AutoBackup.write(store: sqlite, iCloud: false, now: .now)
        try sqlite.replace(with: chosen)
        var restored = (try? sqlite.settings()) ?? keep
        // Backup preferences belong to this phone, not to the file.
        restored.iCloudBackup = keep.iCloudBackup
        settings = restored
        session = try? sqlite.activeSession()
        reload()
    }
}

private extension Settings {
    /// Settings minus the timestamps the backup itself writes, so recording
    /// a backup doesn't count as a change that needs one.
    var withoutBackupStamps: Settings {
        var copy = self
        copy.lastAutoBackup = nil
        copy.lastICloudBackup = nil
        copy.lastBackup = nil
        copy.lastBackupBytes = nil
        return copy
    }
}
