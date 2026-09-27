import SwiftUI
import GymBuddyCore

/// Create or edit your own exercise — the escape hatch when search finds nothing.
struct ExerciseEditorView: View {
    let exercise: Exercise?
    var initialName = ""
    @Environment(AppModel.self) private var model
    @Environment(\.dismiss) private var dismiss

    @State private var name = ""
    @State private var group = MuscleGroup.arms
    @State private var equipment = Equipment.dumbbell
    @State private var muscles: [Muscle] = []
    @State private var measure = Measure.reps
    @State private var instructions = ""

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    TextField("Name", text: $name)
                        .textInputAutocapitalization(.words)
                    Picker("Muscle group", selection: $group) {
                        ForEach(MuscleGroup.allCases) { Text($0.displayName).tag($0) }
                    }
                    Picker("Equipment", selection: $equipment) {
                        ForEach(Equipment.allCases, id: \.self) { Text($0.displayName).tag($0) }
                    }
                    Picker("Counted in", selection: $measure) {
                        ForEach(Measure.allCases, id: \.self) { Text($0.displayName).tag($0) }
                    }
                } footer: {
                    if equipment.isLoadable {
                        Text("+ adds \(LoadFormat.weight(equipment.increment(in: model.unit), model.unit)) a tap.")
                    } else if let step = equipment.inclineStep {
                        Text("Tracks incline instead of weight, \(LoadFormat.incline(step)) a tap.")
                    } else {
                        Text("No weight is tracked for this equipment.")
                    }
                }
                Section("Muscles worked") {
                    ForEach(Muscle.allCases) { muscle in
                        Button {
                            if let i = muscles.firstIndex(of: muscle) { muscles.remove(at: i) } else { muscles.append(muscle) }
                        } label: {
                            HStack {
                                Text(muscle.displayName).foregroundStyle(.primary)
                                Spacer()
                                if let i = muscles.firstIndex(of: muscle) {
                                    Text(i == 0 ? "primary" : "secondary").font(.caption).foregroundStyle(.secondary)
                                    Image(systemName: "checkmark").foregroundStyle(Theme.accent)
                                }
                            }
                        }
                    }
                }
                Section {
                    TextField("One step per line", text: $instructions, axis: .vertical)
                        .lineLimit(3...8)
                } header: {
                    Text("How to")
                } footer: {
                    Text("Optional. Three lines covering what people get wrong is plenty.")
                }
            }
            .navigationTitle(exercise == nil ? "New exercise" : "Edit exercise")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("Cancel") { dismiss() } }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save", action: save)
                        .disabled(name.trimmingCharacters(in: .whitespaces).isEmpty)
                }
            }
            .onAppear(perform: load)
        }
    }

    private func load() {
        guard let e = exercise else {
            name = initialName
            return
        }
        name = e.name
        group = e.muscleGroup
        equipment = e.equipment
        muscles = e.muscles
        measure = e.measure
        instructions = e.instructions ?? ""
    }

    private func save() {
        let steps = instructions.split(separator: "\n").map { $0.trimmingCharacters(in: .whitespaces) }.filter { !$0.isEmpty }
        model.saveExercise(Exercise(
            id: exercise?.id ?? "custom-" + UUID().uuidString.lowercased(),
            name: name.trimmingCharacters(in: .whitespaces),
            muscleGroup: group,
            equipment: equipment,
            muscles: muscles,
            instructions: steps.isEmpty ? nil : steps.joined(separator: "\n"),
            isFavourite: exercise?.isFavourite ?? false,
            isCustom: true,
            measure: measure
        ))
        dismiss()
    }
}
