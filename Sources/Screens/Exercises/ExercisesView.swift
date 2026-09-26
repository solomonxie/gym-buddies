import SwiftUI

struct ExercisesView: View {
    var body: some View {
        NavigationStack {
            Placeholder(task: "T3.1 · Exercise library", drawing: "docs/uiux/exercises.md")
                .navigationTitle("Exercises")
        }
    }
}
