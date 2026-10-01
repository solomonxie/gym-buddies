import Foundation

/// Which automatic backups to write and which to let go. File names carry
/// their own timestamps, so the rules need nothing but a directory listing.
///
/// - On the phone: a new file on every change, never overwritten. The newest
///   `perDay` of today are kept, then the newest one of each earlier day,
///   for the last `days` days.
/// - In iCloud: one file per day, overwritten by each change that day; the
///   last `cloudDays` days are kept.
public enum BackupRotation {
    public static let perDay = 20
    public static let days = 7
    public static let cloudDays = 30
    static let prefix = "GymBuddy-"
    static let suffix = ".sqlite"

    private static func formatter(_ format: String) -> DateFormatter {
        let f = DateFormatter()
        f.locale = Locale(identifier: "en_US_POSIX")
        f.calendar = Calendar(identifier: .gregorian)
        f.timeZone = .current
        f.dateFormat = format
        return f
    }

    /// `GymBuddy-2026-09-26_21-05-33-120.sqlite` — milliseconds, so two
    /// changes in one second don't collide.
    public static func localName(at date: Date) -> String {
        prefix + formatter("yyyy-MM-dd_HH-mm-ss-SSS").string(from: date) + suffix
    }

    /// `GymBuddy-2026-09-26.sqlite`.
    public static func cloudName(at date: Date) -> String {
        prefix + formatter("yyyy-MM-dd").string(from: date) + suffix
    }

    public static func date(fromLocalName name: String) -> Date? {
        stamp(name).flatMap { formatter("yyyy-MM-dd_HH-mm-ss-SSS").date(from: $0) }
    }

    public static func date(fromCloudName name: String) -> Date? {
        stamp(name).flatMap { formatter("yyyy-MM-dd").date(from: $0) }
    }

    private static func stamp(_ name: String) -> String? {
        guard name.hasPrefix(prefix), name.hasSuffix(suffix) else { return nil }
        return String(name.dropFirst(prefix.count).dropLast(suffix.count))
    }

    /// Local files to delete. Names that aren't ours are never touched.
    public static func localExpired(
        _ names: [String],
        now: Date,
        calendar: Calendar = .current
    ) -> [String] {
        let dated = names.compactMap { name in date(fromLocalName: name).map { (name, $0) } }
        let today = calendar.startOfDay(for: now)
        let oldest = firstKeptDay(now: now, days: days, calendar: calendar)
        var expired: [String] = []
        for (day, files) in Dictionary(grouping: dated, by: { calendar.startOfDay(for: $0.1) }) {
            let keep = day >= today ? perDay : day >= oldest ? 1 : 0
            for file in files.sorted(by: { $0.1 > $1.1 }).dropFirst(keep) {
                expired.append(file.0)
            }
        }
        return expired.sorted()
    }

    public static func cloudExpired(
        _ names: [String],
        now: Date,
        calendar: Calendar = .current
    ) -> [String] {
        let oldest = firstKeptDay(now: now, days: cloudDays, calendar: calendar)
        return names.filter { name in date(fromCloudName: name).map { $0 < oldest } ?? false }.sorted()
    }

    /// Local backups, newest first, for the restore list.
    public static func sortedLocal(_ names: [String]) -> [(name: String, date: Date)] {
        names.compactMap { name in date(fromLocalName: name).map { (name, $0) } }
            .sorted { $0.date > $1.date }
    }

    private static func firstKeptDay(now: Date, days: Int, calendar: Calendar) -> Date {
        calendar.date(byAdding: .day, value: -(days - 1), to: calendar.startOfDay(for: now))!
    }
}
