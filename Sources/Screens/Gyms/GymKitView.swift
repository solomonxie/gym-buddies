import SwiftUI
import GymBuddyCore

/// Which exercises a gym has the kit for: search, tick, or take a whole kind.
struct GymKitView: View {
    @Binding var gym: Gym
    @Environment(AppModel.self) private var model
    @State private var query = ""

    var body: some View {
        let groups = Gym.pickable(model.exercises, matching: query)
        List {
            if groups.isEmpty {
                Text("No exercise called “\(query)”.").foregroundStyle(.secondary)
            }
            ForEach(groups, id: \.equipment) { group in
                Section {
                    ForEach(group.exercises) { exercise in
                        row(exercise)
                    }
                } header: {
                    header(group.equipment, group.exercises)
                }
            }
        }
        .listStyle(.insetGrouped)
        .searchable(text: $query, placement: .navigationBarDrawer(displayMode: .always), prompt: "Search")
        .navigationTitle("Equipment")
        .navigationBarTitleDisplayMode(.inline)
    }

    private func row(_ exercise: Exercise) -> some View {
        let has = gym.exerciseIDs.contains(exercise.id)
        return Button {
            if has { gym.exerciseIDs.remove(exercise.id) } else { gym.exerciseIDs.insert(exercise.id) }
        } label: {
            HStack(spacing: 12) {
                Text(exercise.name).foregroundStyle(.primary)
                Spacer()
                Image(systemName: has ? "checkmark.circle.fill" : "circle")
                    .font(.title3)
                    .foregroundStyle(has ? Theme.accent : Color.secondary)
            }
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityAddTraits(has ? .isSelected : [])
    }

    private func header(_ kit: Equipment, _ exercises: [Exercise]) -> some View {
        let ids = Set(exercises.map(\.id))
        let all = ids.isSubset(of: gym.exerciseIDs)
        return HStack {
            GlyphTile(equipment: kit, size: 22)
            Text(kit.displayName).eyebrow()
            Text("\(ids.intersection(gym.exerciseIDs).count)/\(ids.count)").eyebrow().monospacedDigit()
            Spacer()
            Button(all ? "None" : "All") {
                if all { gym.exerciseIDs.subtract(ids) } else { gym.exerciseIDs.formUnion(ids) }
            }
            .font(.subheadline.weight(.semibold))
            .textCase(nil)
        }
    }
}
