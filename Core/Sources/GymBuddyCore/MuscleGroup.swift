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

/// Finer than `MuscleGroup`: what the muscle map lights up. A curl and a
/// pushdown are both "Arms" and share no muscle.
public enum Muscle: String, Codable, Sendable, CaseIterable, Identifiable {
    case chest, frontDelts, sideDelts, rearDelts
    case biceps, triceps, forearms
    case lats, traps, lowerBack
    case abs, obliques
    case glutes, quads, hamstrings, calves, adductors

    public var id: String { rawValue }

    public var displayName: String {
        switch self {
        case .chest: "Chest"
        case .frontDelts: "Front delts"
        case .sideDelts: "Side delts"
        case .rearDelts: "Rear delts"
        case .biceps: "Biceps"
        case .triceps: "Triceps"
        case .forearms: "Forearms"
        case .lats: "Lats"
        case .traps: "Traps"
        case .lowerBack: "Lower back"
        case .abs: "Abs"
        case .obliques: "Obliques"
        case .glutes: "Glutes"
        case .quads: "Quads"
        case .hamstrings: "Hamstrings"
        case .calves: "Calves"
        case .adductors: "Adductors"
        }
    }
}
