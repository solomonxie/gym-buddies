import SwiftUI
import UserNotifications

@main
struct GymBuddyApp: App {
    @State private var model = AppModel.launch()
    private let presenter = NotificationPresenter()

    init() {
        UNUserNotificationCenter.current().delegate = presenter
    }

    var body: some Scene {
        WindowGroup {
            Group {
                if let error = model.loadError {
                    DatabaseErrorView(message: error)
                } else {
                    RootView()
                }
            }
            .environment(model)
        }
    }
}

extension AppModel {
    static func launch() -> AppModel {
        #if DEBUG
        if let demo = DemoData.modelIfRequested() { return demo }
        #endif
        return AppModel()
    }
}
