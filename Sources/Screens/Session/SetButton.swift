import SwiftUI
import GymBuddyCore

/// The one big button, and the clock along with it: Start set while resting
/// or before a timed set, End set once a set has begun. Its band drains
/// right→left as rest or a timed set runs out. `+30s` or `×` sits beside it
/// only while there's a clock to change.
struct SetButton: View {
    @Environment(AppModel.self) private var model
    let session: WorkoutSession
    var onLogged: () -> Void

    @State private var showingMulti = false
    /// A long press opens the several-sets dialog; the release that follows
    /// must not also log one.
    @State private var suppressTap = false

    var body: some View {
        Group {
            if session.isSetRunning || model.restTimer.isRunning {
                TimelineView(.periodic(from: .now, by: 0.25)) { context in
                    row(face(at: context.date))
                }
            } else {
                row(face(at: .now))
            }
        }
        .confirmationDialog("Log several identical sets", isPresented: $showingMulti, titleVisibility: .visible) {
            ForEach(2...max(2, remaining), id: \.self) { n in
                Button("Log \(n) sets") {
                    model.completeSets(n)
                    onLogged()
                }
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("For warm-ups: each at the reps and weight shown.")
        }
    }

    private var remaining: Int {
        session.currentEntry.map { $0.plan.targetSets - session.completedSets(for: $0.id) } ?? 0
    }

    private enum Side { case extend, cancel }

    private struct Face {
        var action: WorkoutSession.PrimaryAction
        var detail: String?
        /// Share of the countdown still to go; the band drains as it runs out.
        var remaining: Double?
        var timeUp = false
        var countdown: Int?
        var side: Side?
    }

    private func face(at now: Date) -> Face {
        let rest = model.restTimer
        let restOver = rest.hasFired(at: now)
        let action = session.primaryAction(resting: rest.isRunning && !restOver)
        if rest.isRunning, !restOver, !session.isSetRunning {
            let left = rest.remaining(at: now).rounded(.up)
            return Face(action: action, detail: "Rest " + RestTimer.format(left), remaining: 1 - rest.progress(at: now),
                        countdown: Int(left), side: .extend)
        }
        guard let began = session.setBegan(restEndedAt: restOver ? rest.endsAt : nil) else {
            return Face(action: action, detail: restOver ? "Rest over" : nil)
        }
        let elapsed = max(0, now.timeIntervalSince(began))
        guard let duration = session.setDuration, let left = session.setRemaining(at: now) else {
            return Face(action: action, detail: RestTimer.format(elapsed), side: session.isSetRunning ? .cancel : nil)
        }
        let up = session.isSetTimeUp(at: now)
        return Face(
            action: action,
            detail: up ? "Time's up +" + RestTimer.format(elapsed - duration) : RestTimer.format(left.rounded(.up)),
            remaining: duration > 0 ? max(0, 1 - elapsed / duration) : 0,
            timeUp: up,
            countdown: Int(left.rounded(.up)),
            side: .cancel
        )
    }

    private func row(_ face: Face) -> some View {
        HStack(spacing: 10) {
            main(face)
            switch face.side {
            case .extend:
                sideButton(label: "Add 30 seconds of rest", action: { model.extendRest() }) {
                    Text("+30s").font(.tabular(17, weight: .bold))
                }
            case .cancel:
                sideButton(label: "Cancel set timer", action: { model.cancelSet() }) {
                    Image(systemName: "xmark").font(.body.weight(.bold))
                }
            case nil:
                EmptyView()
            }
        }
        .onChange(of: face.countdown) { _, seconds in
            if let seconds { haptic(for: seconds) }
        }
    }

    private func main(_ face: Face) -> some View {
        Button { tap(face.action) } label: {
            VStack(spacing: 2) {
                HStack(spacing: 10) {
                    Image(systemName: Self.icon(face.action))
                        .font(.system(size: 20, weight: .heavy))
                    Text(Self.title(face.action))
                        .lineLimit(1)
                        .minimumScaleFactor(0.8)
                }
                .font(.system(size: 21, weight: .bold, design: .rounded))
                if let detail = face.detail {
                    Text(detail)
                        .font(.tabular(15, weight: .semibold))
                        .opacity(0.85)
                }
            }
            .padding(.horizontal, 12)
            .frame(maxWidth: .infinity, minHeight: 72)
            .background(alignment: .leading) {
                if let remaining = face.remaining {
                    GeometryReader { geo in
                        Color.black.opacity(0.18).frame(width: geo.size.width * remaining)
                    }
                }
            }
            .clipShape(RoundedRectangle(cornerRadius: Theme.Metrics.corner, style: .continuous))
        }
        .buttonStyle(PrimaryButtonStyle(tint: face.timeUp ? Theme.done : Theme.accent, height: 72))
        .simultaneousGesture(LongPressGesture(minimumDuration: 0.6).onEnded { _ in
            guard remaining > 1 else { return }
            suppressTap = true
            showingMulti = true
        })
        .accessibilityElement(children: .ignore)
        .accessibilityLabel([Self.title(face.action), face.detail].compactMap { $0 }.joined(separator: ", "))
        .accessibilityAddTraits(.isButton)
        .accessibilityAction { tap(face.action) }
        .accessibilityAction(named: "Log several sets") { if remaining > 1 { showingMulti = true } }
    }

    private func sideButton<Label: View>(label: String, action: @escaping () -> Void, @ViewBuilder content: () -> Label) -> some View {
        Button(action: action) {
            content()
                .foregroundStyle(Theme.accent)
                .frame(width: 72, height: 72)
                .background(RoundedRectangle(cornerRadius: Theme.Metrics.corner, style: .continuous).fill(Theme.fill))
                .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityLabel(label)
    }

    private func tap(_ action: WorkoutSession.PrimaryAction) {
        if suppressTap {
            suppressTap = false
            return
        }
        switch action {
        case .startSet: model.startSet()
        case .endSet, .endSetAndNextExercise, .endSetAndFinish:
            model.completeSets(1)
            onLogged()
        }
    }

    private static func title(_ action: WorkoutSession.PrimaryAction) -> String {
        switch action {
        case .startSet(let set): "Start set \(set)"
        case .endSet(let set): "End set \(set)"
        case .endSetAndNextExercise: "End set & next exercise"
        case .endSetAndFinish: "End set & finish"
        }
    }

    private static func icon(_ action: WorkoutSession.PrimaryAction) -> String {
        switch action {
        case .startSet: "play.fill"
        default: "checkmark"
        }
    }

    private func haptic(for seconds: Int) {
        guard model.settings.vibrate else { return }
        if seconds == 0 {
            UINotificationFeedbackGenerator().notificationOccurred(.success)
        } else if model.settings.countdownLastSeconds, (1...3).contains(seconds) {
            UIImpactFeedbackGenerator(style: .light).impactOccurred()
        }
    }
}
