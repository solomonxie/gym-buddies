import GymBuddyCore
import SwiftUI

/// The session kept in the background: a bar above the tab bar that shows
/// the live clock and opens the session again on tap.
struct MiniSessionBar: View {
    @Environment(AppModel.self) private var model

    var body: some View {
        if let session = model.session, !model.isSessionPresented {
            Button { model.resume() } label: {
                HStack(spacing: 12) {
                    VStack(alignment: .leading, spacing: 2) {
                        Text(session.workoutName)
                            .font(.subheadline.weight(.semibold))
                            .lineLimit(1)
                        Text(detail(session))
                            .font(.caption)
                            .foregroundStyle(.secondary)
                            .lineLimit(1)
                    }
                    Spacer(minLength: 8)
                    TimelineView(.periodic(from: .now, by: 1)) { context in
                        let clock = clock(session, at: context.date)
                        Label(clock.text, systemImage: clock.icon)
                            .font(.tabular(17, weight: .bold))
                            .foregroundStyle(clock.tint)
                    }
                    Image(systemName: "chevron.up")
                        .font(.caption.weight(.bold))
                        .foregroundStyle(.tertiary)
                }
                .padding(.horizontal, 16)
                .frame(minHeight: 56)
                .background(RoundedRectangle(cornerRadius: Theme.Metrics.corner, style: .continuous).fill(Theme.card))
                .shadow(color: .black.opacity(0.12), radius: 8, y: 2)
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .padding(.horizontal, 12)
            .padding(.bottom, 6)
            .accessibilityLabel("\(session.workoutName) in progress")
            .accessibilityHint("Opens the workout")
        }
    }

    private func detail(_ session: WorkoutSession) -> String {
        guard let entry = session.currentEntry else { return "Every exercise is done or skipped" }
        return "\(entry.exercise.name) · Set \(session.currentSetNumber) of \(entry.plan.targetSets)"
    }

    /// Whichever clock the Session screen's set button would show, else elapsed.
    private func clock(_ session: WorkoutSession, at now: Date) -> (text: String, icon: String, tint: Color) {
        if session.isSetRunning {
            if session.isSetTimeUp(at: now) { return ("Time's up", "bell.fill", Theme.done) }
            let shown = session.setRemaining(at: now)?.rounded(.up) ?? session.setElapsed(at: now)
            return (RestTimer.format(shown), "stopwatch", Theme.accent)
        }
        let rest = model.restTimer
        if rest.isRunning {
            if rest.hasFired(at: now) { return ("Rest over", "bell.fill", Theme.done) }
            return (RestTimer.format(rest.remaining(at: now).rounded(.up)), "timer", Theme.accent)
        }
        return (RestTimer.format(session.elapsed(at: now)), "clock", .secondary)
    }
}

extension View {
    func miniSessionBar() -> some View {
        safeAreaInset(edge: .bottom, spacing: 0) { MiniSessionBar() }
    }
}
