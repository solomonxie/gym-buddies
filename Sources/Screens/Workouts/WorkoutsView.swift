import SwiftUI
import GymBuddyCore

/// Train: the workout that's up next, big, then everything else. The app's
/// only root — progress, the library, gyms and settings are pushed from it.
struct WorkoutsView: View {
    @Environment(AppModel.self) private var model
    @State private var creating = false

    /// The workout done most recently; falls back to the first one if none has been done.
    private var lastUsed: Workout? {
        let usable = model.workouts.filter { !$0.exercises.isEmpty }
        return usable.filter { $0.lastPerformed != nil }
            .max { $0.lastPerformed! < $1.lastPerformed! } ?? usable.first
    }

    var body: some View {
        Group {
            if model.workouts.isEmpty {
                VStack {
                    EmptyState(
                        title: "Nothing built yet",
                        message: "A workout is a list of exercises in the order you'll do them.",
                        systemImage: "dumbbell",
                        action: ("Build a workout", { creating = true })
                    )
                    VStack(spacing: 12) {
                        PlacesRow()
                        SettingsRow()
                    }
                    .padding(.horizontal, Theme.Metrics.gutter)
                    .padding(.bottom, 24)
                }
            } else {
                content
            }
        }
        .background(Theme.surface)
        .navigationTitle("Gym Buddies")
        .sheet(isPresented: $creating) {
            NewWorkoutSheet()
        }
    }

    private var content: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 12) {
                if let session = model.session {
                    ResumeCard(session: session)
                } else if let last = lastUsed {
                    HeroCard(workout: last)
                }
                PlacesRow()
                if !model.logs.isEmpty {
                    ProgressSummary()
                }
                HStack {
                    Text("Workouts").eyebrow()
                    Spacer()
                    Button { creating = true } label: {
                        Image(systemName: "plus")
                            .font(.body.weight(.semibold))
                            .frame(width: 44, height: 44)
                    }
                    .accessibilityLabel("New workout")
                }
                .padding(.top, 4)
                .padding(.leading, 4)
                ForEach(model.workouts) { workout in
                    WorkoutCard(workout: workout)
                }
                SettingsRow()
                    .padding(.top, 12)
            }
            .padding(.horizontal, Theme.Metrics.gutter)
            .padding(.bottom, 24)
        }
    }
}

extension AppModel {
    func minutes(for workout: Workout) -> Int {
        Stats.estimatedMinutes(workoutID: workout.id, logs: logs)
            ?? Stats.plannedMinutes(workout, defaultRest: settings.restBetweenSets, exercises: exercisesByID)
    }
}

/// The last 30 days at a glance; the rest is one tap away.
private struct ProgressSummary: View {
    @Environment(AppModel.self) private var model

    var body: some View {
        let recent = Stats.logs(model.logs, since: TrendRange.days30.start)
        let minutes = Int(recent.reduce(0) { $0 + $1.duration } / 60)
        NavigationLink(value: Route.progress) {
            VStack(alignment: .leading, spacing: 14) {
                HStack {
                    Text("Progress · last 30 days").eyebrow()
                    Spacer()
                    Image(systemName: "chevron.right")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(.tertiary)
                }
                WeekDots(days: Stats.weekDots(model.logs, asOf: .now))
                HStack(alignment: .firstTextBaseline) {
                    figure("\(recent.count)", "sessions")
                    figure(StatFormat.compact(Stats.volume(recent.flatMap(\.sets)).value(in: model.unit)), "\(model.unit.abbreviation) moved")
                    figure(StatFormat.hours(minutes), "time")
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .card(padding: 16)
    }

    private func figure(_ value: String, _ label: String) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(value).font(.tabular(20, weight: .bold)).foregroundStyle(.primary)
            Text(label).font(.footnote).foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

/// Exercises and Gyms: looked up now and then, so a tile each, not a tab.
private struct PlacesRow: View {
    @Environment(AppModel.self) private var model

    var body: some View {
        HStack(spacing: 12) {
            PlaceTile(title: "Exercises", systemImage: "dumbbell", route: .exercises) {
                Text("\(model.exercises.count)")
            }
            PlaceTile(title: "Gyms", systemImage: "building.2", route: .gyms) {
                TimelineView(.periodic(from: .now, by: 60)) { context in
                    let open = Gym.sorted(model.gyms, leaving: context.date).filter(\.availability.isOpen).count
                    Text(model.gyms.isEmpty ? "none yet" : "\(open) open now")
                }
            }
        }
    }
}

private struct SettingsRow: View {
    var body: some View {
        NavigationLink(value: Route.settings) {
            HStack(spacing: 12) {
                Image(systemName: "gearshape").foregroundStyle(.secondary)
                Text("Settings").foregroundStyle(.primary)
                Spacer()
                Image(systemName: "chevron.right")
                    .font(.footnote.weight(.semibold))
                    .foregroundStyle(.tertiary)
            }
            .frame(minHeight: 44)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .card(padding: 16)
    }
}

private struct PlaceTile<Detail: View>: View {
    let title: String
    let systemImage: String
    let route: Route
    @ViewBuilder var detail: () -> Detail

    var body: some View {
        NavigationLink(value: route) {
            VStack(alignment: .leading, spacing: 6) {
                Image(systemName: systemImage)
                    .font(.title3)
                    .foregroundStyle(Theme.accent)
                Text(title).font(.headline).foregroundStyle(.primary)
                detail()
                    .font(.subheadline.monospacedDigit())
                    .foregroundStyle(.secondary)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .card(padding: 16)
    }
}

/// The one thing most people open the app to do.
private struct HeroCard: View {
    let workout: Workout
    @Environment(AppModel.self) private var model

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            NavigationLink(value: Route.workout(workout.id)) {
                VStack(alignment: .leading, spacing: 6) {
                    HStack(alignment: .firstTextBaseline) {
                        Text("Last workout").eyebrow()
                        Spacer()
                        Text(workout.lastPerformed.map { "Last \(Dates.ago($0))" } ?? "Never done")
                            .font(.footnote)
                            .foregroundStyle(.secondary)
                            .lineLimit(1)
                    }
                    Text(workout.name)
                        .font(.system(size: 30, weight: .bold, design: .rounded))
                        .foregroundStyle(.primary)
                        .lineLimit(2)
                    Text("\(workout.exercises.count) exercises · ~\(model.minutes(for: workout)) min")
                        .font(.subheadline.monospacedDigit())
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                    VStack(alignment: .leading, spacing: 4) {
                        ForEach(workout.exercises.prefix(4)) { line in
                            if let e = model.exercisesByID[line.exerciseID] {
                                HStack {
                                    Text(e.name).lineLimit(1)
                                    Spacer()
                                    Text(LoadFormat.line(line, exercise: e, unit: model.unit)).monospacedDigit()
                                        .foregroundStyle(.secondary)
                                        .lineLimit(1)
                                        .layoutPriority(1)
                                }
                                .font(.subheadline)
                                .foregroundStyle(.primary)
                            }
                        }
                        if workout.exercises.count > 4 {
                            Text("+ \(workout.exercises.count - 4) more").font(.subheadline).foregroundStyle(.secondary)
                        }
                    }
                    .padding(.top, 8)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            Button { model.start(workout) } label: {
                Label("Start", systemImage: "play.fill")
            }
            .buttonStyle(PrimaryButtonStyle())
            .accessibilityLabel("Start \(workout.name)")
        }
        .card(padding: 20)
    }
}

struct ResumeCard: View {
    let session: WorkoutSession
    @Environment(AppModel.self) private var model

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            VStack(alignment: .leading, spacing: 6) {
                Text("In progress").eyebrow()
                Text(session.workoutName)
                    .font(.system(size: 30, weight: .bold, design: .rounded))
                TimelineView(.periodic(from: .now, by: 1)) { context in
                    Text("\(session.logs.count) set\(session.logs.count == 1 ? "" : "s") logged · \(RestTimer.format(session.elapsed(at: context.date)))")
                        .font(.subheadline.monospacedDigit())
                        .foregroundStyle(.secondary)
                }
            }
            ResumeButton(session: session)
        }
        .card(padding: 20)
    }
}

struct ResumeButton: View {
    let session: WorkoutSession
    @Environment(AppModel.self) private var model

    var body: some View {
        Button { model.resume() } label: {
            Label("Resume", systemImage: "arrow.uturn.forward")
        }
        .buttonStyle(PrimaryButtonStyle())
        .accessibilityLabel("Resume \(session.workoutName)")
    }
}

struct WorkoutCard: View {
    let workout: Workout
    @Environment(AppModel.self) private var model

    private var blocked: Bool {
        workout.exercises.isEmpty || (model.session != nil && model.session?.workoutID != workout.id)
    }

    var body: some View {
        HStack(spacing: 12) {
            NavigationLink(value: Route.workout(workout.id)) {
                VStack(alignment: .leading, spacing: 3) {
                    Text(workout.name)
                        .font(.headline)
                        .foregroundStyle(.primary)
                        .lineLimit(1)
                    Text("\(workout.exercises.count) exercise\(workout.exercises.count == 1 ? "" : "s") · ~\(model.minutes(for: workout)) min")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                    Text(workout.lastPerformed.map { "Last done \(Dates.ago($0))" } ?? "Never done")
                        .font(.footnote)
                        .foregroundStyle(.tertiary)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            Button { model.start(workout) } label: {
                Image(systemName: "play.fill")
                    .font(.body.weight(.bold))
                    .foregroundStyle(blocked ? Color.secondary : Theme.accent)
                    .frame(width: 48, height: 48)
                    .background(Circle().fill(blocked ? Theme.fill : Theme.accentSoft))
            }
            .disabled(blocked)
            .accessibilityLabel("Start \(workout.name)")
        }
        .card(padding: 16)
    }
}
