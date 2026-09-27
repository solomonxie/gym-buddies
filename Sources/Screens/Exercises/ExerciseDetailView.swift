import SwiftUI
import GymBuddyCore

struct ExerciseDetailView: View {
    let exerciseID: String
    @Environment(AppModel.self) private var model
    @Environment(\.dismiss) private var dismiss
    @AppStorage("detailMetric") private var metricRaw = Stats.Metric.topWeight.rawValue
    @State private var editing = false
    @State private var confirmingReset = false
    @State private var confirmingDelete = false
    @State private var addingToWorkout = false

    private var metric: Stats.Metric { Stats.Metric(rawValue: metricRaw) ?? .topWeight }

    var body: some View {
        if let exercise = model.exercisesByID[exerciseID] {
            content(exercise)
        } else {
            ContentUnavailableView("Exercise removed", systemImage: "trash")
        }
    }

    private func content(_ exercise: Exercise) -> some View {
        let sets = model.logs.flatMap(\.sets).filter { $0.exerciseID == exercise.id }
        let best = Stats.personalRecord(exerciseID: exercise.id, in: sets)
        let last = Stats.lastSession(exerciseID: exercise.id, in: model.logs)
        let usedIn = Stats.workouts(using: exercise.id, in: model.workouts)

        return List {
            Section {
                ExerciseArt(exercise: exercise)
                    .listRowInsets(EdgeInsets())
                Text(subtitle(exercise))
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }

            Section {
                LabeledContent("Your best") {
                    Text(best.map { bestText($0, exercise) } ?? "—").font(.tabular(17, weight: .semibold))
                }
                if let last {
                    NavigationLink(value: Route.log(last.id)) {
                        LabeledContent("Last done", value: lastText(last, exercise))
                    }
                } else {
                    LabeledContent("Last done", value: "—")
                }
            }

            Section {
                Picker("Metric", selection: $metricRaw) {
                    ForEach(Stats.Metric.allCases) { Text($0.displayName).tag($0.rawValue) }
                }
                .pickerStyle(.segmented)
                TrendChart(
                    points: Stats.series(exerciseID: exercise.id, metric: metric, from: model.logs, in: model.unit),
                    metric: metric, unit: model.unit, height: 180
                )
                if !sets.isEmpty {
                    NavigationLink("Every session", value: Route.trend(exercise.id))
                }
            }

            if !exercise.steps.isEmpty {
                Section("How to") {
                    ForEach(Array(exercise.steps.enumerated()), id: \.offset) { index, step in
                        HStack(alignment: .firstTextBaseline, spacing: 10) {
                            Text("\(index + 1).").font(.body.monospacedDigit()).foregroundStyle(.secondary)
                            Text(step)
                        }
                    }
                }
            }

            if !usedIn.isEmpty {
                Section("In \(usedIn.count) workout\(usedIn.count == 1 ? "" : "s")") {
                    ForEach(usedIn) { workout in
                        NavigationLink(value: Route.workout(workout.id)) {
                            LabeledContent(workout.name, value: planText(workout, exercise))
                        }
                    }
                }
            }
        }
        .navigationTitle(exercise.name)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItemGroup(placement: .primaryAction) {
                Button { model.toggleFavourite(exercise) } label: {
                    Image(systemName: exercise.isFavourite ? "heart.fill" : "heart")
                        .foregroundStyle(Theme.accent)
                }
                .accessibilityLabel(exercise.isFavourite ? "Remove from favourites" : "Add to favourites")
                Menu {
                    if exercise.isCustom {
                        Button("Edit", systemImage: "pencil") { editing = true }
                    }
                    Button("Add to workout…", systemImage: "text.badge.plus") { addingToWorkout = true }
                    Button("Reset history", systemImage: "arrow.counterclockwise", role: .destructive) {
                        confirmingReset = true
                    }
                    .disabled(sets.isEmpty)
                    if exercise.isCustom {
                        Button("Delete exercise", systemImage: "trash", role: .destructive) { confirmingDelete = true }
                    }
                } label: {
                    Image(systemName: "ellipsis.circle")
                }
                .accessibilityLabel("More")
            }
        }
        .sheet(isPresented: $editing) { ExerciseEditorView(exercise: exercise) }
        .confirmationDialog("Add to…", isPresented: $addingToWorkout) {
            ForEach(model.workouts) { w in
                Button(w.name) { model.add([exercise.id], to: w.id) }
            }
        }
        .alert("Reset history for \(exercise.name)?", isPresented: $confirmingReset) {
            Button("Cancel", role: .cancel) {}
            Button("Reset", role: .destructive) { model.resetHistory(of: exercise) }
        } message: {
            Text("\(sets.count) logged sets are removed. The sessions they were in are kept.")
        }
        .alert("Delete \(exercise.name)?", isPresented: $confirmingDelete) {
            Button("Cancel", role: .cancel) {}
            Button("Delete", role: .destructive) {
                dismiss()
                model.deleteCustomExercise(exercise)
            }
        } message: {
            Text("It's removed from your workouts. Sets already logged stay in your history.")
        }
    }

    /// `Back · Machine · 10 lb a pin` — what `+` will do, before you press it.
    private func subtitle(_ e: Exercise) -> String {
        var parts = [e.muscleGroup.displayName, e.equipment.displayName]
        if e.equipment.isLoadable {
            parts.append("\(LoadFormat.weight(e.equipment.increment(in: model.unit), model.unit)) a step")
        } else if let step = e.equipment.inclineStep {
            parts.append("\(LoadFormat.incline(step)) incline a step")
        }
        if e.measure != .reps { parts.append("in \(e.measure.displayName.lowercased())") }
        if e.isCustom { parts.append("yours") }
        return parts.joined(separator: " · ")
    }

    private func bestText(_ set: SetLog, _ e: Exercise) -> String {
        bestSetText(set, e, unit: model.unit)
    }

    private func lastText(_ log: WorkoutLog, _ e: Exercise) -> String {
        let sets = log.sets.filter { $0.exerciseID == e.id }
        let ago = Dates.ago(log.startedAt)
        guard let load = LoadFormat.load(weight: sets.map(\.weight).max() ?? .zero,
                                         incline: sets.compactMap(\.incline).max(), exercise: e, unit: model.unit)
        else { return ago }
        return "\(ago), \(load)"
    }

    private func planText(_ w: Workout, _ e: Exercise) -> String {
        guard let plan = w.exercises.first(where: { $0.exerciseID == e.id }) else { return "" }
        return LoadFormat.line(sets: plan.targetSets, reps: plan.targetReps, weight: plan.targetWeight,
                               exercise: e, unit: model.unit, incline: plan.targetIncline)
    }
}

/// `60 lb × 10`, `20 min · 8% incline`, `12 reps`.
func bestSetText(_ set: SetLog, _ e: Exercise?, unit: WeightUnit) -> String {
    let measure = e?.measure ?? .reps
    let count = measure == .reps ? "\(set.reps)" : LoadFormat.reps(set.reps, measure: measure)
    guard let load = LoadFormat.load(weight: set.weight, incline: set.incline, exercise: e, unit: unit) else {
        return measure == .reps ? "\(set.reps) reps" : count
    }
    return e?.equipment.inclineStep != nil ? "\(count) · \(load)" : "\(load) × \(count)"
}
