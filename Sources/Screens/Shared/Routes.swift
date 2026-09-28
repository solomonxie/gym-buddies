import SwiftUI
import GymBuddyCore

/// Every pushed screen, by value, so any tab can open any of them.
enum Route: Hashable {
    case exercise(String)
    case workout(String)
    case addExercises(String)
    case log(String)
    case trend(String)
    case gym(String)
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
            }
        }
    }
}

/// A tab's navigation stack, seeded by demo deep links in DEBUG.
struct TabStack<Content: View>: View {
    let tab: AppTab
    @ViewBuilder var content: () -> Content
    @State private var path: [Route]

    init(_ tab: AppTab, @ViewBuilder content: @escaping () -> Content) {
        self.tab = tab
        self.content = content
        #if DEBUG
        _path = State(initialValue: DemoData.initialPath(for: tab))
        #else
        _path = State(initialValue: [])
        #endif
    }

    var body: some View {
        NavigationStack(path: $path) {
            content().withRoutes()
        }
    }
}
