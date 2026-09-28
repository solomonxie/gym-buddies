import SwiftUI
import GymBuddyCore

/// Train: the workout that's up next, big, then everything else.
struct WorkoutsView: View {
    @Environment(AppModel.self) private var model
    @State private var naming = false
    @State private var newName = ""

    /// Least recently done goes next — a rotation without asking for one.
    private var upNext: Workout? {
        model.workouts
            .filter { !$0.exercises.isEmpty }
            .min { ($0.lastPerformed ?? .distantPast) < ($1.lastPerformed ?? .distantPast) }
    }

    var body: some View {
        TabStack(.train) {
            Group {
                if model.workouts.isEmpty {
                    EmptyState(
                        title: "Nothing built yet",
                        message: "A workout is a list of exercises in the order you'll do them.",
                        systemImage: "dumbbell",
                        action: ("Build a workout", { naming = true })
                    )
                } else {
                    content
                }
            }
            .background(Theme.surface)
            .navigationTitle("Train")
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button { naming = true } label: { Image(systemName: "plus") }
                        .accessibilityLabel("New workout")
                }
            }
            .alert("New workout", isPresented: $naming) {
                TextField("Name", text: $newName)
                Button("Cancel", role: .cancel) { newName = "" }
                Button("Create") {
                    let name = newName.trimmingCharacters(in: .whitespaces)
                    model.createWorkout(named: name.isEmpty ? "Workout" : name)
                    newName = ""
                }
            }
        }
    }

    private var content: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 12) {
                if let session = model.session {
                    ResumeCard(session: session)
                } else if let next = upNext {
                    HeroCard(workout: next)
                }
                Text("Workouts")
                    .eyebrow()
                    .padding(.top, 12)
                    .padding(.leading, 4)
                ForEach(model.workouts) { workout in
                    WorkoutCard(workout: workout)
                }
            }
            .padding(.horizontal, Theme.Metrics.gutter)
            .padding(.bottom, 24)
        }
    }
}

extension AppModel {
    func minutes(for workout: Workout) -> Int {
        Stats.estimatedMinutes(workoutID: workout.id, logs: logs)
            ?? Stats.plannedMinutes(workout, defaultRest: settings.restBetweenSets)
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
                    Text("Up next").eyebrow()
                    Text(workout.name)
                        .font(.system(size: 30, weight: .bold, design: .rounded))
                        .foregroundStyle(.primary)
                        .lineLimit(2)
                    Text("\(workout.exercises.count) exercises · ~\(model.minutes(for: workout)) min · \(workout.lastPerformed.map { "last \(Dates.ago($0))" } ?? "never done")")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                    VStack(alignment: .leading, spacing: 4) {
                        ForEach(workout.exercises.prefix(4)) { line in
                            if let e = model.exercisesByID[line.exerciseID] {
                                HStack {
                                    Text(e.name).lineLimit(1)
                                    Spacer()
                                    Text(LoadFormat.line(line, exercise: e, unit: model.unit)).monospacedDigit()
                                        .foregroundStyle(.secondary)
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
