import GymBuddyCore
import SwiftUI

struct RootTabView: View {
    @Environment(AppModel.self) private var model

    var body: some View {
        @Bindable var model = model
        TabView(selection: $model.tab) {
            WorkoutsView()
                .miniSessionBar()
                .tabItem { Label("Train", systemImage: "figure.strengthtraining.traditional") }
                .tag(AppTab.train)
            ExercisesView()
                .miniSessionBar()
                .tabItem { Label("Exercises", systemImage: "dumbbell") }
                .tag(AppTab.exercises)
            LogsView()
                .miniSessionBar()
                .tabItem { Label("Progress", systemImage: "chart.bar.xaxis") }
                .tag(AppTab.progress)
            SettingsView()
                .miniSessionBar()
                .tabItem { Label("Settings", systemImage: "gearshape") }
                .tag(AppTab.settings)
        }
        .tint(Theme.accent)
        .fullScreenCover(isPresented: $model.isSessionPresented) {
            SessionView()
        }
    }
}
/// The database couldn't be opened. One screen, one way out — never a
/// silent empty list pretending you have no history.
struct DatabaseErrorView: View {
    let message: String
    @State private var importing = false
    @State private var failure: String?

    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: "externaldrive.badge.exclamationmark")
                .font(.system(size: 48))
                .foregroundStyle(.secondary)
            Text("Your data couldn't be opened")
                .font(.title3.bold())
            Text("Restore from a backup to carry on. The file you export from Settings → Export… is the backup.")
                .multilineTextAlignment(.center)
                .foregroundStyle(.secondary)
            Text(message)
                .font(.caption.monospaced())
                .foregroundStyle(.tertiary)
            Button("Restore from a backup…") { importing = true }
                .buttonStyle(.borderedProminent)
                .controlSize(.large)
            if let failure {
                Text(failure).foregroundStyle(.red).font(.footnote)
            }
        }
        .padding(32)
        .fileImporter(isPresented: $importing, allowedContentTypes: [.data, .item]) { result in
            guard case .success(let url) = result else { return }
            let scoped = url.startAccessingSecurityScopedResource()
            defer { if scoped { url.stopAccessingSecurityScopedResource() } }
            do {
                _ = try SQLiteStore.inspect(url)
                let target = AppModel.databaseURL
                try? FileManager.default.removeItem(at: target)
                try FileManager.default.copyItem(at: url, to: target)
                failure = "Restored. Close and reopen Gym Buddy."
            } catch {
                failure = String(describing: error)
            }
        }
    }
}
