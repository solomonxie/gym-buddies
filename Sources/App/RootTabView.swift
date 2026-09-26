import SwiftUI

struct RootTabView: View {
    @Environment(AppModel.self) private var model

    var body: some View {
        TabView {
            ExercisesView()
                .tabItem { Label("Exercises", systemImage: "figure.strengthtraining.traditional") }
            FavouritesView()
                .tabItem { Label("Favourites", systemImage: "heart") }
            WorkoutsView()
                .tabItem { Label("Workouts", systemImage: "dumbbell") }
            LogsView()
                .tabItem { Label("Logs & Graphs", systemImage: "chart.line.uptrend.xyaxis") }
            SettingsView()
                .tabItem { Label("Settings", systemImage: "gearshape") }
        }
        .tint(Theme.chrome)
        .fullScreenCover(isPresented: .constant(model.session != nil)) {
            SessionView()
        }
    }
}
