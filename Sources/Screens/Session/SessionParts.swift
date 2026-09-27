import SwiftUI
import GymBuddyCore

// MARK: - Progression offer

/// Once per exercise per session, and always a question — an app that moves
/// the pin for you is one you stop trusting the first time it's wrong.
struct ProgressionOffer: View {
    let session: WorkoutSession
    let entry: WorkoutSession.Entry
    @Environment(AppModel.self) private var model

    var body: some View {
        if let offer {
            VStack(alignment: .leading, spacing: 12) {
                Label(offer.text, systemImage: "arrow.up.right")
                    .font(.subheadline.weight(.medium))
                HStack(spacing: 8) {
                    Button("Not today") { decline() }
                        .buttonStyle(SoftButtonStyle(tint: .secondary))
                    Button("Use \(LoadFormat.weight(offer.weight, model.unit))") { accept(offer.weight) }
                        .buttonStyle(SoftButtonStyle())
                }
            }
            .card(padding: 14)
            .transition(.opacity)
        }
    }

    private var offer: (text: String, weight: Weight)? {
        guard model.settings.suggestHeavier,
              session.currentSetNumber == 1,
              session.completedSets(for: entry.id) == 0,
              !session.progressionOffered.contains(entry.id)
        else { return nil }
        let suggestion = Progression.suggest(
            for: entry.plan, equipment: entry.exercise.equipment, history: model.logs, unit: model.unit
        )
        let plan = "\(entry.plan.targetSets) × \(LoadFormat.reps(entry.plan.targetReps, measure: entry.exercise.measure))"
        switch suggestion {
        case .increase(let to, _) where to != session.workingWeight:
            return ("Hit all \(plan) last time. Try \(LoadFormat.weight(to, model.unit))?", to)
        case .deload(let to, _) where to != session.workingWeight:
            return ("Short of \(plan) twice running. Try \(LoadFormat.weight(to, model.unit))?", to)
        default:
            return nil
        }
    }

    private func accept(_ weight: Weight) {
        model.updateSession {
            $0.setWorkingValues(weight: weight)
            $0.markProgressionOffered(for: entry.id)
        }
    }

    private func decline() {
        model.updateSession { $0.markProgressionOffered(for: entry.id) }
    }
}

// MARK: - Jump sheet

struct JumpSheet: View {
    @Environment(AppModel.self) private var model
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            List {
                if let session = model.session {
                    ForEach(Array(session.entries.enumerated()), id: \.element.id) { index, entry in
                        Button {
                            model.updateSession { $0.jump(toExerciseAt: index) }
                            dismiss()
                        } label: {
                            row(session, index, entry)
                        }
                        .disabled(session.isComplete(entry))
                    }
                }
            }
            .navigationTitle("Jump to")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) { Button("Done") { dismiss() } }
            }
        }
        .presentationDetents([.medium, .large])
    }

    private func row(_ session: WorkoutSession, _ index: Int, _ entry: WorkoutSession.Entry) -> some View {
        let done = session.completedSets(for: entry.id)
        let isCurrent = index == session.exerciseIndex
        return HStack(spacing: 10) {
            Group {
                if session.isComplete(entry) {
                    Image(systemName: "checkmark.circle.fill").foregroundStyle(Theme.done)
                } else if isCurrent {
                    Image(systemName: "circle.fill").font(.caption).foregroundStyle(Theme.accent)
                } else {
                    Color.clear
                }
            }
            .frame(width: 20)
            Text(entry.exercise.name)
                .foregroundStyle(session.isComplete(entry) ? .secondary : .primary)
                .lineLimit(1)
            Spacer()
            Text(status(session, entry, done: done, isCurrent: isCurrent))
                .font(.subheadline.monospacedDigit())
                .foregroundStyle(.secondary)
        }
        .frame(minHeight: 44)
        .contentShape(Rectangle())
    }

    private func status(_ session: WorkoutSession, _ entry: WorkoutSession.Entry, done: Int, isCurrent: Bool) -> String {
        if session.isComplete(entry) {
            return LoadFormat.summary(session.logs.filter { $0.planLineID == entry.id }, exercise: entry.exercise, unit: model.unit)
        }
        if entry.isSkipped { return "skipped" }
        if done > 0 || isCurrent { return "\(done) of \(entry.plan.targetSets) done" }
        return LoadFormat.line(sets: entry.plan.targetSets, reps: entry.plan.targetReps,
                               weight: entry.plan.targetWeight, exercise: entry.exercise, unit: model.unit,
                               incline: entry.plan.targetIncline)
    }
}

// MARK: - Keypad

enum KeypadField: String, Identifiable {
    case reps, weight, incline
    var id: String { rawValue }
}

/// For when ± is the wrong tool: 50 → 135 is not a job for a stepper.
struct KeypadSheet: View {
    let field: KeypadField
    @Environment(AppModel.self) private var model
    @Environment(\.dismiss) private var dismiss
    @State private var text = ""
    @FocusState private var focused: Bool

    var body: some View {
        VStack(spacing: 16) {
            Text(title).font(.headline)
            TextField("0", text: $text)
                .keyboardType(field == .reps ? .numberPad : .decimalPad)
                .accessibilityLabel(title)
                .font(.tabular(56))
                .multilineTextAlignment(.center)
                .focused($focused)
            HStack(spacing: 12) {
                Button("Cancel") { dismiss() }
                    .buttonStyle(.bordered)
                    .frame(maxWidth: .infinity)
                Button("Set") { commit() }
                    .buttonStyle(PrimaryButtonStyle())
                    .disabled(parsed == nil)
            }
            .controlSize(.large)
        }
        .padding()
        .onAppear {
            guard let session = model.session else { return }
            text = switch field {
            case .reps: "\(session.workingReps)"
            case .weight: LoadFormat.number(session.workingWeight.value(in: model.unit))
            case .incline: LoadFormat.number(session.workingIncline ?? 0)
            }
            focused = true
        }
    }

    private var title: String {
        switch field {
        case .reps: model.session?.currentEntry?.exercise.measure.displayName ?? "Reps"
        case .weight: "Weight (\(model.unit.abbreviation))"
        case .incline: "Incline (%)"
        }
    }

    private var parsed: Double? {
        let value = Double(text.replacingOccurrences(of: ",", with: "."))
        guard let value, value >= 0, value < 10_000 else { return nil }
        return value
    }

    private func commit() {
        guard let value = parsed else { return }
        model.updateSession {
            switch field {
            case .reps: $0.setWorkingValues(reps: Int(value))
            case .weight: $0.setWorkingValues(weight: Weight(value, model.unit))
            case .incline: $0.setWorkingValues(incline: value)
            }
        }
        dismiss()
    }
}

// MARK: - Summary

/// States what happened and stops. No confetti.
struct SummarySheet: View {
    let session: WorkoutSession
    @Environment(AppModel.self) private var model
    @State private var updatePlan = false
    @State private var notes = ""
    @State private var confirmingDiscard = false

    var body: some View {
        let log = session.finish(at: .now)
        let records = Stats.records(in: log, history: model.logs + [log])
        let drift = session.weightDrift
        let inclineDrift = session.inclineDrift
        let drifted = session.driftedLineIDs
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 12) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(session.isFinished ? "Workout complete" : "Finishing early").eyebrow()
                        Text(session.workoutName)
                            .font(.system(size: 30, weight: .bold, design: .rounded))
                    }
                    .padding(.horizontal, 4)

                    HStack(spacing: 10) {
                        StatTile(value: LoadFormat.duration(log.duration), label: "Time")
                        StatTile(value: "\(log.sets.count)", label: "Sets")
                        StatTile(value: LoadFormat.volume(Stats.volume(log.sets).value(in: model.unit), model.unit), label: "Moved")
                    }

                    if !records.isEmpty {
                        VStack(alignment: .leading, spacing: 10) {
                            Text("Personal records").eyebrow()
                            ForEach(records) { set in
                                if let e = model.exercisesByID[set.exerciseID] {
                                    HStack {
                                        Image(systemName: "star.fill").foregroundStyle(Theme.record)
                                        Text(e.name)
                                        Spacer()
                                        Text("\(LoadFormat.weight(set.weight, model.unit)) × \(set.reps)").monospacedDigit()
                                    }
                                    .font(.body.weight(.medium))
                                }
                            }
                        }
                        .card()
                    }

                    if !log.skippedExerciseIDs.isEmpty {
                        VStack(alignment: .leading, spacing: 6) {
                            Text("Skipped").eyebrow()
                            Text(log.skippedExerciseIDs.compactMap { model.exercisesByID[$0]?.name }.joined(separator: ", "))
                                .foregroundStyle(.secondary)
                        }
                        .card()
                    }

                    if !drifted.isEmpty {
                        VStack(alignment: .leading, spacing: 12) {
                            Text("\(inclineDrift.isEmpty ? "Weights" : drift.isEmpty ? "Incline" : "Weights and incline") differed from the plan on \(drifted.count) line\(drifted.count == 1 ? "" : "s"). Update the workout?")
                                .font(.subheadline.weight(.medium))
                            Picker("Plan", selection: $updatePlan) {
                                Text("Leave the plan").tag(false)
                                Text("Update it").tag(true)
                            }
                            .pickerStyle(.segmented)
                            ForEach(session.entries.filter { drifted.contains($0.id) }) { entry in
                                HStack {
                                    Text(entry.exercise.name).lineLimit(1)
                                    Spacer()
                                    Group {
                                        if let weight = drift[entry.id] {
                                            Text("\(LoadFormat.weight(entry.plan.targetWeight, model.unit)) → \(LoadFormat.weight(weight, model.unit))")
                                        } else if let incline = inclineDrift[entry.id] {
                                            Text("\(LoadFormat.incline(entry.plan.targetIncline ?? 0)) → \(LoadFormat.incline(incline))")
                                        }
                                    }
                                    .monospacedDigit()
                                }
                                .font(.subheadline)
                                .foregroundStyle(updatePlan ? .primary : .secondary)
                            }
                        }
                        .card()
                    }

                    VStack(alignment: .leading, spacing: 8) {
                        Text("Notes").eyebrow()
                        TextField("How it went, anything to remember", text: $notes, axis: .vertical)
                            .lineLimit(2...6)
                    }
                    .card()
                }
                .padding(Theme.Metrics.gutter)
            }
            .background(Theme.surface)
            .scrollDismissesKeyboard(.interactively)
            .toolbar {
                if !session.isFinished {
                    ToolbarItem(placement: .cancellationAction) {
                        Button("Keep going") { model.pendingSummary = nil }
                    }
                }
            }
            .safeAreaInset(edge: .bottom) {
                HStack(spacing: 10) {
                    Button("Discard", role: .destructive) { confirmingDiscard = true }
                        .buttonStyle(SoftButtonStyle(tint: .red))
                    Button("Save") {
                        model.updateSession { $0.notes = notes }
                        model.saveSession(updatingPlan: updatePlan)
                    }
                    .buttonStyle(PrimaryButtonStyle())
                }
                .padding(.horizontal, Theme.Metrics.gutter)
                .padding(.vertical, 10)
                .background(.bar)
            }
            .alert("Discard this workout?", isPresented: $confirmingDiscard) {
                Button("Cancel", role: .cancel) {}
                Button("Discard", role: .destructive) { model.discardSession() }
            } message: {
                Text("\(log.sets.count) logged set\(log.sets.count == 1 ? "" : "s") won't be saved.")
            }
            .onAppear { notes = session.notes }
        }
    }
}
