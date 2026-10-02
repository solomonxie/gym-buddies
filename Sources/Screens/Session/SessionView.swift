import SwiftUI
import GymBuddyCore

/// The active workout. Everything on it is sized by how often it's touched:
/// end a set fifty times, ± a few times, everything else almost never.
struct SessionView: View {
    @Environment(AppModel.self) private var model
    @State private var showingJump = false
    @State private var showingExit = false
    @State private var showingSets = false
    @State private var editing: SessionField?
    @State private var logged = 0

    var body: some View {
        @Bindable var model = model
        Group {
            if let session = model.session {
                content(session)
            } else {
                Color.clear.onAppear { model.isSessionPresented = false }
            }
        }
        .sheet(item: Binding(
            get: { model.pendingSummary.map { SummaryItem(session: $0) } },
            set: { if $0 == nil { model.pendingSummary = nil } }
        )) { item in
            SummarySheet(session: item.session)
                .interactiveDismissDisabled()
        }
    }

    private func content(_ session: WorkoutSession) -> some View {
        VStack(spacing: 0) {
            header(session)
            ProgressStrip(session: session)
                .padding(.horizontal, Theme.Metrics.gutter)
                .padding(.bottom, 12)
            if let entry = session.currentEntry {
                current(session, entry)
            } else {
                finished(session)
            }
        }
        .background(Theme.surface.ignoresSafeArea())
        .sensoryFeedback(.success, trigger: logged)
        .sheet(isPresented: $showingJump) { JumpSheet() }
        .sheet(item: $editing) { field in
            AdjustSheet(field: field)
                .presentationDetents([.height(260)])
        }
        .confirmationDialog(
            session.hasLoggedAnything ? "Finish this workout?" : "Leave?",
            isPresented: $showingExit, titleVisibility: .visible
        ) {
            Button("Keep in background") { model.isSessionPresented = false }
            if session.hasLoggedAnything {
                Button("Save & exit") {
                    if session.driftedLineIDs.isEmpty { model.saveSession(updatingPlan: false) }
                    else { model.pendingSummary = session }
                }
                Button("Discard", role: .destructive) { model.discardSession() }
            } else {
                Button("Leave", role: .destructive) { model.discardSession() }
            }
            Button("Keep going", role: .cancel) {}
        } message: {
            if session.hasLoggedAnything {
                let minutes = Int(session.elapsed(at: .now) / 60)
                Text("\(session.logs.count) set\(session.logs.count == 1 ? "" : "s") logged, \(minutes) minute\(minutes == 1 ? "" : "s").")
            } else {
                Text("Nothing was logged, so nothing will be saved.")
            }
        }
    }

    // MARK: - Header

    private func header(_ session: WorkoutSession) -> some View {
        HStack {
            circleButton("xmark", label: "Exit workout") { showingExit = true }
            Spacer()
            VStack(spacing: 1) {
                Text(session.workoutName)
                    .font(.subheadline.weight(.semibold))
                    .lineLimit(1)
                TimelineView(.periodic(from: .now, by: 1)) { context in
                    Text(RestTimer.format(session.elapsed(at: context.date)))
                        .font(.tabular(13, weight: .medium))
                        .foregroundStyle(.secondary)
                        .accessibilityLabel("Elapsed \(LoadFormat.duration(session.elapsed(at: context.date)))")
                }
            }
            Spacer()
            circleButton("list.bullet", label: "All exercises") { showingJump = true }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 6)
    }

    private func circleButton(_ systemImage: String, label: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Image(systemName: systemImage)
                .font(.body.weight(.semibold))
                .foregroundStyle(.primary)
                .frame(width: 44, height: 44)
                .background(Circle().fill(Theme.fill))
                .frame(width: Theme.tapTarget, height: Theme.tapTarget)
                .contentShape(Rectangle())
        }
        .accessibilityLabel(label)
    }

    // MARK: - Current exercise

    private func current(_ session: WorkoutSession, _ entry: WorkoutSession.Entry) -> some View {
        VStack(spacing: 0) {
            ScrollView {
                VStack(alignment: .leading, spacing: 14) {
                    exerciseTitle(entry)
                    setRow(session, entry)
                    if showingSets { changeSets(session, entry) }
                    ProgressionOffer(session: session, entry: entry)
                    HStack(alignment: .center, spacing: 12) {
                        if !entry.exercise.muscles.isEmpty {
                            MuscleMap(highlighted: entry.exercise.muscles)
                                .frame(maxWidth: .infinity, maxHeight: 220)
                                .opacity(0.8)
                        }
                        ValueColumn(editing: $editing)
                            .frame(maxWidth: entry.exercise.muscles.isEmpty ? .infinity : 150)
                    }
                    .padding(.top, 4)
                }
                .padding(.horizontal, Theme.Metrics.gutter)
            }
            .scrollBounceBehavior(.basedOnSize)

            VStack(spacing: 10) {
                SetButton(session: session) { logged += 1 }
                upNext(session)
            }
            .padding(.horizontal, Theme.Metrics.gutter)
            .padding(.bottom, 4)
        }
        .animation(.snappy, value: showingSets)
        .animation(.snappy, value: model.restTimer.isRunning)
        .animation(.snappy, value: session.isSetRunning)
        .animation(.snappy, value: entry.id)
    }

    private func exerciseTitle(_ entry: WorkoutSession.Entry) -> some View {
        HStack(alignment: .top, spacing: 12) {
            VStack(alignment: .leading, spacing: 4) {
                Text(entry.exercise.name)
                    .font(.system(size: 28, weight: .bold, design: .rounded))
                    .lineLimit(2)
                    .minimumScaleFactor(0.7)
                    .fixedSize(horizontal: false, vertical: true)
                Text("\(entry.exercise.muscleGroup.displayName) · \(entry.exercise.equipment.displayName)")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
            Spacer()
            if let back = model.session?.backEntry {
                Button { model.goBack() } label: {
                    Image(systemName: "backward.end.fill")
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(.secondary)
                        .frame(width: 44, height: 44)
                        .background(Circle().fill(Color.secondary.opacity(0.14)))
                        .frame(width: Theme.tapTarget, height: Theme.tapTarget)
                        .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                .accessibilityLabel("Back to \(back.exercise.name)")
            }
            Button { model.skipExercise() } label: {
                Label("Skip", systemImage: "forward.end.fill")
                    .labelStyle(.titleAndIcon)
                    .font(.subheadline.weight(.semibold))
            }
            .buttonStyle(SoftButtonStyle(tint: .secondary))
            .frame(minHeight: Theme.tapTarget)
            .accessibilityLabel("Skip \(entry.exercise.name)")
        }
        .padding(.top, 4)
    }

    private func setRow(_ session: WorkoutSession, _ entry: WorkoutSession.Entry) -> some View {
        HStack(alignment: .center) {
            Button { showingSets.toggle() } label: {
                HStack(spacing: 10) {
                    SetDots(done: session.completedSets(for: entry.id), total: entry.plan.targetSets)
                    Text("Set \(session.currentSetNumber) of \(entry.plan.targetSets)")
                        .font(.tabular(16, weight: .semibold))
                        .foregroundStyle(.primary)
                    Image(systemName: "chevron.down")
                        .font(.caption.weight(.bold))
                        .foregroundStyle(.secondary)
                        .rotationEffect(.degrees(showingSets ? 180 : 0))
                }
                .frame(minHeight: 44)
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .accessibilityHint("Change the number of sets")
            Spacer()
            VStack(alignment: .trailing, spacing: 1) {
                Text("Last time").eyebrow()
                Text(lastTimeText(session, entry))
                    .font(.tabular(15, weight: .medium))
                    .foregroundStyle(.secondary)
            }
            .accessibilityElement(children: .combine)
        }
    }

    private func lastTimeText(_ session: WorkoutSession, _ entry: WorkoutSession.Entry) -> String {
        guard let last = Stats.lastTime(exerciseID: entry.exercise.id, setNumber: session.currentSetNumber, measure: entry.measure, in: model.logs)
        else { return "—" }
        let reps = LoadFormat.reps(last.reps, measure: last.measure(for: entry.exercise))
        guard let load = LoadFormat.load(weight: last.weight, incline: last.incline, exercise: entry.exercise, unit: model.unit)
        else { return reps }
        return entry.exercise.equipment.inclineStep == nil ? "\(reps) × \(load)" : "\(reps) · \(load)"
    }

    private func changeSets(_ session: WorkoutSession, _ entry: WorkoutSession.Entry) -> some View {
        let upper = max(6, entry.plan.targetSets + 2)
        return VStack(alignment: .leading, spacing: 8) {
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    ForEach(1...upper, id: \.self) { n in
                        let current = n == entry.plan.targetSets
                        let allowed = n >= session.minimumTargetSets
                        Button {
                            model.changeTargetSets(to: n)
                            showingSets = false
                        } label: {
                            Text("\(n)")
                                .font(.tabular(18, weight: .semibold))
                                .frame(width: 52, height: 52)
                                .foregroundStyle(current ? Color(.systemBackground) : .primary)
                                .background(Circle().fill(current ? Color.primary : Theme.fill))
                        }
                        .buttonStyle(.plain)
                        .disabled(!allowed)
                        .opacity(allowed ? 1 : 0.3)
                        .accessibilityLabel("\(n) sets")
                    }
                }
            }
            if session.minimumTargetSets > 1 {
                Text("\(session.minimumTargetSets) already logged, so fewer isn't offered.")
                    .font(.caption).foregroundStyle(.secondary)
            }
        }
        .transition(.opacity.combined(with: .move(edge: .top)))
    }

    // MARK: - Up next

    @ViewBuilder
    private func upNext(_ session: WorkoutSession) -> some View {
        if let next = session.upcoming.first(where: { !session.isComplete($0) && !$0.isSkipped }) {
            Button { showingJump = true } label: {
                HStack(spacing: 6) {
                    Text("Next").foregroundStyle(.secondary)
                    Text(next.exercise.name).foregroundStyle(.primary).lineLimit(1)
                    Spacer(minLength: 4)
                    Text(LoadFormat.line(next.plan, exercise: next.exercise, unit: model.unit)
                        .replacingOccurrences(of: #" · rest \d+s"#, with: "", options: .regularExpression))
                        .foregroundStyle(.secondary)
                        .monospacedDigit()
                    Image(systemName: "chevron.up").font(.caption.weight(.bold)).foregroundStyle(.tertiary)
                }
                .font(.subheadline)
                .frame(minHeight: 44)
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .accessibilityHint("Shows every exercise")
        } else {
            Color.clear.frame(height: 8)
        }
    }

    private func finished(_ session: WorkoutSession) -> some View {
        VStack(spacing: 16) {
            Spacer()
            Image(systemName: "checkmark.circle")
                .font(.system(size: 56, weight: .light))
                .foregroundStyle(.secondary)
            Text("Every exercise is done or skipped.")
                .foregroundStyle(.secondary)
            Button("Go back to one") { showingJump = true }
                .buttonStyle(SoftButtonStyle())
            Spacer()
            Button("Finish workout") { model.pendingSummary = session }
                .buttonStyle(PrimaryButtonStyle(height: 72))
                .padding()
        }
    }
}

/// ● ● ○ — sets done and to go.
struct SetDots: View {
    let done: Int
    let total: Int

    var body: some View {
        HStack(spacing: 5) {
            ForEach(0..<min(total, 10), id: \.self) { i in
                Circle()
                    .fill(i < done ? Theme.accent : Theme.fill)
                    .frame(width: 9, height: 9)
            }
        }
        .accessibilityHidden(true)
    }
}

/// One segment per exercise: filled when done, accent while current.
struct ProgressStrip: View {
    let session: WorkoutSession

    var body: some View {
        HStack(spacing: 4) {
            ForEach(Array(session.entries.enumerated()), id: \.element.id) { index, entry in
                Capsule()
                    .fill(color(index, entry))
                    .frame(height: 4)
            }
        }
        .accessibilityElement()
        .accessibilityLabel("\(session.entries.filter { session.isComplete($0) }.count) of \(session.entries.count) exercises done")
    }

    private func color(_ index: Int, _ entry: WorkoutSession.Entry) -> Color {
        if session.isComplete(entry) { return Color.primary.opacity(0.75) }
        if index == session.exerciseIndex { return Theme.accent }
        if entry.isSkipped { return Theme.fill.opacity(0.5) }
        return Theme.fill
    }
}

private struct SummaryItem: Identifiable {
    let session: WorkoutSession
    var id: String { session.id }
}
