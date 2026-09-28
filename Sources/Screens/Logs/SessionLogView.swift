import SwiftUI
import GymBuddyCore

struct SessionLogView: View {
    let logID: String
    @Environment(AppModel.self) private var model
    @Environment(\.dismiss) private var dismiss
    @State private var confirmingDelete = false
    @State private var editing = false
    @State private var record: SetLog?

    var body: some View {
        if let log = model.logs.first(where: { $0.id == logID }) {
            content(log)
        } else {
            ContentUnavailableView("Session deleted", systemImage: "trash")
        }
    }

    private func content(_ log: WorkoutLog) -> some View {
        let records = Stats.records(in: log, history: model.logs)
        let recordIDs = Set(records.map(\.id))
        return List {
            Section {
                VStack(alignment: .leading, spacing: 4) {
                    Text("\(log.startedAt.formatted(.dateTime.weekday(.abbreviated).day().month(.abbreviated).year())) · \(log.startedAt.formatted(date: .omitted, time: .shortened)) – \(log.finishedAt.formatted(date: .omitted, time: .shortened))")
                        .foregroundStyle(.secondary)
                    Text("\(LoadFormat.duration(log.duration)) · \(log.sets.count) sets · \(LoadFormat.volume(Stats.volume(log.sets).value(in: model.unit), model.unit)) moved")
                        .font(.body.monospacedDigit().weight(.medium))
                }
            }
            ForEach(log.exerciseOrder, id: \.self) { exerciseID in
                let exercise = model.exercisesByID[exerciseID]
                Section {
                    ForEach(log.sets.filter { $0.exerciseID == exerciseID }) { set in
                        if editing {
                            SetEditor(log: log, set: set, exercise: exercise)
                        } else {
                            SetLine(set: set, exercise: exercise, unit: model.unit, isRecord: recordIDs.contains(set.id))
                                .contentShape(Rectangle())
                                .onTapGesture { if recordIDs.contains(set.id) { record = set } }
                        }
                    }
                } header: {
                    header(exerciseID, exercise)
                }
            }
            ForEach(log.skippedExerciseIDs, id: \.self) { id in
                Section {
                    Text("skipped").foregroundStyle(.secondary)
                } header: {
                    header(id, model.exercisesByID[id])
                }
            }
            if !log.notes.isEmpty || editing {
                Section("Notes") {
                    if editing {
                        TextField("Notes", text: Binding(
                            get: { log.notes },
                            set: { var l = log; l.notes = $0; model.saveLog(l) }
                        ), axis: .vertical)
                    } else {
                        Text(log.notes)
                    }
                }
            }
        }
        .navigationTitle(log.workoutName)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            if editing {
                Button("Done") { editing = false }
            } else {
                Menu {
                    Button("Edit sets", systemImage: "pencil") { editing = true }
                    ShareLink(item: csv(log), preview: SharePreview("\(log.workoutName).csv")) {
                        Label("Export CSV…", systemImage: "tablecells")
                    }
                    Divider()
                    Button("Delete", systemImage: "trash", role: .destructive) { confirmingDelete = true }
                } label: {
                    Image(systemName: "ellipsis.circle")
                }
                .accessibilityLabel("More")
            }
        }
        .alert("Delete this session?", isPresented: $confirmingDelete) {
            Button("Cancel", role: .cancel) {}
            Button("Delete", role: .destructive) {
                dismiss()
                model.deleteLog(log)
            }
        } message: {
            Text(deleteMessage(log, records))
        }
        .alert(recordTitle(log), isPresented: Binding(get: { record != nil }, set: { if !$0 { record = nil } })) {
            Button("OK") {}
        } message: {
            Text(recordMessage(log))
        }
    }

    private func header(_ id: String, _ exercise: Exercise?) -> some View {
        NavigationLink(value: Route.trend(id)) {
            HStack {
                Text(exercise?.name ?? "Removed exercise").font(.headline).foregroundStyle(.primary)
                Spacer()
                Text(exercise?.muscleGroup.displayName ?? "").font(.subheadline)
            }
            .textCase(nil)
        }
        .disabled(exercise == nil)
    }

    private func deleteMessage(_ log: WorkoutLog, _ records: [SetLog]) -> String {
        let names = records.compactMap { model.exercisesByID[$0.exerciseID]?.name }
        guard !names.isEmpty else { return "\(log.sets.count) sets." }
        return "\(log.sets.count) sets, and the \(names.joined(separator: ", ")) PR\(names.count == 1 ? "" : "s") it set."
    }

    private func recordTitle(_ log: WorkoutLog) -> String {
        guard let record, let e = model.exercisesByID[record.exerciseID] else { return "" }
        return "★ \(e.name) \(LoadFormat.weight(record.weight, model.unit)) × \(record.reps)"
    }

    private func recordMessage(_ log: WorkoutLog) -> String {
        guard let record, let before = Stats.previousBest(before: record, in: log, history: model.logs) else { return "" }
        return "Beat \(LoadFormat.weight(before.weight, model.unit)) × \(before.reps) from \(Dates.day(before.completedAt))."
    }

    private func csv(_ log: WorkoutLog) -> URL {
        let url = FileManager.default.temporaryDirectory.appending(path: "\(log.workoutName) \(log.startedAt.formatted(.iso8601.year().month().day())).csv")
        try? CSVExport.sessions([log], exercises: model.exercisesByID, unit: model.unit)
            .write(to: url, atomically: true, encoding: .utf8)
        return url
    }
}

/// Fixing a mis-logged set after the fact.
private struct SetEditor: View {
    let log: WorkoutLog
    let set: SetLog
    let exercise: Exercise?
    @Environment(AppModel.self) private var model

    var body: some View {
        VStack(spacing: 4) {
            LineStepper(title: "Set \(set.setNumber) · \(set.measure(for: exercise).displayName.lowercased())", value: "\(set.reps)",
                        decrement: { update { $0.reps = max(0, $0.reps - set.measure(for: exercise).step) } },
                        increment: { update { $0.reps += set.measure(for: exercise).step } },
                        canDecrement: set.reps > 0)
            if let exercise, exercise.equipment.isLoadable {
                LineStepper(title: "weight", value: LoadFormat.number(set.weight.value(in: model.unit)),
                            detail: model.unit.abbreviation,
                            decrement: { update { $0.weight = exercise.equipment.stepped($0.weight, by: -1, in: model.unit) } },
                            increment: { update { $0.weight = exercise.equipment.stepped($0.weight, by: 1, in: model.unit) } },
                            canDecrement: set.weight.kilograms > 0)
            }
            if let exercise, exercise.equipment.inclineStep != nil {
                LineStepper(title: "incline", value: LoadFormat.incline(set.incline ?? 0),
                            decrement: { update { $0.incline = exercise.equipment.stepped(incline: $0.incline ?? 0, by: -1) } },
                            increment: { update { $0.incline = exercise.equipment.stepped(incline: $0.incline ?? 0, by: 1) } },
                            canDecrement: (set.incline ?? 0) > 0)
            }
        }
        .swipeActions {
            Button("Delete", role: .destructive) {
                var l = log
                l.sets.removeAll { $0.id == set.id }
                model.saveLog(l)
            }
        }
    }

    private func update(_ change: (inout SetLog) -> Void) {
        var l = log
        guard let i = l.sets.firstIndex(where: { $0.id == set.id }) else { return }
        change(&l.sets[i])
        model.saveLog(l)
    }
}
