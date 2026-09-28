import SwiftUI
import GymBuddyCore

/// Multi-select, because nobody adds exactly one exercise.
struct AddExercisesView: View {
    let workoutID: String
    @Environment(AppModel.self) private var model
    @Environment(\.dismiss) private var dismiss
    @State private var query = ""
    @State private var group: MuscleGroup?
    @State private var selected: [String] = []
    @State private var creating: String?

    private var filtered: [Exercise] {
        model.exercises.filter { e in
            (group == nil || e.muscleGroup == group)
                && (query.isEmpty || e.name.localizedCaseInsensitiveContains(query))
        }
        .sorted { a, b in
            a.isFavourite != b.isFavourite ? a.isFavourite : a.name < b.name
        }
    }

    var body: some View {
        List {
            Section {
                ChipBar(selection: $group)
                    .listRowInsets(EdgeInsets())
                    .listRowBackground(Color.clear)
            }
            if filtered.isEmpty {
                Section {
                    Text(query.isEmpty ? "Nothing here." : "No exercise called “\(query)”.").foregroundStyle(.secondary)
                    Button("Create it") { creating = query }
                }
            }
            Section {
                ForEach(filtered) { exercise in
                    Button { toggle(exercise.id) } label: {
                        HStack(spacing: 12) {
                            Image(systemName: selected.contains(exercise.id) ? "checkmark.circle.fill" : "circle")
                                .font(.title3)
                                .foregroundStyle(selected.contains(exercise.id) ? Theme.accent : Color.secondary.opacity(0.5))
                            Text(exercise.name).foregroundStyle(.primary).lineLimit(1)
                            Spacer()
                            if exercise.isFavourite {
                                Image(systemName: "heart.fill").font(.caption).foregroundStyle(.red)
                            }
                            Text("\(exercise.muscleGroup.displayName) · \(exercise.equipment.displayName)")
                                .font(.footnote)
                                .foregroundStyle(.secondary)
                        }
                        .contentShape(Rectangle())
                    }
                    .accessibilityAddTraits(selected.contains(exercise.id) ? .isSelected : [])
                }
            }
        }
        .searchable(text: $query, placement: .navigationBarDrawer(displayMode: .always), prompt: "Search")
        .navigationTitle("Add to \(model.workout(id: workoutID)?.name ?? "workout")")
        .navigationBarTitleDisplayMode(.inline)
        .safeAreaInset(edge: .bottom) {
            if !selected.isEmpty {
                HStack {
                    Text("\(selected.count) selected").foregroundStyle(.secondary)
                    Button("Add \(selected.count)") {
                        model.add(selected, to: workoutID)
                        dismiss()
                    }
                    .buttonStyle(PrimaryButtonStyle())
                    .frame(maxWidth: 200)
                }
                .padding()
                .background(.bar)
            }
        }
        .sheet(item: $creating) { name in
            ExerciseEditorView(exercise: nil, initialName: name)
        }
    }

    private func toggle(_ id: String) {
        if let i = selected.firstIndex(of: id) { selected.remove(at: i) } else { selected.append(id) }
    }
}
