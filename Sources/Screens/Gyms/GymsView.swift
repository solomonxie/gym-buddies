import SwiftUI
import GymBuddyCore

/// Where can I go: open on arrival first, now or at a picked time.
struct GymsView: View {
    @Environment(AppModel.self) private var model
    @State private var picking = false
    @State private var picked = Date.now
    @State private var newGym: NewGym?

    private struct NewGym: Identifiable { let id: String }

    var body: some View {
        TabStack(.gyms) {
            TimelineView(.periodic(from: .now, by: 60)) { context in
                list(leaving: picking ? picked : context.date)
            }
            .navigationTitle("Gyms")
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button { newGym = NewGym(id: model.createGym().id) } label: { Image(systemName: "plus") }
                        .accessibilityLabel("New gym")
                }
            }
            .sheet(item: $newGym) { gym in
                NavigationStack {
                    GymEditorView(gymID: gym.id)
                        .withRoutes()
                        .toolbar {
                            ToolbarItem(placement: .confirmationAction) {
                                Button("Done") { newGym = nil }
                            }
                        }
                }
            }
        }
    }

    private func list(leaving: Date) -> some View {
        let rows = Gym.sorted(model.gyms, leaving: leaving)
        let open = rows.filter(\.availability.isOpen)
        let closed = rows.filter { !$0.availability.isOpen }
        return List {
            Section {
                Picker("When", selection: $picking) {
                    Text("Now").tag(false)
                    Text("Pick a time").tag(true)
                }
                .pickerStyle(.segmented)
                if picking {
                    DatePicker("Leaving", selection: $picked)
                }
            }
            Section {
                if open.isEmpty {
                    Text("Nothing's open then.").foregroundStyle(.secondary)
                }
                ForEach(open, id: \.gym.id) { row in GymRow(gym: row.gym, availability: row.availability) }
            } header: {
                Text("Open when you get there").eyebrow()
            } footer: {
                Text("Counts travel time: open means open on arrival.")
            }
            if !closed.isEmpty {
                Section {
                    ForEach(closed, id: \.gym.id) { row in GymRow(gym: row.gym, availability: row.availability) }
                } header: {
                    Text("Closed then").eyebrow()
                }
            }
        }
    }
}

private struct GymRow: View {
    let gym: Gym
    let availability: Availability

    var body: some View {
        NavigationLink(value: Route.gym(gym.id)) {
            VStack(alignment: .leading, spacing: 3) {
                HStack {
                    Text(gym.name).font(.headline).lineLimit(1)
                    if gym.isHome {
                        Text("Home")
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(Theme.accent)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(Capsule().fill(Theme.accentSoft))
                    }
                }
                Text(GymText.line(gym, availability))
                    .font(.subheadline.monospacedDigit())
                    .foregroundStyle(availability.isOpen ? .secondary : .tertiary)
            }
            .padding(.vertical, 2)
        }
    }
}

enum GymText {
    /// `Open till 22:00 · 15 min · $45/month`.
    static func line(_ gym: Gym, _ availability: Availability) -> String {
        var parts = [status(availability)]
        parts.append(gym.travelMinutes == 0 ? "on the spot" : "\(gym.travelMinutes) min")
        if let price = gym.price { parts.append(price.format()) }
        return parts.joined(separator: " · ")
    }

    static func status(_ a: Availability) -> String {
        switch a.status {
        case .open(nil):
            return "Open all day"
        case .open(let until?):
            if let left = a.minutesBeforeClose, left < 60 { return "Shuts \(left) min after you arrive" }
            return "Open till \(time(until))"
        case .closed(nil):
            return "No hours set"
        case .closed(let opens?):
            let sameDay = Calendar.current.isDate(opens, inSameDayAs: a.arrival)
            return "Opens \(sameDay ? "" : opens.formatted(.dateTime.weekday(.abbreviated)) + " ")\(time(opens))"
        }
    }

    static func time(_ date: Date) -> String {
        date.formatted(date: .omitted, time: .shortened)
    }
}
