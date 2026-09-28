import SwiftUI
import GymBuddyCore

/// One bar above the big button for both clocks — rest between sets, and the
/// set itself once started. They never run together. The fill is the ring,
/// unrolled; a rep set counts up with no fill.
struct TimerBar: View {
    @Environment(AppModel.self) private var model
    let session: WorkoutSession

    var body: some View {
        if session.isSetRunning || model.restTimer.isRunning {
            TimelineView(.periodic(from: .now, by: 0.25)) { context in
                bar(clock(at: context.date))
            }
            .transition(.opacity.combined(with: .scale(scale: 0.95)))
        }
    }

    private struct Clock {
        var icon: String
        var title: String
        var readout: String?
        var progress: Double?
        var fired: Bool
        var countdown: Int?
        var accessibility: String
        var canExtend: Bool
        var dismissLabel: String
        var dismiss: () -> Void
    }

    private func clock(at now: Date) -> Clock {
        if session.isSetRunning {
            let elapsed = session.setElapsed(at: now)
            let remaining = session.setRemaining(at: now)
            let up = session.isSetTimeUp(at: now)
            let readout = up
                ? "+" + RestTimer.format(elapsed - (session.setDuration ?? 0))
                : RestTimer.format(remaining?.rounded(.up) ?? elapsed)
            return Clock(
                icon: up ? "bell.fill" : "stopwatch",
                title: up ? "Time's up" : "Set \(session.currentSetNumber)",
                readout: readout,
                progress: session.setDuration.map { $0 > 0 ? min(1, elapsed / $0) : 1 },
                fired: up,
                countdown: remaining.map { Int($0.rounded(.up)) },
                accessibility: up ? "Time's up"
                    : remaining.map { "\(LoadFormat.duration($0.rounded(.up))) left" }
                    ?? "Set running, \(LoadFormat.duration(elapsed))",
                canExtend: false,
                dismissLabel: "Cancel set timer",
                dismiss: { model.cancelSet() }
            )
        }
        let timer = model.restTimer
        let fired = timer.hasFired(at: now)
        let remaining = timer.remaining(at: now)
        return Clock(
            icon: fired ? "bell.fill" : "timer",
            title: fired ? "Rest over" : "Rest",
            readout: fired ? nil : RestTimer.format(remaining.rounded(.up)),
            progress: timer.progress(at: now),
            fired: fired,
            countdown: Int(remaining.rounded(.up)),
            accessibility: fired ? "Rest over" : "Resting, \(Int(remaining.rounded(.up))) seconds left",
            canExtend: !fired,
            dismissLabel: "Dismiss rest",
            dismiss: { model.dismissRest() }
        )
    }

    private func bar(_ clock: Clock) -> some View {
        let tint = clock.fired ? Theme.done : Theme.accent
        return HStack(spacing: 8) {
            Image(systemName: clock.icon)
                .font(.body.weight(.semibold))
                .foregroundStyle(tint)
            Text(clock.title)
                .font(.subheadline.weight(.semibold))
            if let readout = clock.readout {
                Text(readout)
                    .font(.tabular(20, weight: .bold))
            }
            Spacer()
            if clock.canExtend {
                Button("+30s") { model.extendRest() }
                    .buttonStyle(SoftButtonStyle())
                    .accessibilityLabel("Add 30 seconds of rest")
            }
            Button(action: clock.dismiss) {
                Image(systemName: "xmark")
                    .font(.subheadline.weight(.bold))
                    .foregroundStyle(.secondary)
                    .frame(width: 44, height: 44)
                    .background(Circle().fill(Theme.fill))
            }
            .accessibilityLabel(clock.dismissLabel)
        }
        .padding(.leading, 16)
        .padding(.trailing, 8)
        .frame(minHeight: Theme.tapTarget)
        .background(
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    Theme.card
                    if let progress = clock.progress {
                        tint.opacity(0.16).frame(width: geo.size.width * progress)
                    }
                }
            }
        )
        .clipShape(RoundedRectangle(cornerRadius: Theme.Metrics.corner, style: .continuous))
        .onChange(of: clock.countdown) { _, seconds in
            if let seconds { haptic(for: seconds) }
        }
        .accessibilityElement(children: .contain)
        .accessibilityLabel(clock.accessibility)
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
