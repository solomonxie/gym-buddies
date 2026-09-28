import SwiftUI
import UniformTypeIdentifiers
import GymBuddyCore

struct SettingsView: View {
    @Environment(AppModel.self) private var model
    @Environment(\.scenePhase) private var scenePhase
    @State private var pendingUnit: WeightUnit?
    @State private var openRest: RestKind?
    @State private var notificationsDenied = false
    @State private var exported: ExportedFile?
    @State private var importing = false
    @State private var incoming: (url: URL, summary: BackupSummary)?
    @State private var failure: String?

    enum RestKind { case sets, exercises }

    var body: some View {
        @Bindable var model = model
        Form {
            units
            rest
            Section("During a workout") {
                Toggle("Keep the screen awake", isOn: $model.settings.keepScreenAwake)
                Toggle("Suggest heavier weights", isOn: $model.settings.suggestHeavier)
                Toggle("Count down the last 3 seconds", isOn: $model.settings.countdownLastSeconds)
                    .disabled(!model.settings.vibrate)
            }
            backups
            data
            Section {
                NavigationLink("About") { AboutView() }
            } footer: {
                Text("Gym Buddy \(Bundle.main.version) · no ads, no account, nothing leaves this phone unless you send it")
            }
        }
        .navigationTitle("Settings")
        .task(id: scenePhase) { notificationsDenied = await RestAlerts.isDenied() }
        .confirmationDialog(
            "Show weights in \(pendingUnit == .kilograms ? "kilograms" : "pounds")?",
            isPresented: Binding(get: { pendingUnit != nil }, set: { if !$0 { pendingUnit = nil } }),
            titleVisibility: .visible
        ) {
            Button("Use \(pendingUnit?.abbreviation ?? "")") {
                if let unit = pendingUnit { model.settings.unit = unit }
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("Every logged set is converted for display. Nothing is rewritten — your history is stored in kilograms already.")
        }
        .sheet(item: $exported) { file in
            ShareSheet(url: file.url)
        }
        .fileImporter(isPresented: $importing, allowedContentTypes: [.data, .item]) { result in
            inspect(result)
        }
        .alert("Replace everything?", isPresented: Binding(get: { incoming != nil }, set: { if !$0 { incoming = nil } })) {
            Button("Cancel", role: .cancel) {}
            Button("Replace", role: .destructive) { replace() }
        } message: {
            if let summary = incoming?.summary {
                Text("This backup has \(summary.sessions) sessions and \(summary.workouts) workouts. Your current \(model.logs.count) and \(model.workouts.count) are overwritten.")
            }
        }
        .alert("Couldn't do that", isPresented: Binding(get: { failure != nil }, set: { if !$0 { failure = nil } })) {
            Button("OK") {}
        } message: {
            Text(failure ?? "")
        }
    }

    // MARK: - Sections

    private var units: some View {
        Section {
            HStack {
                Text("Weight")
                Spacer()
                Picker("Weight", selection: Binding(
                    get: { model.settings.unit },
                    set: { if $0 != model.settings.unit { pendingUnit = $0 } }
                )) {
                    Text("KG").tag(WeightUnit.kilograms)
                    Text("LB").tag(WeightUnit.pounds)
                }
                .pickerStyle(.segmented)
                .frame(width: 140)
                .disabled(model.session != nil)
            }
        } header: {
            Text("Units")
        } footer: {
            if model.session != nil { Text("Finish the workout first.") }
        }
    }

    private var rest: some View {
        @Bindable var model = model
        return Section {
            if notificationsDenied && model.settings.alertWhenRestOver {
                VStack(alignment: .leading, spacing: 8) {
                    Label("Alerts are off in iOS Settings, so rest will only show on screen.", systemImage: "exclamationmark.triangle")
                        .font(.subheadline)
                    Button("Open Settings") {
                        if let url = URL(string: UIApplication.openNotificationSettingsURLString) {
                            UIApplication.shared.open(url)
                        }
                    }
                }
            }
            restRow("Between sets", kind: .sets, value: $model.settings.restBetweenSets)
            restRow("Between exercises", kind: .exercises, value: $model.settings.restBetweenExercises)
            Toggle("Alert when rest or time is up", isOn: $model.settings.alertWhenRestOver)
                .onChange(of: model.settings.alertWhenRestOver) { _, on in
                    if on { RestAlerts.requestAuthorization() }
                }
            Toggle("Vibrate", isOn: $model.settings.vibrate)
        } header: {
            HStack(spacing: 2) {
                Text("Rest")
                InfoButton(text: "Rest starts on its own when you log a set, and the alert is a notification, so it still reaches you with the phone in a pocket and the screen locked. A workout with per-exercise rest set on a line uses that instead of these.")
            }
        }
    }

    /// Unfolds in place: the row stays put and the choices appear under it.
    @ViewBuilder
    private func restRow(_ title: String, kind: RestKind, value: Binding<Int>) -> some View {
        Button {
            withAnimation(.snappy) { openRest = openRest == kind ? nil : kind }
        } label: {
            LabeledContent(title) {
                HStack(spacing: 6) {
                    Text("\(value.wrappedValue)s").monospacedDigit()
                    Image(systemName: openRest == kind ? "chevron.down" : "chevron.right")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(.tertiary)
                }
            }
            .foregroundStyle(.primary)
        }
        if openRest == kind {
            VStack(alignment: .leading, spacing: 10) {
                HStack(spacing: 6) {
                    ForEach(Settings.restChoices, id: \.self) { seconds in
                        Button("\(seconds)") { value.wrappedValue = seconds }
                            .font(.subheadline.monospacedDigit().weight(.semibold))
                            .frame(maxWidth: .infinity, minHeight: 36)
                            .foregroundStyle(value.wrappedValue == seconds ? .white : .primary)
                            .background(RoundedRectangle(cornerRadius: 8)
                                .fill(value.wrappedValue == seconds ? Theme.accent : Theme.fill))
                            .buttonStyle(.plain)
                    }
                }
                Stepper("Custom: \(value.wrappedValue)s", value: value, in: 0...600, step: 5)
                    .monospacedDigit()
            }
        }
    }

    private var backups: some View {
        @Bindable var model = model
        return Section {
            NavigationLink {
                BackupsView()
            } label: {
                LabeledContent("On this phone") {
                    Text(model.settings.lastAutoBackup.map { $0.formatted(.relative(presentation: .named)) } ?? "after the next change")
                }
            }
            Toggle("Back up to iCloud", isOn: $model.settings.iCloudBackup)
                .onChange(of: model.settings.iCloudBackup) { _, on in
                    if on { model.backupSoon() }
                }
        } header: {
            HStack(spacing: 2) {
                Text("Automatic backups")
                InfoButton(text: "After every change, a copy of your data is saved on this phone — the newest 20 of each day, for 7 days. With iCloud on, one file a day also goes to iCloud Drive → Gym Buddy, replaced by each change that day and kept for 30 days. It's your own iCloud; nothing passes through us.")
            }
        } footer: {
            if model.settings.iCloudBackup {
                if model.iCloudUnavailable || !AutoBackup.isICloudSignedIn {
                    Text("iCloud isn't available. Sign in to iCloud with iCloud Drive on, in iOS Settings.")
                        .foregroundStyle(.orange)
                } else if let date = model.settings.lastICloudBackup {
                    Text("Last saved to iCloud \(date.formatted(.relative(presentation: .named))).")
                }
            }
        }
    }

    private var data: some View {
        Section {
            NavigationLink(value: Route.exercises) {
                LabeledContent("Exercises") { Text("\(model.exercises.count)").monospacedDigit() }
            }
            LabeledContent("Workouts") { Text("\(model.workouts.count)").monospacedDigit() }
            NavigationLink(value: Route.progress) {
                LabeledContent("Sessions logged") { Text("\(model.logs.count)").monospacedDigit() }
            }
            LabeledContent("Last export") {
                if let date = model.settings.lastBackup {
                    Text("\(date.formatted(date: .abbreviated, time: .omitted)) · \(ByteCountFormatter.string(fromByteCount: Int64(model.settings.lastBackupBytes ?? 0), countStyle: .file))")
                } else {
                    Text("never")
                }
            }
            if model.settings.lastBackup == nil && !model.settings.iCloudBackup && !model.logs.isEmpty {
                Text("Only this phone has a copy. Turn on iCloud backup or export one.")
                    .font(.subheadline).foregroundStyle(.orange)
            }
            HStack(spacing: 12) {
                Button("Export…") { export() }
                    .frame(maxWidth: .infinity)
                Button("Import…") { importing = true }
                    .frame(maxWidth: .infinity)
                    .disabled(model.session != nil)
            }
            .buttonStyle(.bordered)
            .controlSize(.large)
        } header: {
            HStack(spacing: 2) {
                Text("Your data")
                InfoButton(text: "Everything is one SQLite file on this phone. There is no account and no server, so an iCloud backup or an exported file is the only copy that survives losing the device.")
            }
        }
    }

    // MARK: - Backup

    private func export() {
        do { exported = ExportedFile(url: try model.exportBackup()) }
        catch { failure = String(describing: error) }
    }

    private func inspect(_ result: Result<URL, Error>) {
        guard case .success(let picked) = result else { return }
        let scoped = picked.startAccessingSecurityScopedResource()
        defer { if scoped { picked.stopAccessingSecurityScopedResource() } }
        do {
            let local = FileManager.default.temporaryDirectory.appending(path: "import-\(UUID().uuidString).sqlite")
            try FileManager.default.copyItem(at: picked, to: local)
            incoming = (local, try SQLiteStore.inspect(local))
        } catch {
            failure = "That file isn't a Gym Buddy backup."
        }
    }

    private func replace() {
        guard let url = incoming?.url else { return }
        do { try model.importBackup(from: url) }
        catch { failure = String(describing: error) }
    }
}

private struct ExportedFile: Identifiable {
    let url: URL
    var id: URL { url }
}

/// The system share sheet for one file.
struct ShareSheet: UIViewControllerRepresentable {
    let url: URL

    func makeUIViewController(context: Context) -> UIActivityViewController {
        UIActivityViewController(activityItems: [url], applicationActivities: nil)
    }

    func updateUIViewController(_ controller: UIActivityViewController, context: Context) {}
}

struct AboutView: View {
    var body: some View {
        List {
            Section {
                LabeledContent("Version", value: Bundle.main.version)
                Text("No ads, no account, no analytics. Nothing leaves this phone unless you export it or turn on iCloud backup — and then only to your own iCloud.")
            }
            Section("Not a coach") {
                Text("Weight suggestions are double progression: hit every rep on every set and the next session offers one step heavier; miss twice running and it offers one step lighter. It's always a question, never a change made for you. Anything smarter would need effort ratings or bar speed, which this app doesn't ask for.")
            }
            Section("Illustrations") {
                Text("Muscle maps and equipment symbols are drawn in code and with SF Symbols. How-to steps appear only where they've been reviewed; the rest are left blank rather than guessed.")
            }
            Section("Licences") {
                Text("Built with Apple frameworks only: SwiftUI, Swift Charts, UserNotifications and SQLite. No third-party code.")
            }
        }
        .navigationTitle("About")
    }
}

extension Bundle {
    var version: String {
        let short = infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0"
        let build = infoDictionary?["CFBundleVersion"] as? String ?? "1"
        return "\(short) (\(build))"
    }
}

/// Local snapshots, newest first, grouped by day. Tap one to restore it.
struct BackupsView: View {
    @Environment(AppModel.self) private var model
    @State private var items: [(url: URL, date: Date, bytes: Int)] = []
    @State private var picked: (url: URL, date: Date, summary: BackupSummary)?
    @State private var failure: String?

    private var days: [(day: Date, items: [(url: URL, date: Date, bytes: Int)])] {
        let grouped = Dictionary(grouping: items) { Calendar.current.startOfDay(for: $0.date) }
        return grouped.keys.sorted(by: >).map { ($0, grouped[$0]!) }
    }

    var body: some View {
        List {
            Section {
                Text("A copy is saved after every change: the newest 20 of each day, for the last 7 days. Restoring one saves what's here now first, so it can be undone.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
            if items.isEmpty {
                Text("No backups yet — one is saved a few seconds after your next change.")
                    .foregroundStyle(.secondary)
            }
            ForEach(days, id: \.day) { day in
                Section(day.day.formatted(.dateTime.weekday(.wide).day().month(.wide))) {
                    ForEach(day.items, id: \.url) { item in
                        Button { inspect(item) } label: {
                            LabeledContent {
                                Text(ByteCountFormatter.string(fromByteCount: Int64(item.bytes), countStyle: .file))
                            } label: {
                                Text(item.date.formatted(date: .omitted, time: .standard))
                                    .foregroundStyle(.primary)
                                    .monospacedDigit()
                            }
                        }
                        .disabled(model.session != nil)
                    }
                }
            }
        }
        .navigationTitle("Backups")
        .onAppear { items = AutoBackup.localBackups() }
        .alert("Restore this backup?", isPresented: Binding(get: { picked != nil }, set: { if !$0 { picked = nil } })) {
            Button("Cancel", role: .cancel) {}
            Button("Restore", role: .destructive) { restore() }
        } message: {
            if let picked {
                Text("From \(picked.date.formatted(date: .abbreviated, time: .standard)): \(picked.summary.sessions) sessions and \(picked.summary.workouts) workouts. What's here now is saved as a backup first.")
            }
        }
        .alert("Couldn't restore", isPresented: Binding(get: { failure != nil }, set: { if !$0 { failure = nil } })) {
            Button("OK") {}
        } message: {
            Text(failure ?? "")
        }
    }

    private func inspect(_ item: (url: URL, date: Date, bytes: Int)) {
        do { picked = (item.url, item.date, try SQLiteStore.inspect(item.url)) }
        catch { failure = String(describing: error) }
    }

    private func restore() {
        guard let picked else { return }
        do {
            try model.importBackup(from: picked.url)
            items = AutoBackup.localBackups()
        } catch {
            failure = String(describing: error)
        }
    }
}
