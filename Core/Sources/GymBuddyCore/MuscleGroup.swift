import Foundation

public enum MuscleGroup: String, Codable, Sendable, CaseIterable, Identifiable {
    case arms, back, chest, shoulders, legs, core, cardio, fullBody

    public var id: String { rawValue }

    public var displayName: String {
        switch self {
        case .arms: "Arms"
        case .back: "Back"
        case .chest: "Chest"
        case .shoulders: "Shoulders"
        case .legs: "Legs"
        case .core: "Core"
        case .cardio: "Cardio"
        case .fullBody: "Full Body"
        }
    }
}
