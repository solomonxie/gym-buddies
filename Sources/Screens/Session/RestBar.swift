import SwiftUI
import GymBuddyCore

/// Sits above Log set and never replaces it — starting early is a choice the
/// app has no business blocking. The fill behind it is the ring, unrolled.
struct RestBar: View {
    @Environment(AppModel.self) private var model

    var body: some View {
        if model.restTimer.isRunning {
            TimelineView(.periodic(from: .now, by: 0.25)) { context in
                bar(at: context.date)
            }
            .transition(.opacity.combined(with: .scale(scale: 0.95)))
        }
    }

    private func bar(at now: Date) -> some View {
        let timer = model.restTimer
        let fired = timer.hasFired(at: now)
        let remaining = timer.remaining(at: now)
        return HStack(spacing: 8) {
            Image(systemName: fired ? "bell.fill" : "timer")
                .font(.body.weight(.semibold))
                .foregroundStyle(fired ? Theme.done : Theme.accent)
            Text(fired ? "Rest over" : "Rest")
                .font(.subheadline.weight(.semibold))
            if !fired {
                Text(RestTimer.format(remaining.rounded(.up)))
                    .font(.tabular(20, weight: .bold))
            }
            Spacer()
            if !fired {
                Button("+30s") { model.extendRest() }
                    .buttonStyle(SoftButtonStyle())
                    .accessibilityLabel("Add 30 seconds of rest")
            }
            Button { model.dismissRest() } label: {
                Image(systemName: "xmark")
                    .font(.subheadline.weight(.bold))
                    .foregroundStyle(.secondary)
                    .frame(width: 44, height: 44)
                    .background(Circle().fill(Theme.fill))
            }
            .accessibilityLabel("Dismiss rest")
        }
        .padding(.leading, 16)
        .padding(.trailing, 8)
        .frame(minHeight: Theme.tapTarget)
        .background(
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    Theme.card
                    (fired ? Theme.done : Theme.accent).opacity(0.16)
                        .frame(width: geo.size.width * timer.progress(at: now))
                }
            }
        )
        .clipShape(RoundedRectangle(cornerRadius: Theme.Metrics.corner, style: .continuous))
        .onChange(of: Int(remaining.rounded(.up))) { _, seconds in
            haptic(for: seconds)
        }
        .accessibilityElement(children: .contain)
        .accessibilityLabel(fired ? "Rest over" : "Resting, \(Int(remaining.rounded(.up))) seconds left")
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
