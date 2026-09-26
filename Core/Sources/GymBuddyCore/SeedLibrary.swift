import Foundation

/// A starter library, enough to build a real workout on first launch. The full
/// catalogue and its illustrations land in T2.4 — see docs/DESIGN.md's Risks
/// section for why the artwork is the expensive part.
public enum SeedLibrary {
    public static let exercises: [Exercise] = [
        .init(id: "barbell-curls", name: "Barbell Curls", muscleGroup: .arms, equipment: .barbell),
        .init(id: "cable-tricep-extensions", name: "Cable Tricep Extensions", muscleGroup: .arms, equipment: .cable),
        .init(id: "dumbbell-hammer-curls", name: "Dumbbell Hammer Curls", muscleGroup: .arms, equipment: .dumbbell),
        .init(id: "seated-machine-rows", name: "Seated Machine Rows", muscleGroup: .back, equipment: .machine),
        .init(id: "lat-pull-downs", name: "Lat Pull Downs", muscleGroup: .back, equipment: .machine),
        .init(id: "barbell-deadlifts", name: "Barbell Deadlifts", muscleGroup: .back, equipment: .barbell),
        .init(id: "pull-ups", name: "Pull Ups", muscleGroup: .back, equipment: .bodyweight),
        .init(id: "barbell-bench-press", name: "Barbell Bench Press", muscleGroup: .chest, equipment: .barbell),
        .init(id: "dumbbell-flyes", name: "Dumbbell Flyes", muscleGroup: .chest, equipment: .dumbbell),
        .init(id: "push-ups", name: "Push Ups", muscleGroup: .chest, equipment: .bodyweight),
        .init(id: "seated-machine-presses", name: "Seated Machine Presses", muscleGroup: .shoulders, equipment: .machine),
        .init(id: "dumbbell-lateral-raises", name: "Dumbbell Lateral Raises", muscleGroup: .shoulders, equipment: .dumbbell),
        .init(id: "barbell-overhead-press", name: "Barbell Overhead Press", muscleGroup: .shoulders, equipment: .barbell),
        .init(id: "barbell-squats", name: "Barbell Squats", muscleGroup: .legs, equipment: .barbell),
        .init(id: "seated-leg-curls", name: "Seated Leg Curls", muscleGroup: .legs, equipment: .machine),
        .init(id: "leg-press", name: "Leg Press", muscleGroup: .legs, equipment: .machine),
        .init(id: "walking-lunges", name: "Walking Lunges", muscleGroup: .legs, equipment: .dumbbell),
        .init(id: "planking", name: "Planking", muscleGroup: .core, equipment: .bodyweight),
        .init(id: "hanging-leg-raises", name: "Hanging Leg Raises", muscleGroup: .core, equipment: .bodyweight),
        .init(id: "cable-woodchoppers", name: "Cable Woodchoppers", muscleGroup: .core, equipment: .cable),
        .init(id: "walking", name: "Walking", muscleGroup: .cardio, equipment: .bodyweight),
        .init(id: "rowing-machine", name: "Rowing Machine", muscleGroup: .cardio, equipment: .machine),
        .init(id: "kettlebell-swings", name: "Kettlebell Swings", muscleGroup: .fullBody, equipment: .kettlebell),
        .init(id: "burpees", name: "Burpees", muscleGroup: .fullBody, equipment: .bodyweight),
    ]

    public static var byID: [String: Exercise] {
        Dictionary(uniqueKeysWithValues: exercises.map { ($0.id, $0) })
    }
}
