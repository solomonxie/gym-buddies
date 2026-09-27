import SwiftUI
import GymBuddyCore

struct TrendView: View {
    let exerciseID: String
    @Environment(AppModel.self) private var model
    @AppStorage("detailMetric") private var metricRaw = Stats.Metric.topWeight.rawValue
    @AppStorage("logsRange") private var rangeRaw = TrendRange.all.rawValue

    private var metric: Stats.Metric { Stats.Metric(rawValue: metricRaw) ?? .topWeight }
    private var range: TrendRange { TrendRange(rawValue: rangeRaw) ?? .all }

    var body: some View {
        let exercise = model.exercisesByID[exerciseID]
        let logs = Stats.logs(model.logs, since: range.start)
        let sessions = Stats.sessions(exerciseID: exerciseID, in: logs)
        let best = Stats.personalRecord(exerciseID: exerciseID, in: model.logs.flatMap(\.sets))
        let bestLog = best.flatMap { b in model.logs.first { $0.sets.contains { $0.id == b.id } } }

        List {
            Section {
                Picker("Metric", selection: $metricRaw) {
                    ForEach(Stats.Metric.allCases) { Text($0.displayName).tag($0.rawValue) }
                }
                .pickerStyle(.segmented)
                Picker("Range", selection: $rangeRaw) {
                    ForEach(TrendRange.allCases) { Text($0.rawValue).tag($0.rawValue) }
                }
                .pickerStyle(.segmented)
                TrendChart(points: Stats.series(exerciseID: exerciseID, metric: metric, from: logs, in: model.unit),
                           metric: metric, unit: model.unit, height: 220)
            }

            if let best, let bestLog {
                Section("Best") {
                    NavigationLink(value: Route.log(bestLog.id)) {
                        LabeledContent {
                            Text(Dates.day(bestLog.startedAt))
                        } label: {
                            Text(bestText(best, exercise)).font(.tabular(17, weight: .semibold))
                        }
                    }
                }
            }

            if !sessions.isEmpty {
                Section("Every session") {
                    ForEach(sessions, id: \.log.id) { item in
                        let isRecord = Stats.records(in: item.log, history: model.logs).contains { $0.exerciseID == exerciseID }
                        NavigationLink(value: Route.log(item.log.id)) {
                            HStack {
                                Text(Dates.day(item.log.startedAt)).frame(width: 96, alignment: .leading)
                                Text(LoadFormat.summary(item.sets, exercise: exercise, unit: model.unit)).monospacedDigit()
                                Spacer()
                                if isRecord { Text("★").foregroundStyle(Theme.record) }
                                else if item.sets.contains(where: \.isUnderTarget) { Text("▼").foregroundStyle(.secondary) }
                            }
                            .font(.subheadline)
                        }
                    }
                }
            }
        }
        .navigationTitle(exercise?.name ?? "Trend")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            if exercise != nil {
                NavigationLink(value: Route.exercise(exerciseID)) { Image(systemName: "info.circle") }
                    .accessibilityLabel("About this exercise")
            }
        }
    }

    private func bestText(_ set: SetLog, _ e: Exercise?) -> String {
        bestSetText(set, e, unit: model.unit)
    }
}
