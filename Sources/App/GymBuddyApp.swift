import SwiftUI

@main
struct GymBuddyApp: App {
    @State private var model = AppModel()

    var body: some Scene {
        WindowGroup {
            RootTabView()
                .environment(model)
        }
    }
}
