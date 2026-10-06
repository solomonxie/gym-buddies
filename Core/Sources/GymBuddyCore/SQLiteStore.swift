import Foundation
import SQLite3

public struct StoreError: Error, CustomStringConvertible {
    public let description: String

    public init(description: String) {
        self.description = description
    }
}

/// What a backup file holds, for the "Replace everything?" confirm.
public struct BackupSummary: Equatable, Sendable {
    public let sessions: Int
    public let workouts: Int
}

/// One SQLite file on the phone. Numbered migrations, a table per model, and
/// the bundled catalogue re-applied on open without touching favourites or
/// anything the user made.
public final class SQLiteStore: Store, @unchecked Sendable {
    public let url: URL
    private let catalogue: [Exercise]
    private var db: OpaquePointer?
    private let lock = NSRecursiveLock()

    public init(url: URL, catalogue: [Exercise] = SeedLibrary.exercises) throws {
        self.url = url
        self.catalogue = catalogue
        try open()
    }

    deinit { sqlite3_close(db) }

    private func open() throws {
        guard sqlite3_open(url.path, &db) == SQLITE_OK else {
            throw StoreError(description: "Can't open \(url.lastPathComponent)")
        }
        try exec("PRAGMA foreign_keys = ON")
        try migrate()
        try seedCatalogue()
        try run("INSERT OR IGNORE INTO gyms (id, name, hours) VALUES (?, ?, ?)",
                [.text(Gym.home.id), .text(Gym.home.name), .text(try Self.json(Gym.home.hours))])
    }

    private static func json<T: Encodable>(_ value: T) throws -> String {
        String(decoding: try JSONEncoder().encode(value), as: UTF8.self)
    }

    // MARK: - Schema

    static let migrations: [String] = [
        """
        CREATE TABLE exercises (
            id TEXT PRIMARY KEY, name TEXT NOT NULL, muscle_group TEXT NOT NULL,
            equipment TEXT NOT NULL, muscles TEXT NOT NULL DEFAULT '',
            instructions TEXT, is_favourite INTEGER NOT NULL DEFAULT 0,
            is_custom INTEGER NOT NULL DEFAULT 0, is_timed INTEGER NOT NULL DEFAULT 0
        );
        CREATE TABLE workouts (
            id TEXT PRIMARY KEY, name TEXT NOT NULL, last_performed REAL
        );
        CREATE TABLE workout_lines (
            id TEXT PRIMARY KEY,
            workout_id TEXT NOT NULL REFERENCES workouts(id) ON DELETE CASCADE,
            position INTEGER NOT NULL, exercise_id TEXT NOT NULL,
            target_sets INTEGER NOT NULL, target_reps INTEGER NOT NULL,
            target_weight_kg REAL NOT NULL, rest_seconds INTEGER
        );
        CREATE TABLE logs (
            id TEXT PRIMARY KEY, workout_id TEXT NOT NULL, workout_name TEXT NOT NULL,
            started_at REAL NOT NULL, finished_at REAL NOT NULL,
            skipped TEXT NOT NULL DEFAULT '', notes TEXT NOT NULL DEFAULT ''
        );
        CREATE TABLE sets (
            id TEXT PRIMARY KEY,
            log_id TEXT NOT NULL REFERENCES logs(id) ON DELETE CASCADE,
            position INTEGER NOT NULL, exercise_id TEXT NOT NULL,
            set_number INTEGER NOT NULL, reps INTEGER NOT NULL,
            weight_kg REAL NOT NULL, completed_at REAL NOT NULL,
            plan_line_id TEXT, target_reps INTEGER
        );
        CREATE INDEX sets_exercise ON sets(exercise_id);
        CREATE TABLE meta (key TEXT PRIMARY KEY, value BLOB NOT NULL);
        """,
        // What the count means, and the treadmill's incline.
        """
        ALTER TABLE exercises ADD COLUMN measure TEXT NOT NULL DEFAULT 'reps';
        UPDATE exercises SET measure = 'seconds' WHERE is_timed = 1;
        ALTER TABLE workout_lines ADD COLUMN target_incline REAL;
        ALTER TABLE sets ADD COLUMN incline REAL;
        """,
        // Set timing, and a line counting differently from its exercise.
        """
        ALTER TABLE sets ADD COLUMN started_at REAL;
        ALTER TABLE sets ADD COLUMN measure TEXT;
        ALTER TABLE workout_lines ADD COLUMN measure TEXT;
        """,
        // Pools, gyms, and which gyms a workout is for.
        """
        ALTER TABLE workout_lines ADD COLUMN pool_length TEXT;
        ALTER TABLE sets ADD COLUMN pool_length TEXT;
        ALTER TABLE workouts ADD COLUMN gym_ids TEXT NOT NULL DEFAULT '';
        CREATE TABLE gyms (
            id TEXT PRIMARY KEY, name TEXT NOT NULL, equipment TEXT NOT NULL DEFAULT '',
            price_cents INTEGER, price_period TEXT, hours TEXT NOT NULL,
            travel_minutes INTEGER NOT NULL DEFAULT 0, notes TEXT NOT NULL DEFAULT ''
        );
        """,
        // A gym lists the exercises it has kit for, not kinds of kit.
        """
        ALTER TABLE gyms ADD COLUMN exercise_ids TEXT NOT NULL DEFAULT '';
        UPDATE gyms SET exercise_ids = COALESCE((
            SELECT group_concat(e.id, ',') FROM exercises e
            WHERE instr(',' || gyms.equipment || ',', ',' || e.equipment || ',') > 0
        ), '');
        """,
        // …and then the machines and equipment, not the exercises: see `convertGymsToKit`.
        """
        ALTER TABLE gyms ADD COLUMN kit TEXT NOT NULL DEFAULT '';
        """,
    ]

    private static let kitMigration = 6

    private func migrate() throws {
        try exec("CREATE TABLE IF NOT EXISTS migrations (version INTEGER PRIMARY KEY, applied_at REAL NOT NULL)")
        let applied = try query("SELECT COALESCE(MAX(version), 0) FROM migrations") { $0.int(0) }.first ?? 0
        for (index, sql) in Self.migrations.enumerated() where index + 1 > applied {
            try transaction {
                try exec(sql)
                try run("INSERT INTO migrations VALUES (?, ?)", [.int(index + 1), .double(Date().timeIntervalSince1970)])
                if index + 1 == Self.kitMigration { try convertGymsToKit() }
            }
        }
    }

    /// A gym that listed exercises gets the kit those exercises need.
    private func convertGymsToKit() throws {
        let exercises = Dictionary(uniqueKeysWithValues: try query("SELECT id, name, equipment FROM exercises") { row in
            (row.text(0), Exercise(id: row.text(0), name: row.text(1), muscleGroup: .fullBody,
                                   equipment: Equipment(rawValue: row.text(2)) ?? .none))
        })
        let gyms = try query("SELECT id, exercise_ids FROM gyms") { ($0.text(0), $0.text(1)) }
        for (id, exerciseIDs) in gyms {
            let kit = Set(exerciseIDs.split(separator: ",").compactMap { exercises[String($0)].flatMap(Kit.needed(by:))?.id })
            try run("UPDATE gyms SET kit = ? WHERE id = ?", [.text(kit.sorted().joined(separator: ",")), .text(id)])
        }
    }

    private func seedCatalogue() throws {
        try transaction {
            for exercise in catalogue {
                try run("""
                    INSERT INTO exercises (id, name, muscle_group, equipment, muscles, instructions, measure)
                    VALUES (?, ?, ?, ?, ?, ?, ?)
                    ON CONFLICT(id) DO UPDATE SET name = excluded.name,
                        muscle_group = excluded.muscle_group, equipment = excluded.equipment,
                        muscles = excluded.muscles, instructions = excluded.instructions,
                        measure = excluded.measure
                    WHERE is_custom = 0
                    """, [
                        .text(exercise.id), .text(exercise.name), .text(exercise.muscleGroup.rawValue),
                        .text(exercise.equipment.rawValue), .text(Self.join(exercise.muscles)),
                        .optionalText(exercise.instructions), .text(exercise.measure.rawValue),
                    ])
            }
        }
    }

    // MARK: - Exercises

    public func exercises() throws -> [Exercise] {
        try query("SELECT id, name, muscle_group, equipment, muscles, instructions, is_favourite, is_custom, measure FROM exercises ORDER BY name COLLATE NOCASE") { row in
            Exercise(
                id: row.text(0), name: row.text(1),
                muscleGroup: MuscleGroup(rawValue: row.text(2)) ?? .fullBody,
                equipment: Equipment(rawValue: row.text(3)) ?? .none,
                muscles: row.text(4).split(separator: ",").compactMap { Muscle(rawValue: String($0)) },
                instructions: row.optionalText(5),
                isFavourite: row.bool(6), isCustom: row.bool(7),
                measure: Measure(rawValue: row.text(8)) ?? .reps
            )
        }
    }

    public func saveExercise(_ e: Exercise) throws {
        try run("""
            INSERT OR REPLACE INTO exercises (id, name, muscle_group, equipment, muscles, instructions, is_favourite, is_custom, measure)
            VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?)
            """, [.text(e.id), .text(e.name), .text(e.muscleGroup.rawValue), .text(e.equipment.rawValue),
                  .text(Self.join(e.muscles)), .optionalText(e.instructions), .bool(e.isFavourite),
                  .bool(e.isCustom), .text(e.measure.rawValue)])
    }

    public func deleteExercise(id: String) throws {
        try run("DELETE FROM exercises WHERE id = ? AND is_custom = 1", [.text(id)])
    }

    // MARK: - Workouts

    public func workouts() throws -> [Workout] {
        let lines = try query("SELECT id, workout_id, exercise_id, target_sets, target_reps, target_weight_kg, rest_seconds, target_incline, measure, pool_length FROM workout_lines ORDER BY position") { row in
            (row.text(1), WorkoutExercise(
                id: row.text(0), exerciseID: row.text(2),
                targetSets: row.int(3), targetReps: row.int(4),
                targetWeight: Weight(kilograms: row.double(5)), restSeconds: row.optionalInt(6),
                targetIncline: row.optionalDouble(7),
                measure: row.optionalText(8).flatMap(Measure.init(rawValue:)),
                poolLength: row.optionalText(9).flatMap(PoolLength.init(rawValue:))
            ))
        }
        let byWorkout = Dictionary(grouping: lines, by: \.0).mapValues { $0.map(\.1) }
        return try query("SELECT id, name, last_performed, gym_ids FROM workouts ORDER BY name COLLATE NOCASE") { row in
            Workout(id: row.text(0), name: row.text(1),
                    exercises: byWorkout[row.text(0)] ?? [],
                    lastPerformed: row.optionalDouble(2).map(Date.init(timeIntervalSince1970:)),
                    gymIDs: row.text(3).split(separator: ",").map(String.init))
        }
    }

    public func saveWorkout(_ w: Workout) throws {
        try transaction {
            try run("INSERT OR REPLACE INTO workouts (id, name, last_performed, gym_ids) VALUES (?, ?, ?, ?)",
                    [.text(w.id), .text(w.name), .optionalDouble(w.lastPerformed?.timeIntervalSince1970),
                     .text(w.gymIDs.joined(separator: ","))])
            try run("DELETE FROM workout_lines WHERE workout_id = ?", [.text(w.id)])
            for (position, line) in w.exercises.enumerated() {
                try run("""
                    INSERT INTO workout_lines (id, workout_id, position, exercise_id, target_sets,
                        target_reps, target_weight_kg, rest_seconds, target_incline, measure, pool_length)
                    VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
                    """, [
                    .text(line.id), .text(w.id), .int(position), .text(line.exerciseID),
                    .int(line.targetSets), .int(line.targetReps), .double(line.targetWeight.kilograms),
                    .optionalInt(line.restSeconds), .optionalDouble(line.targetIncline),
                    .optionalText(line.measure?.rawValue), .optionalText(line.poolLength?.rawValue),
                ])
            }
        }
    }

    public func deleteWorkout(id: String) throws {
        try run("DELETE FROM workouts WHERE id = ?", [.text(id)])
    }

    // MARK: - Logs

    public func logs() throws -> [WorkoutLog] {
        let sets = try query("SELECT id, log_id, exercise_id, set_number, reps, weight_kg, completed_at, plan_line_id, target_reps, incline, started_at, measure, pool_length FROM sets ORDER BY position") { row in
            SetLog(id: row.text(0), sessionID: row.text(1), exerciseID: row.text(2),
                   setNumber: row.int(3), reps: row.int(4), weight: Weight(kilograms: row.double(5)),
                   completedAt: Date(timeIntervalSince1970: row.double(6)),
                   planLineID: row.optionalText(7), targetReps: row.optionalInt(8),
                   incline: row.optionalDouble(9),
                   startedAt: row.optionalDouble(10).map(Date.init(timeIntervalSince1970:)),
                   measure: row.optionalText(11).flatMap(Measure.init(rawValue:)),
                   poolLength: row.optionalText(12).flatMap(PoolLength.init(rawValue:)))
        }
        let byLog = Dictionary(grouping: sets, by: \.sessionID)
        return try query("SELECT id, workout_id, workout_name, started_at, finished_at, skipped, notes FROM logs ORDER BY started_at DESC") { row in
            WorkoutLog(id: row.text(0), workoutID: row.text(1), workoutName: row.text(2),
                       startedAt: Date(timeIntervalSince1970: row.double(3)),
                       finishedAt: Date(timeIntervalSince1970: row.double(4)),
                       sets: byLog[row.text(0)] ?? [],
                       skippedExerciseIDs: row.text(5).split(separator: ",").map(String.init),
                       notes: row.text(6))
        }
    }

    /// Sets are keyed to the log row, not to whatever session ID they carried.
    public func saveLog(_ log: WorkoutLog) throws {
        try transaction {
            try run("INSERT OR REPLACE INTO logs VALUES (?, ?, ?, ?, ?, ?, ?)", [
                .text(log.id), .text(log.workoutID), .text(log.workoutName),
                .double(log.startedAt.timeIntervalSince1970), .double(log.finishedAt.timeIntervalSince1970),
                .text(log.skippedExerciseIDs.joined(separator: ",")), .text(log.notes),
            ])
            try run("DELETE FROM sets WHERE log_id = ?", [.text(log.id)])
            for (position, set) in log.sets.enumerated() {
                try run("""
                    INSERT INTO sets (id, log_id, position, exercise_id, set_number, reps, weight_kg,
                        completed_at, plan_line_id, target_reps, incline, started_at, measure, pool_length)
                    VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
                    """, [
                    .text(set.id), .text(log.id), .int(position), .text(set.exerciseID),
                    .int(set.setNumber), .int(set.reps), .double(set.weight.kilograms),
                    .double(set.completedAt.timeIntervalSince1970),
                    .optionalText(set.planLineID), .optionalInt(set.targetReps), .optionalDouble(set.incline),
                    .optionalDouble(set.startedAt?.timeIntervalSince1970), .optionalText(set.measure?.rawValue),
                    .optionalText(set.poolLength?.rawValue),
                ])
            }
        }
    }

    public func deleteLog(id: String) throws {
        try run("DELETE FROM logs WHERE id = ?", [.text(id)])
    }

    public func deleteSets(exerciseID: String) throws {
        try run("DELETE FROM sets WHERE exercise_id = ?", [.text(exerciseID)])
    }

    // MARK: - Gyms

    /// Home first, then by name.
    public func gyms() throws -> [Gym] {
        try query("SELECT id, name, kit, price_cents, price_period, hours, travel_minutes, notes FROM gyms ORDER BY id != 'home', name COLLATE NOCASE") { row in
            let period = row.optionalText(4).flatMap(Price.Period.init(rawValue:))
            let price: Price? = if let cents = row.optionalInt(3), let period { Price(cents: cents, period: period) } else { nil }
            return Gym(
                id: row.text(0), name: row.text(1),
                kitIDs: Set(row.text(2).split(separator: ",").map(String.init)),
                price: price,
                hours: (try? JSONDecoder().decode(OpeningHours.self, from: Data(row.text(5).utf8))) ?? .always,
                travelMinutes: row.int(6), notes: row.text(7)
            )
        }
    }

    public func saveGym(_ gym: Gym) throws {
        try run("""
            INSERT OR REPLACE INTO gyms (id, name, kit, price_cents, price_period, hours, travel_minutes, notes)
            VALUES (?, ?, ?, ?, ?, ?, ?, ?)
            """, [
            .text(gym.id), .text(gym.name),
            .text(gym.kitIDs.sorted().joined(separator: ",")),
            .optionalInt(gym.price?.cents), .optionalText(gym.price?.period.rawValue),
            .text(try Self.json(gym.hours)), .int(gym.travelMinutes), .text(gym.notes),
        ])
    }

    /// Home can't go: a workout always has somewhere to be done.
    public func deleteGym(id: String) throws {
        guard id != Gym.homeID else { return }
        try run("DELETE FROM gyms WHERE id = ?", [.text(id)])
    }

    // MARK: - Session and settings, as JSON in meta

    public func activeSession() throws -> WorkoutSession? {
        try meta("active_session", as: WorkoutSession.self)
    }

    public func saveActiveSession(_ session: WorkoutSession?) throws {
        try setMeta("active_session", session)
    }

    public func settings() throws -> Settings? {
        try meta("settings", as: Settings.self)
    }

    public func saveSettings(_ settings: Settings) throws {
        try setMeta("settings", settings)
    }

    private func meta<T: Decodable>(_ key: String, as type: T.Type) throws -> T? {
        guard let data = try query("SELECT value FROM meta WHERE key = ?", [.text(key)], { $0.data(0) }).first
        else { return nil }
        return try? JSONDecoder().decode(T.self, from: data)
    }

    private func setMeta<T: Encodable>(_ key: String, _ value: T?) throws {
        guard let value else {
            try run("DELETE FROM meta WHERE key = ?", [.text(key)])
            return
        }
        try run("INSERT OR REPLACE INTO meta VALUES (?, ?)", [.text(key), .blob(try JSONEncoder().encode(value))])
    }

    // MARK: - Backup

    /// A consistent copy of the whole database, for the share sheet.
    public func backup(to destination: URL) throws {
        try? FileManager.default.removeItem(at: destination)
        try run("VACUUM INTO ?", [.text(destination.path)])
    }

    /// Opens a candidate file read-only and counts what it holds. Anything
    /// that isn't one of our databases throws, so a bad pick can't replace
    /// good data.
    public static func inspect(_ file: URL) throws -> BackupSummary {
        var handle: OpaquePointer?
        guard sqlite3_open_v2(file.path, &handle, SQLITE_OPEN_READONLY, nil) == SQLITE_OK else {
            sqlite3_close(handle)
            throw StoreError(description: "That file isn't a Gym Buddies backup.")
        }
        defer { sqlite3_close(handle) }
        func count(_ table: String) throws -> Int {
            var statement: OpaquePointer?
            defer { sqlite3_finalize(statement) }
            guard sqlite3_prepare_v2(handle, "SELECT COUNT(*) FROM \(table)", -1, &statement, nil) == SQLITE_OK,
                  sqlite3_step(statement) == SQLITE_ROW
            else { throw StoreError(description: "That file isn't a Gym Buddies backup.") }
            return Int(sqlite3_column_int(statement, 0))
        }
        _ = try count("migrations")
        return BackupSummary(sessions: try count("logs"), workouts: try count("workouts"))
    }

    /// Swaps the live database for a backup, then migrates it forward.
    public func replace(with file: URL) throws {
        _ = try Self.inspect(file)
        lock.lock()
        defer { lock.unlock() }
        let staged = url.appendingPathExtension("incoming")
        try? FileManager.default.removeItem(at: staged)
        try FileManager.default.copyItem(at: file, to: staged)
        sqlite3_close(db)
        db = nil
        _ = try FileManager.default.replaceItemAt(url, withItemAt: staged)
        try open()
    }

    public var fileSize: Int {
        (try? FileManager.default.attributesOfItem(atPath: url.path)[.size] as? Int) ?? 0
    }

    // MARK: - Plumbing

    enum Value {
        case int(Int), double(Double), text(String), blob(Data), null

        static func bool(_ b: Bool) -> Value { .int(b ? 1 : 0) }
        static func optionalText(_ s: String?) -> Value { s.map(Value.text) ?? .null }
        static func optionalInt(_ i: Int?) -> Value { i.map(Value.int) ?? .null }
        static func optionalDouble(_ d: Double?) -> Value { d.map(Value.double) ?? .null }
    }

    struct Row {
        let statement: OpaquePointer?
        func text(_ i: Int32) -> String { optionalText(i) ?? "" }
        func optionalText(_ i: Int32) -> String? {
            sqlite3_column_text(statement, i).map { String(cString: $0) }
        }
        func int(_ i: Int32) -> Int { Int(sqlite3_column_int64(statement, i)) }
        func optionalInt(_ i: Int32) -> Int? { isNull(i) ? nil : int(i) }
        func double(_ i: Int32) -> Double { sqlite3_column_double(statement, i) }
        func optionalDouble(_ i: Int32) -> Double? { isNull(i) ? nil : double(i) }
        func bool(_ i: Int32) -> Bool { int(i) != 0 }
        func data(_ i: Int32) -> Data {
            guard let bytes = sqlite3_column_blob(statement, i) else { return Data() }
            return Data(bytes: bytes, count: Int(sqlite3_column_bytes(statement, i)))
        }
        private func isNull(_ i: Int32) -> Bool { sqlite3_column_type(statement, i) == SQLITE_NULL }
    }

    private static let transient = unsafeBitCast(-1, to: sqlite3_destructor_type.self)

    private func error() -> StoreError {
        StoreError(description: String(cString: sqlite3_errmsg(db)))
    }

    private func exec(_ sql: String) throws {
        lock.lock()
        defer { lock.unlock() }
        guard sqlite3_exec(db, sql, nil, nil, nil) == SQLITE_OK else { throw error() }
    }

    private func prepare(_ sql: String, _ values: [Value]) throws -> OpaquePointer? {
        var statement: OpaquePointer?
        guard sqlite3_prepare_v2(db, sql, -1, &statement, nil) == SQLITE_OK else { throw error() }
        for (offset, value) in values.enumerated() {
            let i = Int32(offset + 1)
            switch value {
            case .int(let v): sqlite3_bind_int64(statement, i, Int64(v))
            case .double(let v): sqlite3_bind_double(statement, i, v)
            case .text(let v): sqlite3_bind_text(statement, i, v, -1, Self.transient)
            case .blob(let v): _ = v.withUnsafeBytes { sqlite3_bind_blob(statement, i, $0.baseAddress, Int32(v.count), Self.transient) }
            case .null: sqlite3_bind_null(statement, i)
            }
        }
        return statement
    }

    private func run(_ sql: String, _ values: [Value] = []) throws {
        lock.lock()
        defer { lock.unlock() }
        let statement = try prepare(sql, values)
        defer { sqlite3_finalize(statement) }
        guard sqlite3_step(statement) == SQLITE_DONE else { throw error() }
    }

    private func query<T>(_ sql: String, _ values: [Value] = [], _ map: (Row) throws -> T) throws -> [T] {
        lock.lock()
        defer { lock.unlock() }
        let statement = try prepare(sql, values)
        defer { sqlite3_finalize(statement) }
        var rows: [T] = []
        while true {
            let step = sqlite3_step(statement)
            if step == SQLITE_DONE { break }
            guard step == SQLITE_ROW else { throw error() }
            rows.append(try map(Row(statement: statement)))
        }
        return rows
    }

    private func transaction(_ body: () throws -> Void) throws {
        lock.lock()
        defer { lock.unlock() }
        try exec("BEGIN")
        do {
            try body()
            try exec("COMMIT")
        } catch {
            try? exec("ROLLBACK")
            throw error
        }
    }

    private static func join(_ muscles: [Muscle]) -> String {
        muscles.map(\.rawValue).joined(separator: ",")
    }
}
