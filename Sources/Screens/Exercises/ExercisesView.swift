import SwiftUI
import GymBuddyCore

struct ExercisesView: View {
    var body: some View {
        ExerciseLibrary()
            .navigationTitle("Exercises")
    }
}

/// The library: favourites on top, then every muscle group, each folded to a
/// few rows until tapped open. A search shows every match.
struct ExerciseLibrary: View {
    @Environment(AppModel.self) private var model
    @State private var query = ""
    @State private var expanded: Set<String> = []
    @State private var creating: String?
    @State private var addingToWorkout: Exercise?

    private static let folded = 3
    private static let favouritesKey = "favourites"

    private var filtered: [Exercise] {
        model.exercises.filter { e in
            query.isEmpty || e.name.localizedCaseInsensitiveContains(query)
                || e.equipment.displayName.localizedCaseInsensitiveContains(query)
        }
    }

    private var sections: [(key: String, title: String, exercises: [Exercise])] {
        let shown = filtered
        let favourites = shown.filter(\.isFavourite)
        let byGroup = Dictionary(grouping: shown, by: \.muscleGroup)
        return (favourites.isEmpty ? [] : [(Self.favouritesKey, "Favourites", favourites)])
            + MuscleGroup.allCases.compactMap { g in byGroup[g].map { (g.rawValue, g.displayName, $0) } }
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
            if filtered.isEmpty {
                noMatch
            }
            ForEach(sections, id: \.key) { section in
                let open = !query.isEmpty || expanded.contains(section.key)
                Section {
                    ForEach(open ? section.exercises : Array(section.exercises.prefix(Self.folded))) { exercise in
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
                    if query.isEmpty && section.exercises.count > Self.folded {
                        Button(open ? "Show fewer" : "Show \(section.exercises.count - Self.folded) more") {
                            if open { expanded.remove(section.key) } else { expanded.insert(section.key) }
                        }
                        .font(.subheadline.weight(.semibold))
                    }
                } header: {
                    HStack {
                        Text(section.title)
                        Spacer()
                        Text("\(section.exercises.count)").monospacedDigit()
                    }
                    .eyebrow()
                }
            }
        }
        .listStyle(.insetGrouped)
        .searchable(text: $query, placement: .navigationBarDrawer(displayMode: .always), prompt: "Search \(model.exercises.count) exercises")
        .animation(.snappy, value: expanded)
    }

    @ViewBuilder
    private var noMatch: some View {
        Section {
            VStack(alignment: .leading, spacing: 12) {
                Text(query.isEmpty ? "No exercises yet." : "No exercise called “\(query)”.")
                    .foregroundStyle(.secondary)
                Button("Create it") { creating = query }
                    .buttonStyle(SoftButtonStyle())
            }
            .padding(.vertical, 8)
        }
    }
}

extension String: @retroactive Identifiable {
    public var id: String { self }
}
