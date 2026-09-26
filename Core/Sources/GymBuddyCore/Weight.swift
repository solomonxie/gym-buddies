import Foundation

public enum WeightUnit: String, Codable, Sendable, CaseIterable {
    case kilograms, pounds

    public var abbreviation: String {
        switch self {
        case .kilograms: "kg"
        case .pounds: "lb"
        }
    }
}

/// Stored in kilograms always, displayed in whatever the user picked. Mixing
/// the two in storage is how a log silently becomes wrong when someone flips
/// the setting.
public struct Weight: Hashable, Codable, Sendable, Comparable {
    public static let poundsPerKilogram = 2.204_622_621_848_776
    public static let zero = Weight(kilograms: 0)

    public var kilograms: Double

    public init(kilograms: Double) {
        self.kilograms = kilograms
    }

    public init(pounds: Double) {
        self.kilograms = pounds / Self.poundsPerKilogram
    }

    public init(_ value: Double, _ unit: WeightUnit) {
        switch unit {
        case .kilograms: self.init(kilograms: value)
        case .pounds: self.init(pounds: value)
        }
    }

    public var pounds: Double { kilograms * Self.poundsPerKilogram }

    public func value(in unit: WeightUnit) -> Double {
        switch unit {
        case .kilograms: kilograms
        case .pounds: pounds
        }
    }

    /// One decimal, the way a plate or a stack pin is actually labelled.
    public func formatted(in unit: WeightUnit) -> String {
        String(format: "%.1f %@", value(in: unit), unit.abbreviation)
    }

    /// Compared to a tenth of a gram, not to the last bit. 50 lb converted to
    /// kilograms and back is not bit-identical to 50 lb, and two loads a human
    /// would call equal must not sort as different — the personal-record
    /// tie-break depends on `==` actually matching.
    private var quantized: Int64 { Int64((kilograms * 10_000).rounded()) }

    public static func == (a: Weight, b: Weight) -> Bool {
        a.quantized == b.quantized
    }

    public func hash(into hasher: inout Hasher) {
        hasher.combine(quantized)
    }

    public static func < (a: Weight, b: Weight) -> Bool { a.quantized < b.quantized }

    public static func + (a: Weight, b: Weight) -> Weight {
        Weight(kilograms: a.kilograms + b.kilograms)
    }

    public static func * (w: Weight, n: Int) -> Weight {
        Weight(kilograms: w.kilograms * Double(n))
    }
}
