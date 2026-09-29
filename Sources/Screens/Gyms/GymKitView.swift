import SwiftUI
import GymBuddyCore

/// The machines and equipment a gym has. Each kind folds to a few rows until
/// opened; a search shows every match.
struct GymKitView: View {
    @Binding var gym: Gym
    @Environment(AppModel.self) private var model
    @State private var query = ""
    @State private var expanded: Set<Kit.Kind> = []

    private static let folded = 5

    var body: some View {
        let groups = Kit.pickable(model.exercises, matching: query)
        let uses = Dictionary(grouping: model.exercises.compactMap { Kit.needed(by: $0)?.id }, by: { $0 }).mapValues(\.count)
        List {
            if groups.isEmpty {
                Text("Nothing called “\(query)”.").foregroundStyle(.secondary)
            }
            ForEach(groups, id: \.kind) { group in
                let open = !query.isEmpty || expanded.contains(group.kind)
                Section {
                    ForEach(open ? group.kits : Array(group.kits.prefix(Self.folded))) { kit in
                        row(kit, uses: uses[kit.id] ?? 0)
                    }
                    if query.isEmpty && group.kits.count > Self.folded {
                        Button(open ? "Show fewer" : "Show \(group.kits.count - Self.folded) more") {
                            if open { expanded.remove(group.kind) } else { expanded.insert(group.kind) }
                        }
                        .font(.subheadline.weight(.semibold))
                    }
                } header: {
                    header(group.kind, group.kits)
                }
            }
        }
        .listStyle(.insetGrouped)
        .searchable(text: $query, placement: .navigationBarDrawer(displayMode: .always), prompt: "Search")
        .animation(.snappy, value: expanded)
        .navigationTitle("Equipment")
        .navigationBarTitleDisplayMode(.inline)
    }

    private func row(_ kit: Kit, uses: Int) -> some View {
        let has = gym.kitIDs.contains(kit.id)
        return Button {
            if has { gym.kitIDs.remove(kit.id) } else { gym.kitIDs.insert(kit.id) }
        } label: {
            HStack(spacing: 12) {
                VStack(alignment: .leading, spacing: 2) {
                    Text(kit.name).foregroundStyle(.primary)
                    Text("\(uses) exercise\(uses == 1 ? "" : "s")")
                        .font(.footnote.monospacedDigit())
                        .foregroundStyle(.secondary)
                }
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

    private func header(_ kind: Kit.Kind, _ kits: [Kit]) -> some View {
        let ids = Set(kits.map(\.id))
        let all = ids.isSubset(of: gym.kitIDs)
        return HStack {
            Text(kind.displayName).eyebrow()
            Text("\(ids.intersection(gym.kitIDs).count)/\(ids.count)").eyebrow().monospacedDigit()
            Spacer()
            Button(all ? "None" : "All") {
                if all { gym.kitIDs.subtract(ids) } else { gym.kitIDs.formUnion(ids) }
            }
            .font(.subheadline.weight(.semibold))
            .textCase(nil)
        }
    }
}
