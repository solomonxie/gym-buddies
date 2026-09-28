import GymBuddyCore
import SwiftUI

enum SessionField: String, Identifiable, CaseIterable {
    case reps, weight, incline
    var id: String { rawValue }
}

/// What one working value shows and how it steps, for the card and the sheet.
struct FieldSpec {
    let value: String
    let label: String
    let title: String
    let detail: String?
    let decrementLabel: String
    let incrementLabel: String
    let step: (Int) -> Void
    let current: String
    let keyboard: UIKeyboardType
    let commit: (Double) -> Void

    @MainActor
    static func make(_ field: SessionField, model: AppModel) -> FieldSpec? {
        guard let session = model.session, let entry = session.currentEntry else { return nil }
        let equipment = entry.exercise.equipment
        switch field {
        case .reps:
            let measure = entry.measure
            return FieldSpec(
                value: "\(session.workingReps)", label: measure.displayName.lowercased(),
                title: measure.displayName, detail: measure.step == 1 ? nil : "± \(measure.step)",
                decrementLabel: "Fewer", incrementLabel: "More",
                step: { n in model.updateSession { $0.adjustReps(by: n * measure.step) } },
                current: "\(session.workingReps)", keyboard: .numberPad,
                commit: { v in model.updateSession { $0.setWorkingValues(reps: Int(v)) } }
            )
        case .weight:
            guard equipment.isLoadable else { return nil }
            let step = LoadFormat.weight(equipment.increment(in: model.unit), model.unit)
            return FieldSpec(
                value: LoadFormat.readout(session.workingWeight, model.unit), label: model.unit.abbreviation,
                title: "Weight (\(model.unit.abbreviation))", detail: "± \(step)",
                decrementLabel: "\(step) lighter", incrementLabel: "\(step) heavier",
                step: { n in model.updateSession { $0.adjustWeight(by: n, in: model.unit) } },
                current: LoadFormat.number(session.workingWeight.value(in: model.unit)), keyboard: .decimalPad,
                commit: { v in model.updateSession { $0.setWorkingValues(weight: Weight(v, model.unit)) } }
            )
        case .incline:
            guard let step = equipment.inclineStep else { return nil }
            return FieldSpec(
                value: LoadFormat.number(session.workingIncline ?? 0), label: "incline %",
                title: "Incline (%)", detail: "± \(LoadFormat.incline(step))",
                decrementLabel: "Less incline", incrementLabel: "More incline",
                step: { n in model.updateSession { $0.adjustIncline(by: n) } },
                current: LoadFormat.number(session.workingIncline ?? 0), keyboard: .decimalPad,
                commit: { v in model.updateSession { $0.setWorkingValues(incline: v) } }
            )
        }
    }
}

/// The working values stacked beside the muscle map. Reading them is the
/// common case; tapping one brings its ± down to the thumb.
struct ValueColumn: View {
    @Environment(AppModel.self) private var model
    @Binding var editing: SessionField?

    var body: some View {
        VStack(spacing: 8) {
            ForEach(SessionField.allCases) { field in
                if let spec = FieldSpec.make(field, model: model) {
                    Button { editing = field } label: {
                        VStack(spacing: 0) {
                            Text(spec.value)
                                .font(.tabular(34, weight: .bold))
                                .lineLimit(1)
                                .minimumScaleFactor(0.5)
                                .contentTransition(.numericText())
                                .animation(.snappy(duration: 0.2), value: spec.value)
                            Text(spec.label).eyebrow()
                        }
                        .frame(maxWidth: .infinity, minHeight: 72)
                        .background(RoundedRectangle(cornerRadius: Theme.Metrics.corner, style: .continuous).fill(Theme.card))
                        .overlay(alignment: .topTrailing) {
                            Image(systemName: "plusminus")
                                .font(.caption2.weight(.bold))
                                .foregroundStyle(.tertiary)
                                .padding(8)
                        }
                        .contentShape(Rectangle())
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel("\(spec.value) \(spec.label)")
                    .accessibilityHint("Adjust")
                }
            }
        }
    }
}

/// − and + at the thumb's edges; tap the number to type it instead.
struct AdjustSheet: View {
    let field: SessionField
    @Environment(AppModel.self) private var model
    @Environment(\.dismiss) private var dismiss
    @State private var typing = false
    @State private var text = ""
    @FocusState private var focused: Bool

    var body: some View {
        if let spec = FieldSpec.make(field, model: model) {
            VStack(spacing: 14) {
                HStack {
                    Text(spec.title).font(.headline)
                    if let detail = spec.detail {
                        Text(detail).font(.subheadline.monospacedDigit()).foregroundStyle(.secondary)
                    }
                }
                HStack(spacing: 0) {
                    RepeatButton(systemImage: "minus", label: spec.decrementLabel) { spec.step(-1) }
                    Group {
                        if typing {
                            TextField("0", text: $text)
                                .keyboardType(spec.keyboard)
                                .multilineTextAlignment(.center)
                                .focused($focused)
                                .onSubmit { commit(spec) }
                        } else {
                            Button { startTyping(spec) } label: {
                                Text(spec.value)
                                    .contentTransition(.numericText())
                                    .animation(.snappy(duration: 0.2), value: spec.value)
                                    .frame(maxWidth: .infinity)
                                    .contentShape(Rectangle())
                            }
                            .buttonStyle(.plain)
                            .accessibilityLabel("\(spec.value) \(spec.label)")
                            .accessibilityHint("Type a number")
                        }
                    }
                    .font(.tabular(60, weight: .bold))
                    .lineLimit(1)
                    .minimumScaleFactor(0.5)
                    .frame(maxWidth: .infinity)
                    RepeatButton(systemImage: "plus", label: spec.incrementLabel) { spec.step(1) }
                }
                Button(typing ? "Set" : "Done") {
                    if typing { commit(spec) } else { dismiss() }
                }
                .buttonStyle(PrimaryButtonStyle())
                .disabled(typing && parsed == nil)
            }
            .padding()
        } else {
            Color.clear.onAppear { dismiss() }
        }
    }

    private var parsed: Double? {
        let value = Double(text.replacingOccurrences(of: ",", with: "."))
        guard let value, value >= 0, value < 10_000 else { return nil }
        return value
    }

    private func startTyping(_ spec: FieldSpec) {
        text = spec.current
        typing = true
        focused = true
    }

    private func commit(_ spec: FieldSpec) {
        guard let value = parsed else { return }
        spec.commit(value)
        typing = false
    }
}
