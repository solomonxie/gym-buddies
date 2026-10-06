#if DEBUG
import Foundation
import GymBuddyCore

/// DEBUG launch hooks for QA and store screenshots. `-demo` opens Demo mode
/// freshly seeded (without turning it on for the next normal launch);
/// `-empty` an empty in-memory store; `-screen <name>` one screen, see `route`.
enum DemoData {
    static var arguments: [String] { ProcessInfo.processInfo.arguments }

    static var screen: String? {
        guard let i = arguments.firstIndex(of: "-screen"), i + 1 < arguments.count else { return nil }
        return arguments[i + 1]
    }

    @MainActor
    static func modelIfRequested() -> AppModel? {
        let model: AppModel
        if arguments.contains("-empty") {
            model = AppModel(store: MemoryStore(exercises: SeedLibrary.exercises))
        } else if arguments.contains("-demo") {
            model = AppModel(demo: true, resetDemo: true)
        } else {
            return nil
        }
        model.asksForNotifications = false
        if arguments.contains("-kg") { model.settings.unit = .kilograms }
        if screen != nil { route(model) }
        return model
    }

    @MainActor
    private static func route(_ model: AppModel) {
        model.discardSession()
        switch screen {
        case "treadmill":
            guard let workout = model.workout(id: "demo-full-body") else { return }
            model.start(workout, at: .now.addingTimeInterval(-7 * 60))
            model.startSet(at: .now.addingTimeInterval(-6 * 60 - 38))
        case "session", "resting", "summary", "jump", "progression", "set", "background":
            guard let workout = model.workout(id: "demo-full-body") else { return }
            model.start(workout, at: .now.addingTimeInterval(-14 * 60 - 22))
            model.updateSession { $0.skipExercise() }
            if screen == "progression" { return }
            model.updateSession { $0.markProgressionOffered(for: $0.currentEntry?.id ?? "") }
            if screen == "resting" || screen == "jump" {
                model.completeSets(1, at: .now.addingTimeInterval(-32))
            }
            if screen == "set" { model.startSet(at: .now.addingTimeInterval(-41)) }
            if screen == "background" {
                model.completeSets(1, at: .now.addingTimeInterval(-32))
                model.isSessionPresented = false
            }
            if screen == "summary" {
                model.updateSession { s in
                    while !s.isFinished {
                        if s.currentEntry?.exercise.id == "lat-pull-downs" && s.currentSetNumber == 1 { s.adjustWeight(by: 1, in: .pounds) }
                        s.completeSet(at: .now)
                    }
                }
                model.pendingSummary = model.session
            }
        default: model.path = path
        }
    }

    private static var path: [Route] {
        switch screen {
        case "exercises", "favourites": [.exercises]
        case "exercise": [.exercises, .exercise("lat-pull-downs")]
        case "gyms": [.gyms]
        case "gym": [.gyms, .gym("demo-downtown")]
        case "settings": [.settings]
        case "workout": [.workout("demo-full-body")]
        case "add": [.workout("demo-full-body"), .addExercises("demo-full-body")]
        case "logs": [.progress]
        case "log": [.progress, .log("demo-log-1")]
        case "trend": [.progress, .trend("lat-pull-downs")]
        default: []
        }
    }
}
#endif
