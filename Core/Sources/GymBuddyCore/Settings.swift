import Foundation

public struct Settings: Codable, Equatable, Sendable {
    public var unit: WeightUnit = .pounds
    public var restBetweenSets: Int = 60
    public var restBetweenExercises: Int = 90
    public var alertWhenRestOver = true
    public var vibrate = true
    /// Off: the rest notification already solves what this would.
    public var keepScreenAwake = false
    public var suggestHeavier = true
    public var countdownLastSeconds = true
    public var lastBackup: Date?
    public var lastBackupBytes: Int?
    /// Defaults for a line added to a workout.
    public var defaultSets: Int = 3
    public var defaultReps: Int = 10
    /// One file a day in the user's own iCloud Drive, replaced on each change.
    public var iCloudBackup = false
    public var lastAutoBackup: Date?
    public var lastICloudBackup: Date?

    public init() {}

    /// Every field optional on the way in, so adding a setting never resets
    /// the ones already saved.
    public init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        let d = Settings()
        unit = try c.decodeIfPresent(WeightUnit.self, forKey: .unit) ?? d.unit
        restBetweenSets = try c.decodeIfPresent(Int.self, forKey: .restBetweenSets) ?? d.restBetweenSets
        restBetweenExercises = try c.decodeIfPresent(Int.self, forKey: .restBetweenExercises) ?? d.restBetweenExercises
        alertWhenRestOver = try c.decodeIfPresent(Bool.self, forKey: .alertWhenRestOver) ?? d.alertWhenRestOver
        vibrate = try c.decodeIfPresent(Bool.self, forKey: .vibrate) ?? d.vibrate
        keepScreenAwake = try c.decodeIfPresent(Bool.self, forKey: .keepScreenAwake) ?? d.keepScreenAwake
        suggestHeavier = try c.decodeIfPresent(Bool.self, forKey: .suggestHeavier) ?? d.suggestHeavier
        countdownLastSeconds = try c.decodeIfPresent(Bool.self, forKey: .countdownLastSeconds) ?? d.countdownLastSeconds
        lastBackup = try c.decodeIfPresent(Date.self, forKey: .lastBackup)
        lastBackupBytes = try c.decodeIfPresent(Int.self, forKey: .lastBackupBytes)
        defaultSets = try c.decodeIfPresent(Int.self, forKey: .defaultSets) ?? d.defaultSets
        defaultReps = try c.decodeIfPresent(Int.self, forKey: .defaultReps) ?? d.defaultReps
        iCloudBackup = try c.decodeIfPresent(Bool.self, forKey: .iCloudBackup) ?? d.iCloudBackup
        lastAutoBackup = try c.decodeIfPresent(Date.self, forKey: .lastAutoBackup)
        lastICloudBackup = try c.decodeIfPresent(Date.self, forKey: .lastICloudBackup)
    }

    /// The in-place rest picker's choices.
    public static let restChoices = [30, 45, 60, 90, 120, 180]
}
