import Charts
import SwiftUI
import GymBuddyCore

enum TrendRange: String, CaseIterable, Identifiable {
    case days30 = "30d", days90 = "90d", all = "All"

    var id: String { rawValue }

    var start: Date? {
        switch self {
        case .days30: Calendar.current.date(byAdding: .day, value: -30, to: .now)
        case .days90: Calendar.current.date(byAdding: .day, value: -90, to: .now)
        case .all: nil
        }
    }
}

extension Stats.Metric: @retroactive Identifiable {
    public var id: String { rawValue }
}

/// One point per session. Two points make a trend, one does not — so a
/// single session draws a dot and no line.
struct TrendChart: View {
    let points: [Stats.Point]
    let metric: Stats.Metric
    let unit: WeightUnit
    var height: CGFloat = 200

    @State private var selected: Date?

    var body: some View {
        if points.isEmpty {
            Text("Do it once and the graph starts.")
                .foregroundStyle(.secondary)
                .frame(maxWidth: .infinity, minHeight: height)
                .background(RoundedRectangle(cornerRadius: 12).fill(Color.secondary.opacity(0.06)))
        } else {
            VStack(alignment: .leading, spacing: 6) {
                readout
                chart
            }
        }
    }

    private var readout: some View {
        let point = selectedPoint ?? points.last!
        return HStack(alignment: .firstTextBaseline) {
            Text(format(point.value))
                .font(.tabular(22))
            Text(Dates.day(point.date))
                .font(.footnote)
                .foregroundStyle(.secondary)
            Spacer()
        }
        .accessibilityElement(children: .combine)
    }

    private var chart: some View {
        Chart {
            ForEach(points, id: \.date) { point in
                if points.count > 1 {
                    LineMark(x: .value("Date", point.date), y: .value(metric.displayName, point.value))
                        .foregroundStyle(Theme.accent)
                        .interpolationMethod(.monotone)
                }
                PointMark(x: .value("Date", point.date), y: .value(metric.displayName, point.value))
                    .foregroundStyle(Theme.accent)
                    .symbolSize(points.count > 20 ? 20 : 45)
            }
            if let point = selectedPoint {
                RuleMark(x: .value("Date", point.date))
                    .foregroundStyle(Color.secondary.opacity(0.4))
            }
        }
        .chartYScale(domain: .automatic(includesZero: false))
        .chartXSelection(value: $selected)
        .frame(height: height)
        .accessibilityLabel("\(metric.displayName) over \(points.count) sessions")
    }

    private var selectedPoint: Stats.Point? {
        guard let selected else { return nil }
        return points.min { abs($0.date.timeIntervalSince(selected)) < abs($1.date.timeIntervalSince(selected)) }
    }

    private func format(_ value: Double) -> String {
        switch metric {
        case .topWeight: "\(LoadFormat.number(value)) \(unit.abbreviation)"
        case .volume: LoadFormat.volume(value, unit)
        case .reps: "\(Int(value)) reps"
        }
    }
}
