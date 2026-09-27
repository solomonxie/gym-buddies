import SwiftUI
import GymBuddyCore

struct WorkoutDetailView: View {
    let workoutID: String
    @Environment(AppModel.self) private var model
    @Environment(\.dismiss) private var dismiss
    @State private var expanded: String?
    @State private var renaming = false
    @State private var newName = ""
    @State private var confirmingDelete = false

    var body: some View {
        if let workout = model.workout(id: workoutID) {
            content(workout)
        } else {
            ContentUnavailableView("Workout deleted", systemImage: "trash")
        }
    }

    private func content(_ workout: Workout) -> some View {
        List {
            Section {
                startButton(workout)
                    .listRowInsets(EdgeInsets())
                    .listRowBackground(Color.clear)
            }
            Section {
                ForEach(workout.exercises) { line in
                    if let exercise = model.exercisesByID[line.exerciseID] {
                        LineRow(workoutID: workout.id, line: line, exercise: exercise, expanded: $expanded)
                    }
                }
                .onMove { from, to in
                    var updated = workout
                    updated.exercises.move(fromOffsets: from, toOffset: to)
                    model.saveWorkout(updated)
                }
                .onDelete { offsets in
                    var updated = workout
                    updated.exercises.remove(atOffsets: offsets)
                    model.saveWorkout(updated)
                }
                NavigationLink(value: Route.addExercises(workout.id)) {
                    Label("Add exercises", systemImage: "plus.circle.fill")
                        .foregroundStyle(Theme.accent)
                        .font(.body.weight(.semibold))
                }
            } header: {
                Text(summary(workout)).eyebrow()
            } footer: {
                if workout.exercises.count > 1 {
                    Text("Tap to edit · hold and drag ☰ to reorder")
                }
            }
        }
        .navigationTitle(workout.name)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItemGroup(placement: .primaryAction) {
                Menu {
                    Button("Rename", systemImage: "pencil") {
                        newName = workout.name
                        renaming = true
                    }
                    Button("Duplicate", systemImage: "plus.square.on.square") { model.duplicate(workout) }
                    ShareLink(item: exportText(workout)) { Label("Export…", systemImage: "square.and.arrow.up") }
                    Divider()
                    Button("Delete", systemImage: "trash", role: .destructive) { confirmingDelete = true }
                } label: {
                    Image(systemName: "ellipsis.circle")
                }
                .accessibilityLabel("More")
                NavigationLink(value: Route.addExercises(workout.id)) {
                    Image(systemName: "plus")
                }
                .accessibilityLabel("Add exercises")
            }
        }
        .alert("Rename", isPresented: $renaming) {
            TextField("Name", text: $newName)
            Button("Cancel", role: .cancel) {}
            Button("Save") {
                var updated = workout
                let name = newName.trimmingCharacters(in: .whitespaces)
                if !name.isEmpty { updated.name = name }
                model.saveWorkout(updated)
            }
        }
        .alert("Delete “\(workout.name)”?", isPresented: $confirmingDelete) {
            Button("Cancel", role: .cancel) {}
            Button("Delete", role: .destructive) {
                dismiss()
                model.deleteWorkout(workout)
            }
        } message: {
            let n = model.sessionCount(for: workout.id)
            Text(n == 0 ? "It has never been done, so no history is affected." : "The \(n) session\(n == 1 ? "" : "s") you logged from it \(n == 1 ? "is" : "are") kept.")
        }
    }

    @ViewBuilder
    private func startButton(_ workout: Workout) -> some View {
        if let session = model.session, session.workoutID == workout.id {
            ResumeButton(session: session)
        } else {
            VStack(spacing: 6) {
                Button { model.start(workout) } label: {
                    Label("Start workout", systemImage: "play.fill")
                }
                .buttonStyle(PrimaryButtonStyle())
                .disabled(workout.exercises.isEmpty || model.session != nil)
                if workout.exercises.isEmpty {
                    Text("Add an exercise to start.").font(.footnote).foregroundStyle(.secondary)
                } else if let other = model.session {
                    Text("“\(other.workoutName)” is still running.").font(.footnote).foregroundStyle(.secondary)
                }
            }
        }
    }

    private func summary(_ w: Workout) -> String {
        let sets = w.exercises.reduce(0) { $0 + $1.targetSets }
        let minutes = Stats.estimatedMinutes(workoutID: w.id, logs: model.logs)
            ?? Stats.plannedMinutes(w, defaultRest: model.settings.restBetweenSets)
        return "\(w.exercises.count) exercise\(w.exercises.count == 1 ? "" : "s") · ~\(minutes) min · \(sets) sets"
    }

    private func exportText(_ w: Workout) -> String {
        ([w.name] + w.exercises.compactMap { line in
            model.exercisesByID[line.exerciseID].map { "\($0.name) — \(LoadFormat.line(line, exercise: $0, unit: model.unit))" }
        }).joined(separator: "\n")
    }
}

/// A plan line; tapping unfolds its editor in place — nothing is covered.
private struct LineRow: View {
    let workoutID: String
    let line: WorkoutExercise
    let exercise: Exercise
    @Binding var expanded: String?
    @Environment(AppModel.self) private var model

    private var isOpen: Bool { expanded == line.id }

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Button {
                withAnimation(.snappy) { expanded = isOpen ? nil : line.id }
            } label: {
                HStack(spacing: 12) {
                    GlyphTile(equipment: exercise.equipment, size: 36)
                    VStack(alignment: .leading, spacing: 2) {
                        Text(exercise.name).font(.body.weight(.medium)).foregroundStyle(.primary).lineLimit(1)
                        Text("\(exercise.muscleGroup.displayName) · \(LoadFormat.line(line, exercise: exercise, unit: model.unit))")
                            .font(.subheadline.monospacedDigit())
                            .foregroundStyle(.secondary)
                    }
                    Spacer()
                    Image(systemName: "line.3.horizontal")
                        .foregroundStyle(.tertiary)
                        .accessibilityHidden(true)
                }
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .accessibilityHint(isOpen ? "Closes the editor" : "Edit sets, reps, weight and rest")

            if isOpen { editor }
        }
        .padding(.vertical, 2)
    }

    private var editor: some View {
        VStack(spacing: 10) {
            LineStepper(title: "Sets", value: "\(line.targetSets)",
                        decrement: { update { $0.targetSets = max(1, $0.targetSets - 1) } },
                        increment: { update { $0.targetSets += 1 } },
                        canDecrement: line.targetSets > 1)
            LineStepper(title: exercise.measure.displayName, value: "\(line.targetReps)",
                        decrement: { update { $0.targetReps = max(1, $0.targetReps - exercise.repStep) } },
                        increment: { update { $0.targetReps += exercise.repStep } },
                        canDecrement: line.targetReps > 1)
            if exercise.equipment.isLoadable {
                let step = exercise.equipment.increment(in: model.unit)
                LineStepper(title: "Weight", value: LoadFormat.number(line.targetWeight.value(in: model.unit)),
                            detail: "\(model.unit.abbreviation), \(LoadFormat.weight(step, model.unit)) a tap",
                            decrement: { update { $0.targetWeight = exercise.equipment.stepped($0.targetWeight, by: -1, in: model.unit) } },
                            increment: { update { $0.targetWeight = exercise.equipment.stepped($0.targetWeight, by: 1, in: model.unit) } },
                            canDecrement: line.targetWeight.kilograms > 0)
            }
            if let step = exercise.equipment.inclineStep {
                LineStepper(title: "Incline", value: LoadFormat.incline(line.targetIncline ?? 0),
                            detail: "\(LoadFormat.incline(step)) a tap",
                            decrement: { update { $0.targetIncline = exercise.equipment.stepped(incline: $0.targetIncline ?? 0, by: -1) } },
                            increment: { update { $0.targetIncline = exercise.equipment.stepped(incline: $0.targetIncline ?? 0, by: 1) } },
                            canDecrement: (line.targetIncline ?? 0) > 0)
            }
            HStack {
                Text("Rest")
                Spacer()
                Picker("Rest", selection: Binding(
                    get: { line.restSeconds ?? 0 },
                    set: { value in update { $0.restSeconds = value == 0 ? nil : value } }
                )) {
                    Text("Default (\(model.settings.restBetweenSets)s)").tag(0)
                    ForEach(Settings.restChoices, id: \.self) { Text("\($0)s").tag($0) }
                }
                .pickerStyle(.menu)
            }
            Button("Remove", role: .destructive) {
                guard var w = model.workout(id: workoutID) else { return }
                w.exercises.removeAll { $0.id == line.id }
                model.saveWorkout(w)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .buttonStyle(.borderless)
        }
        .padding(12)
        .background(RoundedRectangle(cornerRadius: Theme.Metrics.smallCorner, style: .continuous).fill(Theme.fill))
    }

    private func update(_ change: (inout WorkoutExercise) -> Void) {
        guard var w = model.workout(id: workoutID),
              let i = w.exercises.firstIndex(where: { $0.id == line.id }) else { return }
        change(&w.exercises[i])
        model.saveWorkout(w)
    }
}
