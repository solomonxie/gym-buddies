import SwiftUI
import GymBuddyCore

/// Progress: what you've actually done, from the numbers `Stats` computes.
struct LogsView: View {
    @Environment(AppModel.self) private var model
    @AppStorage("logsRange") private var rangeRaw = TrendRange.days30.rawValue
    @State private var shown = 50

    private var range: TrendRange { TrendRange(rawValue: rangeRaw) ?? .days30 }

    var body: some View {
        Group {
            if model.logs.isEmpty {
                EmptyState(
                    title: "No sessions yet",
                    message: "Finish a workout and it shows up here with the numbers filled in.",
                    systemImage: "chart.bar.xaxis",
                    action: ("Back to Train", { model.path.removeAll() })
                )
            } else {
                content
            }
        }
        .background(Theme.surface)
        .navigationTitle("Progress")
        .toolbar {
            if !model.logs.isEmpty {
                ToolbarItem(placement: .primaryAction) {
                    ShareLink(item: csvFile(), preview: SharePreview("Gym Buddy sessions.csv")) {
                        Image(systemName: "square.and.arrow.up")
                    }
                    .accessibilityLabel("Export sessions as CSV")
                }
            }
        }
    }

    private var content: some View {
        let inRange = Stats.logs(model.logs, since: range.start)
        let sets = inRange.flatMap(\.sets)
        let rows = Stats.volumeRows(sets, exercises: model.exercisesByID, in: model.unit)
        let maximum = rows.map(\.volume).max() ?? 0
        let minutes = Int(inRange.reduce(0) { $0 + $1.duration } / 60)

        return ScrollView {
            VStack(alignment: .leading, spacing: 12) {
                Picker("Range", selection: $rangeRaw) {
                    ForEach(TrendRange.allCases) { Text($0.rawValue).tag($0.rawValue) }
                }
                .pickerStyle(.segmented)

                HStack(spacing: 10) {
                    StatTile(value: "\(inRange.count)", label: "Sessions")
                    StatTile(value: StatFormat.compact(Stats.volume(sets).value(in: model.unit)), label: "\(model.unit.abbreviation) moved")
                    StatTile(value: StatFormat.hours(minutes), label: "Time")
                }

                VStack(alignment: .leading, spacing: 12) {
                    Text("This week").eyebrow()
                    WeekDots(days: Stats.weekDots(model.logs, asOf: .now))
                }
                .card()

                VStack(alignment: .leading, spacing: 14) {
                    Text("Volume by muscle group").eyebrow()
                    ForEach(rows, id: \.group) { row in
                        BarRow(label: row.group.displayName, value: row.volume, maximum: maximum, unit: model.unit)
                    }
                }
                .card()

                HStack {
                    Text("History").eyebrow()
                    Spacer()
                    Text("\(inRange.count)").eyebrow()
                }
                .padding(.horizontal, 4)
                .padding(.top, 8)

                if inRange.isEmpty {
                    Text("Nothing in the last \(range.rawValue).")
                        .foregroundStyle(.secondary)
                        .card()
                }
                LazyVStack(spacing: 8) {
                    ForEach(inRange.prefix(shown)) { log in
                        NavigationLink(value: Route.log(log.id)) {
                            HistoryRow(log: log, hasRecord: !Stats.records(in: log, history: model.logs).isEmpty)
                                .card(padding: 14)
                        }
                        .buttonStyle(.plain)
                    }
                }
                if inRange.count > shown {
                    Button("Show \(min(50, inRange.count - shown)) more") { shown += 50 }
                        .buttonStyle(SoftButtonStyle())
                        .frame(maxWidth: .infinity)
                }
            }
            .padding(.horizontal, Theme.Metrics.gutter)
            .padding(.bottom, 24)
        }
    }

    private func csvFile() -> URL {
        let url = FileManager.default.temporaryDirectory.appending(path: "Gym Buddy sessions.csv")
        try? CSVExport.sessions(model.logs, exercises: model.exercisesByID, workouts: model.workouts, unit: model.unit)
            .write(to: url, atomically: true, encoding: .utf8)
        return url
    }
}

/// ● = trained. No streak fire, no guilt for the gaps.
struct WeekDots: View {
    let days: [Bool]
    private let letters = ["M", "T", "W", "T", "F", "S", "S"]

    var body: some View {
        HStack {
            ForEach(0..<7, id: \.self) { i in
                VStack(spacing: 8) {
                    Circle()
                        .fill(days[i] ? Theme.accent : Theme.fill)
                        .frame(width: 30, height: 30)
                        .overlay {
                            if days[i] {
                                Image(systemName: "checkmark").font(.caption.weight(.bold)).foregroundStyle(.white)
                            }
                        }
                    Text(letters[i]).font(.caption.weight(.medium)).foregroundStyle(.secondary)
                }
                .frame(maxWidth: .infinity)
            }
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Trained on \(days.filter { $0 }.count) of 7 days this week")
    }
}

struct HistoryRow: View {
    let log: WorkoutLog
    let hasRecord: Bool
    @Environment(AppModel.self) private var model

    var body: some View {
        HStack(spacing: 14) {
            VStack(spacing: 0) {
                Text(log.startedAt.formatted(.dateTime.day()))
                    .font(.tabular(20, weight: .bold))
                Text(log.startedAt.formatted(.dateTime.month(.abbreviated)))
                    .font(.caption2.weight(.semibold))
                    .textCase(.uppercase)
                    .foregroundStyle(.secondary)
            }
            .frame(width: 44)
            VStack(alignment: .leading, spacing: 3) {
                HStack(spacing: 6) {
                    Text(log.name(in: model.workouts)).font(.headline).lineLimit(1)
                    if hasRecord {
                        Image(systemName: "star.fill")
                            .font(.caption)
                            .foregroundStyle(Theme.record)
                            .accessibilityLabel("set a personal record")
                    }
                }
                Text("\(LoadFormat.duration(log.duration)) · \(log.sets.count) sets · \(LoadFormat.volume(Stats.volume(log.sets).value(in: model.unit), model.unit))")
                    .font(.subheadline.monospacedDigit())
                    .foregroundStyle(.secondary)
            }
            Spacer()
            Image(systemName: "chevron.right").font(.footnote.weight(.semibold)).foregroundStyle(.tertiary)
        }
        .contentShape(Rectangle())
    }
}

enum StatFormat {
    /// `82k`, `12.4k`, `940`.
    static func compact(_ value: Double) -> String {
        switch value {
        case 1_000_000...: String(format: "%.1fM", value / 1_000_000)
        case 10_000...: String(format: "%.0fk", value / 1000)
        case 1000...: String(format: "%.1fk", value / 1000)
        default: String(Int(value))
        }
    }

    static func hours(_ minutes: Int) -> String {
        minutes >= 60 ? "\(minutes / 60)h \(minutes % 60)m" : "\(minutes)m"
    }
}
