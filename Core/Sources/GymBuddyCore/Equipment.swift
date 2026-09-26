import Foundation

public enum Equipment: String, Codable, Sendable, CaseIterable {
    case barbell, dumbbell, machine, cable, kettlebell, band, bodyweight, none

    public var displayName: String {
        switch self {
        case .barbell: "Barbell"
        case .dumbbell: "Dumbbell"
        case .machine: "Machine"
        case .cable: "Cable"
        case .kettlebell: "Kettlebell"
        case .band: "Band"
        case .bodyweight: "Bodyweight"
        case .none: "Other"
        }
    }

    /// True when the load is a number worth tracking at all. A resistance band
    /// has a colour, not a weight.
    public var isLoadable: Bool {
        self != .band && self != .none
    }

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
            case .band, .none: Weight.zero
            }
        case .pounds:
            switch self {
            case .barbell, .cable: Weight(pounds: 5)
            case .dumbbell: Weight(pounds: 5)
            case .machine: Weight(pounds: 10)
            case .kettlebell: Weight(pounds: 10)
            case .bodyweight: Weight(pounds: 2.5)
            case .band, .none: Weight.zero
            }
        }
    }

    /// Never lets a tap put a negative number on the bar.
    public func stepped(_ weight: Weight, by steps: Int, in unit: WeightUnit) -> Weight {
        let delta = increment(in: unit).kilograms * Double(steps)
        return Weight(kilograms: max(0, weight.kilograms + delta))
    }
}
