import SwiftUI
import GymBuddyCore

/// `+` on Train: an empty workout by name, or one of the templates.
struct NewWorkoutSheet: View {
    @Environment(AppModel.self) private var model
    @Environment(\.dismiss) private var dismiss
    @State private var name = ""

    var body: some View {
        NavigationStack {
            List {
                Section {
                    HStack {
                        TextField("Name", text: $name)
                            .textInputAutocapitalization(.words)
                            .submitLabel(.done)
                            .onSubmit(createBlank)
                        Button("Create", action: createBlank)
                            .buttonStyle(.borderedProminent)
                            .tint(Theme.accent)
                    }
                } header: {
                    Text("Blank")
                }
                ForEach(TemplateCategory.allCases) { category in
                    Section(category.displayName) {
                        ForEach(TemplateLibrary.templates(in: category)) { template in
                            NavigationLink(value: template.id) {
                                VStack(alignment: .leading, spacing: 3) {
                                    Text(template.name).font(.body.weight(.medium))
                                    Text(template.summary)
                                        .font(.subheadline)
                                        .foregroundStyle(.secondary)
                                        .lineLimit(2)
                                    Text("~\(minutes(template)) min")
                                        .font(.footnote.monospacedDigit())
                                        .foregroundStyle(.tertiary)
                                }
                                .padding(.vertical, 2)
                            }
                        }
                    }
                }
            }
            .navigationTitle("New workout")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
            }
            .navigationDestination(for: String.self) { id in
                if let template = TemplateLibrary.all.first(where: { $0.id == id }) {
                    TemplatePreview(template: template) { dismiss() }
                }
            }
        }
    }

    private func minutes(_ template: WorkoutTemplate) -> Int {
        Stats.plannedMinutes(template.workout(), defaultRest: model.settings.restBetweenSets, exercises: model.exercisesByID)
    }

    private func createBlank() {
        let trimmed = name.trimmingCharacters(in: .whitespaces)
        model.createWorkout(named: trimmed.isEmpty ? "Workout" : trimmed)
        dismiss()
    }
}

private struct TemplatePreview: View {
    let template: WorkoutTemplate
    let done: () -> Void
    @Environment(AppModel.self) private var model
    @State private var pool = PoolLength.default

    private var workout: Workout { template.workout(pool: pool, catalogue: model.exercisesByID) }

    var body: some View {
        List {
            Section {
                Text(template.summary)
                ForEach(template.notes, id: \.self) { note in
                    Label(note, systemImage: "circle.fill")
                        .labelStyle(BulletLabelStyle())
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
            }
            Section {
                ForEach(workout.exercises) { line in
                    if let e = model.exercisesByID[line.exerciseID] {
                        HStack(spacing: 12) {
                            GlyphTile(equipment: e.equipment, size: 32)
                            VStack(alignment: .leading, spacing: 2) {
                                Text(e.name).lineLimit(1)
                                Text(LoadFormat.line(line, exercise: e, unit: model.unit))
                                    .font(.subheadline.monospacedDigit())
                                    .foregroundStyle(.secondary)
                            }
                        }
                    }
                }
                if template.usesPool {
                    Picker("Pool", selection: $pool) {
                        ForEach(PoolLength.allCases) { Text($0.displayName).tag($0) }
                    }
                    .pickerStyle(.menu)
                }
            } header: {
                let minutes = Stats.plannedMinutes(workout, defaultRest: model.settings.restBetweenSets, exercises: model.exercisesByID)
                Text("\(workout.exercises.count) exercises · ~\(minutes) min").eyebrow()
            } footer: {
                Text("Starting loads — adjust to you.")
            }
        }
        .safeAreaInset(edge: .bottom) {
            Button {
                model.createWorkout(from: template, pool: pool)
                done()
            } label: {
                Text("Add workout")
            }
            .buttonStyle(PrimaryButtonStyle())
            .padding(.horizontal, Theme.Metrics.gutter)
            .padding(.bottom, 8)
        }
        .navigationTitle(template.name)
        .navigationBarTitleDisplayMode(.inline)
    }
}

private struct BulletLabelStyle: LabelStyle {
    func makeBody(configuration: Configuration) -> some View {
        HStack(alignment: .firstTextBaseline, spacing: 8) {
            configuration.icon.font(.system(size: 5)).accessibilityHidden(true)
            configuration.title
        }
    }
}
