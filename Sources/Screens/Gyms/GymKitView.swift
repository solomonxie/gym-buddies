import SwiftUI
import GymBuddyCore

/// The machines and equipment a gym has. Each kind folds to a few rows until
/// opened; a search shows every match.
struct GymKitView: View {
    @Binding var gym: Gym
    @Environment(AppModel.self) private var model
    @State private var query = ""
    @State private var expanded: Set<Kit.Kind> = []
    @State private var selectedOnly = false

    private static let folded = 5

    var body: some View {
        let all = Kit.pickable(model.exercises, matching: query)
        let groups = selectedOnly
            ? all.map { (kind: $0.kind, kits: $0.kits.filter { gym.kitIDs.contains($0.id) }) }.filter { !$0.kits.isEmpty }
            : all
        let selectedCount = Set(Kit.pickable(model.exercises, matching: "").flatMap(\.kits).map(\.id)).intersection(gym.kitIDs).count
        let uses = Dictionary(grouping: model.exercises.compactMap { Kit.needed(by: $0)?.id }, by: { $0 }).mapValues(\.count)
        List {
            Section {
                Picker("Show", selection: $selectedOnly) {
                    Text("All").tag(false)
                    Text("Selected (\(selectedCount))").tag(true)
                }
                .pickerStyle(.segmented)
                .listRowInsets(EdgeInsets())
                .listRowBackground(Color.clear)
            }
            if groups.isEmpty {
                Text(selectedOnly ? "Nothing selected\(query.isEmpty ? "" : " matches “\(query)”")." : "Nothing called “\(query)”.")
                    .foregroundStyle(.secondary)
            }
            ForEach(groups, id: \.kind) { group in
                let open = selectedOnly || !query.isEmpty || expanded.contains(group.kind)
                Section {
                    ForEach(open ? group.kits : Array(group.kits.prefix(Self.folded))) { kit in
                        row(kit, uses: uses[kit.id] ?? 0)
                    }
                    if query.isEmpty && !selectedOnly && group.kits.count > Self.folded {
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
