import SwiftUI
import GymBuddyCore

struct ExercisesView: View {
    var body: some View {
        ExerciseLibrary()
            .navigationTitle("Exercises")
    }
}

/// The library. Favourites is this same list with a filter, not a second one.
struct ExerciseLibrary: View {
    @Environment(AppModel.self) private var model
    private var favouritesOnly: Bool { model.favouritesOnly }
    @State private var query = ""
    @State private var group: MuscleGroup?
    @State private var creating: String?
    @State private var addingToWorkout: Exercise?

    private var filtered: [Exercise] {
        model.exercises.filter { e in
            (!favouritesOnly || e.isFavourite)
                && (group == nil || e.muscleGroup == group)
                && (query.isEmpty || e.name.localizedCaseInsensitiveContains(query)
                    || e.equipment.displayName.localizedCaseInsensitiveContains(query))
        }
    }

    private var sections: [(MuscleGroup, [Exercise])] {
        let byGroup = Dictionary(grouping: filtered, by: \.muscleGroup)
        return MuscleGroup.allCases.compactMap { g in byGroup[g].map { (g, $0) } }
    }

    var body: some View {
        list
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button { creating = "" } label: { Image(systemName: "plus") }
                    .accessibilityLabel("Create an exercise")
            }
        }
        .sheet(item: $creating) { name in
            ExerciseEditorView(exercise: nil, initialName: name)
        }
        .confirmationDialog(
            "Add \(addingToWorkout?.name ?? "") to…",
            isPresented: Binding(get: { addingToWorkout != nil }, set: { if !$0 { addingToWorkout = nil } }),
            titleVisibility: .visible
        ) {
            ForEach(model.workouts) { workout in
                Button(workout.name) {
                    if let e = addingToWorkout { model.add([e.id], to: workout.id) }
                }
            }
        } message: {
            if model.workouts.isEmpty { Text("Build a workout first, on Train.") }
        }
    }

    private var list: some View {
        List {
            Section {
                ChipBar(selection: $group, favourites: Binding(
                    get: { model.favouritesOnly }, set: { model.favouritesOnly = $0 }
                ))
                    .listRowInsets(EdgeInsets())
                    .listRowBackground(Color.clear)
            }
            if filtered.isEmpty {
                noMatch
            }
            ForEach(sections, id: \.0) { group, exercises in
                Section {
                    ForEach(exercises) { exercise in
                        NavigationLink(value: Route.exercise(exercise.id)) {
                            ExerciseRow(exercise: exercise) { model.toggleFavourite(exercise) }
                        }
                        .swipeActions(edge: .trailing) {
                            Button { model.toggleFavourite(exercise) } label: {
                                Label("Favourite", systemImage: exercise.isFavourite ? "heart.slash" : "heart")
                            }
                            .tint(.red)
                            Button { addingToWorkout = exercise } label: {
                                Label("Add to workout…", systemImage: "text.badge.plus")
                            }
                            .tint(Theme.accent)
                        }
                    }
                } header: {
                    HStack {
                        Text(group.displayName)
                        Spacer()
                        Text("\(exercises.count)").monospacedDigit()
                    }
                    .eyebrow()
                }
            }
        }
        .listStyle(.insetGrouped)
        .searchable(text: $query, prompt: "Search \(model.exercises.count) exercises")
        .animation(.snappy, value: group)
        .animation(.snappy, value: favouritesOnly)
    }

    @ViewBuilder
    private var noMatch: some View {
        Section {
            VStack(alignment: .leading, spacing: 12) {
                if favouritesOnly && query.isEmpty {
                    Text("Nothing starred yet").font(.headline)
                    Text("Tap ♥ on an exercise to keep it here.").foregroundStyle(.secondary)
                    Button("Show all exercises") { model.favouritesOnly = false }
                        .buttonStyle(SoftButtonStyle())
                } else {
                    Text(query.isEmpty ? "Nothing in this group yet." : "No exercise called “\(query)”.")
                        .foregroundStyle(.secondary)
                    Button("Create it") { creating = query }
                        .buttonStyle(SoftButtonStyle())
                }
            }
            .padding(.vertical, 8)
        }
    }
}

extension String: @retroactive Identifiable {
    public var id: String { self }
}
