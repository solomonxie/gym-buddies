import Foundation

public enum Equipment: String, Codable, Sendable, CaseIterable {
    case barbell, dumbbell, machine, cable, kettlebell, band, bodyweight, treadmill, pool, none

    public var displayName: String {
        switch self {
        case .barbell: "Barbell"
        case .dumbbell: "Dumbbell"
        case .machine: "Machine"
        case .cable: "Cable"
        case .kettlebell: "Kettlebell"
        case .band: "Band"
        case .bodyweight: "Bodyweight"
        case .treadmill: "Treadmill"
        case .pool: "Pool"
        case .none: "Other"
        }
    }

    /// True when the load is a number worth tracking at all. A resistance band
    /// has a colour, not a weight; a treadmill has an incline instead.
    public var isLoadable: Bool {
        ![.band, .none, .treadmill, .pool].contains(self)
    }

    /// What a gym has to own for a movement on it. Your body and the
    /// catch-all "Other" go everywhere.
    public var needsAGym: Bool { self != .bodyweight && self != .none }

    /// The incline control's step, percent, for equipment that has one.
    public var inclineStep: Double? {
        self == .treadmill ? 0.5 : nil
    }

    /// One tap of the incline stepper, kept within what a treadmill offers
    /// and rounded so repeated taps can't drift off the 0.5% grid.
    public func stepped(incline: Double, by steps: Int) -> Double {
        guard let step = inclineStep else { return incline }
        let raw = min(Self.maxIncline, max(0, incline + step * Double(steps)))
        return (raw / step).rounded() * step
    }

    public static let maxIncline = 30.0

    /// The smallest change the equipment physically allows. A barbell moves in
    /// plate *pairs*, a machine in stack plates, a dumbbell in rack steps — so
    /// a single global "+1" is wrong on every one of them.
    public func increment(in unit: WeightUnit) -> Weight {
        switch unit {
        case .kilograms:
            switch self {
            case .barbell, .cable: Weight(kilograms: 2.5)
            case .dumbbell: Weight(kilograms: 2)
            case .machine: Weight(kilograms: 5)
            case .kettlebell: Weight(kilograms: 4)
            case .bodyweight: Weight(kilograms: 1.25)
            case .band, .treadmill, .pool, .none: Weight.zero
            }
        case .pounds:
            switch self {
            case .barbell, .cable: Weight(pounds: 5)
            case .dumbbell: Weight(pounds: 5)
            case .machine: Weight(pounds: 10)
            case .kettlebell: Weight(pounds: 10)
            case .bodyweight: Weight(pounds: 2.5)
            case .band, .treadmill, .pool, .none: Weight.zero
            }
        }
    }

    /// Never lets a tap put a negative number on the bar.
    public func stepped(_ weight: Weight, by steps: Int, in unit: WeightUnit) -> Weight {
        let delta = increment(in: unit).kilograms * Double(steps)
        return Weight(kilograms: max(0, weight.kilograms + delta))
    }
}
