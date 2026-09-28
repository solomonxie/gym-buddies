import SwiftUI
import GymBuddyCore

/// Every pushed screen, by value, so any screen can open any of them.
enum Route: Hashable {
    case exercise(String)
    case workout(String)
    case addExercises(String)
    case log(String)
    case trend(String)
    case gym(String)
    case exercises
    case gyms
    case settings
    case progress
}

extension View {
    func withRoutes() -> some View {
        navigationDestination(for: Route.self) { route in
            switch route {
            case .exercise(let id): ExerciseDetailView(exerciseID: id)
            case .workout(let id): WorkoutDetailView(workoutID: id)
            case .addExercises(let id): AddExercisesView(workoutID: id)
            case .log(let id): SessionLogView(logID: id)
            case .trend(let id): TrendView(exerciseID: id)
            case .gym(let id): GymEditorView(gymID: id)
            case .exercises: ExercisesView()
            case .gyms: GymsView()
            case .settings: SettingsView()
            case .progress: LogsView()
            }
        }
    }
}
