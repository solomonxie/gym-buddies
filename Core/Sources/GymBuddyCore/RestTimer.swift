import Foundation

/// The ring between sets. Holds no clock of its own — every question takes the
/// current time — so it can be driven by a `TimelineView`, a background
/// wake-up, or a test, and give the same answer to all three.
public struct RestTimer: Equatable, Sendable {
    public private(set) var duration: TimeInterval
    public private(set) var startedAt: Date?

    public init(duration: TimeInterval = 60, startedAt: Date? = nil) {
        self.duration = duration
        self.startedAt = startedAt
    }

    public var isRunning: Bool { startedAt != nil }

    public mutating func start(_ duration: TimeInterval, at now: Date) {
        self.duration = duration
        self.startedAt = now
    }

    public mutating func dismiss() {
        startedAt = nil
    }

    /// The "+30s" tap. Extends the window without restarting it, so the time
    /// already rested still counts.
    public mutating func extend(by seconds: TimeInterval) {
        guard isRunning else { return }
        duration += seconds
    }

    public func remaining(at now: Date) -> TimeInterval {
        guard let startedAt else { return 0 }
        return max(0, duration - now.timeIntervalSince(startedAt))
    }

    /// 0 at the start, 1 when it fires — the ring fills, it doesn't drain.
    public func progress(at now: Date) -> Double {
        guard let startedAt, duration > 0 else { return 0 }
        let elapsed = now.timeIntervalSince(startedAt)
        return min(1, max(0, elapsed / duration))
    }

    public func hasFired(at now: Date) -> Bool {
        isRunning && remaining(at: now) == 0
    }

    /// `00:01:30`, matching the elapsed clock's format so the two read as a pair.
    public static func format(_ interval: TimeInterval) -> String {
        let total = Int(interval.rounded(.down))
        return String(
            format: "%02d:%02d:%02d",
            total / 3600, (total % 3600) / 60, total % 60
        )
    }
}
