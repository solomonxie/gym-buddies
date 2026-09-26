import SwiftUI

struct SessionView: View {
    @Environment(AppModel.self) private var model

    var body: some View {
        Placeholder(
            task: "T4.1–T4.5 · Run a workout",
            drawing: "docs/uiux/session.md",
            note: "State lives in GymBuddyCore.WorkoutSession — this screen only draws it."
        )
    }
}
