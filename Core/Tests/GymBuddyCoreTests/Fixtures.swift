import Foundation
@testable import GymBuddyCore

enum Fixtures {
    static let t0 = Date(timeIntervalSince1970: 1_000_000)

    static let rows = Exercise(
        id: "seated-machine-rows",
        name: "Seated Machine Rows",
        muscleGroup: .back,
        equipment: .machine
    )

    static let pullDowns = Exercise(
        id: "lat-pull-downs",
        name: "Lat Pull Downs",
        muscleGroup: .back,
        equipment: .machine
    )

    static let walking = Exercise(
        id: "walking",
        name: "Walking",
        muscleGroup: .cardio,
        equipment: .bodyweight
    )

    static let catalogue: [String: Exercise] = [
        rows.id: rows, pullDowns.id: pullDowns, walking.id: walking,
    ]

    /// Mirrors the "Fraiser Heights" workout in the reference screenshots.
    static let workout = Workout(
        id: "fraiser-heights",
        name: "Fraiser Heights",
        exercises: [
            WorkoutExercise(
                id: "p-walking",
                exerciseID: walking.id,
                targetSets: 1,
                targetReps: 5,
                targetWeight: Weight(pounds: 3)
            ),
            WorkoutExercise(
                id: "p-rows",
                exerciseID: rows.id,
                targetSets: 3,
                targetReps: 10,
                targetWeight: Weight(pounds: 50)
            ),
            WorkoutExercise(
                id: "p-pulldowns",
                exerciseID: pullDowns.id,
                targetSets: 3,
                targetReps: 10,
                targetWeight: Weight(pounds: 50),
                restSeconds: 90
            ),
        ]
    )

    static func session() -> WorkoutSession {
        WorkoutSession(
            id: "s1",
            workout: workout,
            exercises: catalogue,
            startedAt: t0,
            defaultRestSeconds: 60
        )
    }
}
