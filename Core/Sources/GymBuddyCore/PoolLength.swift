import Foundation

/// One length of a pool. A short list, not a free number: pools come in a
/// handful of sizes, and a 25 yd pool counts its distance in yards.
public enum PoolLength: String, Codable, Sendable, CaseIterable, Identifiable {
    case m15, m20, m25, yd25, m33, m50

    public static let `default`: PoolLength = .m25

    public var id: String { rawValue }

    /// In the pool's own unit — metres, or yards for a yard pool.
    public var length: Double {
        switch self {
        case .m15: 15
        case .m20: 20
        case .m25, .yd25: 25
        case .m33: 33.33
        case .m50: 50
        }
    }

    public var unit: String { self == .yd25 ? "yd" : "m" }

    public var displayName: String {
        self == .m33 ? "33⅓ m" : "\(Int(length)) \(unit)"
    }

    /// `300 m`, `1,050 yd`.
    public func distance(laps: Int) -> String {
        Self.format(Double(laps) * length, unit: unit)
    }

    static func format(_ value: Double, unit: String) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.maximumFractionDigits = 0
        formatter.locale = Locale(identifier: "en_US")
        return "\(formatter.string(from: NSNumber(value: value.rounded())) ?? "0") \(unit)"
    }

    /// A recreational pace, about 2:00 per 100: what planned minutes assume.
    public var plannedSecondsPerLap: Double { length / 25 * 30 }
}
