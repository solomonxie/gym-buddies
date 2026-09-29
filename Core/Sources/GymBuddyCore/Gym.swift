import Foundation

/// A place you train: what it has, what it costs, when it's open, how far.
public struct Gym: Identifiable, Hashable, Codable, Sendable {
    public var id: String
    public var name: String
    /// `Kit` IDs: the equipment and machines this place has.
    public var kitIDs: Set<String>
    public var price: Price?
    public var hours: OpeningHours
    public var travelMinutes: Int
    public var notes: String

    public static let homeID = "home"

    /// Always present and never deleted, so a workout always has somewhere to go.
    public var isHome: Bool { id == Self.homeID }

    public static let home = Gym(
        id: homeID, name: "Home",
        hours: .always, travelMinutes: 0
    )

    public init(
        id: String,
        name: String,
        kitIDs: Set<String> = [],
        price: Price? = nil,
        hours: OpeningHours = .always,
        travelMinutes: Int = 0,
        notes: String = ""
    ) {
        self.id = id
        self.name = name
        self.kitIDs = kitIDs
        self.price = price
        self.hours = hours
        self.travelMinutes = travelMinutes
        self.notes = notes
    }

    public func has(_ exercise: Exercise) -> Bool {
        Kit.needed(by: exercise).map { kitIDs.contains($0.id) } ?? true
    }

    /// What the workout needs that this gym doesn't have, in plan order.
    public func missingExercises(for workout: Workout, exercises: [String: Exercise]) -> [Exercise] {
        var missing: [Exercise] = []
        for line in workout.exercises {
            guard let exercise = exercises[line.exerciseID], !has(exercise),
                  !missing.contains(where: { $0.id == exercise.id }) else { continue }
            missing.append(exercise)
        }
        return missing
    }

    /// Whether it's open when you'd get there if you left at `leaving`.
    public func availability(leaving: Date, calendar: Calendar = .current) -> Availability {
        let arrival = leaving.addingTimeInterval(TimeInterval(travelMinutes * 60))
        return Availability(arrival: arrival, status: hours.status(at: arrival, calendar: calendar))
    }

    /// Open on arrival first, nearest first; then the rest by when they open.
    public static func sorted(_ gyms: [Gym], leaving: Date, calendar: Calendar = .current) -> [(gym: Gym, availability: Availability)] {
        gyms.map { ($0, $0.availability(leaving: leaving, calendar: calendar)) }.sorted { a, b in
            switch (a.1.status, b.1.status) {
            case (.open, .closed): return true
            case (.closed, .open): return false
            case (.open, .open): return (a.0.travelMinutes, a.0.name) < (b.0.travelMinutes, b.0.name)
            case (.closed(let x), .closed(let y)):
                return (x ?? .distantFuture, a.0.name) < (y ?? .distantFuture, b.0.name)
            }
        }
    }
}

public struct Availability: Hashable, Sendable {
    public let arrival: Date
    public let status: GymStatus

    /// Time to train before it shuts; nil when it's closed or never shuts.
    public var minutesBeforeClose: Int? {
        guard case .open(let until?) = status else { return nil }
        return Int(until.timeIntervalSince(arrival) / 60)
    }

    public var isOpen: Bool {
        if case .open = status { return true }
        return false
    }
}

public enum GymStatus: Hashable, Sendable {
    /// Nil `until` means it never shuts.
    case open(until: Date?)
    /// Nil `opensAt` means it has no hours at all.
    case closed(opensAt: Date?)
}

public struct Price: Hashable, Codable, Sendable {
    public enum Period: String, Codable, Sendable, CaseIterable {
        case visit, month, year

        public var displayName: String {
            switch self {
            case .visit: "visit"
            case .month: "month"
            case .year: "year"
            }
        }
    }

    /// Cents, so money never goes near a Double's rounding.
    public var cents: Int
    public var period: Period

    public init(cents: Int, period: Period) {
        self.cents = cents
        self.period = period
    }

    /// `$45/month`, `€8/visit`.
    public func format(locale: Locale = .current) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.locale = locale
        if cents % 100 == 0 { formatter.maximumFractionDigits = 0 }
        let amount = formatter.string(from: NSDecimalNumber(value: cents).multiplying(byPowerOf10: -2)) ?? "\(cents / 100)"
        return "\(amount)/\(period.displayName)"
    }
}

/// A week of opening times. Each period belongs to the day it opens on, so a
/// Friday 22:00–02:00 is still open at 1 a.m. on Saturday.
public struct OpeningHours: Hashable, Codable, Sendable {
    public struct Period: Hashable, Codable, Sendable {
        /// `Calendar` numbering: 1 is Sunday.
        public var weekday: Int
        /// Minutes after midnight. `close <= open` runs past midnight;
        /// `close == open` is the whole day.
        public var open: Int
        public var close: Int

        public init(weekday: Int, open: Int, close: Int) {
            self.weekday = weekday
            self.open = open
            self.close = close
        }

        public var isAllDay: Bool { open == close }
    }

    public var periods: [Period]

    public init(periods: [Period]) {
        self.periods = periods
    }

    public static let always = OpeningHours(periods: (1...7).map { Period(weekday: $0, open: 0, close: 0) })

    /// The same hours every day.
    public static func daily(open: Int, close: Int) -> OpeningHours {
        OpeningHours(periods: (1...7).map { Period(weekday: $0, open: open, close: close) })
    }

    public var isAlwaysOpen: Bool {
        Set(periods.filter(\.isAllDay).map(\.weekday)).count == 7
    }

    public func periods(on weekday: Int) -> [Period] {
        periods.filter { $0.weekday == weekday }.sorted { $0.open < $1.open }
    }

    public func status(at date: Date, calendar: Calendar = .current) -> GymStatus {
        if isAlwaysOpen { return .open(until: nil) }
        let spans = merged(intervals(around: date, calendar: calendar))
        if let current = spans.first(where: { $0.start <= date && date < $0.end }) {
            return .open(until: current.end)
        }
        return .closed(opensAt: spans.map(\.start).filter { $0 > date }.min())
    }

    /// Every opening from the day before to a week after, as real dates.
    private func intervals(around date: Date, calendar: Calendar) -> [DateInterval] {
        let today = calendar.startOfDay(for: date)
        var out: [DateInterval] = []
        for offset in -1...8 {
            guard let day = calendar.date(byAdding: .day, value: offset, to: today) else { continue }
            let weekday = calendar.component(.weekday, from: day)
            for p in periods where p.weekday == weekday {
                guard let start = calendar.date(byAdding: .minute, value: p.open, to: day),
                      let end = calendar.date(byAdding: .minute, value: p.close > p.open ? p.close : p.close + 24 * 60, to: day)
                else { continue }
                out.append(DateInterval(start: start, end: end))
            }
        }
        return out
    }

    /// Back-to-back openings read as one: 24 h Monday into 24 h Tuesday
    /// closes Tuesday night, not Monday midnight.
    private func merged(_ intervals: [DateInterval]) -> [DateInterval] {
        var out: [DateInterval] = []
        for next in intervals.sorted(by: { $0.start < $1.start }) {
            if let last = out.last, next.start <= last.end {
                out[out.count - 1] = DateInterval(start: last.start, end: max(last.end, next.end))
            } else {
                out.append(next)
            }
        }
        return out
    }
}
