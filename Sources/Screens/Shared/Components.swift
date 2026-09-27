import SwiftUI
import GymBuddyCore

// MARK: - Primary action

/// The one filled button on a screen: full width, 64pt, the accent.
struct PrimaryButtonStyle: ButtonStyle {
    var tint: Color = Theme.accent
    var height: CGFloat = 64
    @Environment(\.isEnabled) private var isEnabled

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.system(size: 19, weight: .bold, design: .rounded))
            .foregroundStyle(.white)
            .frame(maxWidth: .infinity, minHeight: height)
            .background(
                RoundedRectangle(cornerRadius: Theme.Metrics.corner, style: .continuous)
                    .fill(isEnabled ? tint : Color.gray.opacity(0.35))
            )
            .scaleEffect(configuration.isPressed ? 0.97 : 1)
            .animation(.spring(duration: 0.2), value: configuration.isPressed)
            .contentShape(Rectangle())
    }
}

/// Quiet secondary action: tinted text on a soft fill.
struct SoftButtonStyle: ButtonStyle {
    var tint: Color = Theme.accent

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.system(.body, design: .rounded).weight(.semibold))
            .foregroundStyle(tint)
            .padding(.horizontal, 16)
            .frame(minHeight: 44)
            .background(Capsule().fill(tint.opacity(0.14)))
            .opacity(configuration.isPressed ? 0.6 : 1)
            .contentShape(Capsule())
    }
}

// MARK: - Steppers

/// A round − or + that repeats, accelerating, while held.
struct RepeatButton: View {
    let systemImage: String
    let label: String
    var size: CGFloat = Theme.tapTarget
    let action: () -> Void

    @State private var repeater: Task<Void, Never>?
    @State private var fired = false
    @State private var pressed = false

    var body: some View {
        Image(systemName: systemImage)
            .font(.system(size: size * 0.36, weight: .semibold))
            .foregroundStyle(.primary)
            .frame(width: size, height: size)
            .background(Circle().fill(Theme.fill))
            .scaleEffect(pressed ? 0.92 : 1)
            .animation(.spring(duration: 0.2), value: pressed)
            .contentShape(Circle())
            .onLongPressGesture(minimumDuration: 0.35, maximumDistance: 30) {
                startRepeating()
            } onPressingChanged: { pressing in
                pressed = pressing
                if !pressing { stopRepeating() }
            }
            .simultaneousGesture(TapGesture().onEnded {
                if !fired { action() }
                fired = false
            })
            .sensoryFeedback(.selection, trigger: pressed) { _, new in new }
            .accessibilityElement()
            .accessibilityLabel(label)
            .accessibilityAddTraits(.isButton)
            .accessibilityAction { action() }
    }

    /// Repeats while held, getting faster every five steps.
    private func startRepeating() {
        fired = true
        repeater?.cancel()
        repeater = Task { @MainActor in
            var interval = 0.18
            var count = 0
            while !Task.isCancelled {
                action()
                count += 1
                if count % 5 == 0 { interval = max(0.05, interval * 0.6) }
                try? await Task.sleep(for: .seconds(interval))
            }
        }
    }

    private func stopRepeating() {
        repeater?.cancel()
        repeater = nil
    }
}

/// Compact stepper for the workout line editor, outside the Session screen.
struct LineStepper: View {
    let title: String
    let value: String
    var detail: String?
    let decrement: () -> Void
    let increment: () -> Void
    var canDecrement = true

    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                if let detail {
                    Text(detail).font(.caption).foregroundStyle(.secondary)
                }
            }
            Spacer()
            Button(action: decrement) {
                Image(systemName: "minus").frame(width: 44, height: 44)
            }
            .disabled(!canDecrement)
            .accessibilityLabel("Decrease \(title)")
            Text(value)
                .font(.tabular(20, weight: .semibold))
                .frame(minWidth: 64)
                .accessibilityLabel("\(title) \(value)")
            Button(action: increment) {
                Image(systemName: "plus").frame(width: 44, height: 44)
            }
            .accessibilityLabel("Increase \(title)")
        }
        .buttonStyle(.bordered)
        .buttonBorderShape(.roundedRectangle(radius: 10))
    }
}

// MARK: - Rows

/// Equipment glyph on a soft rounded square — the row's only picture.
struct GlyphTile: View {
    let equipment: Equipment
    var size: CGFloat = 40

    var body: some View {
        Image(systemName: EquipmentGlyph.symbol(for: equipment))
            .font(.system(size: size * 0.45, weight: .medium))
            .foregroundStyle(Theme.accent)
            .frame(width: size, height: size)
            .background(RoundedRectangle(cornerRadius: size * 0.3, style: .continuous).fill(Theme.accentSoft))
            .accessibilityHidden(true)
    }
}

struct ExerciseRow: View {
    let exercise: Exercise
    var onFavourite: (() -> Void)?

    var body: some View {
        HStack(spacing: 14) {
            GlyphTile(equipment: exercise.equipment)
            VStack(alignment: .leading, spacing: 2) {
                Text(exercise.name)
                    .font(.body.weight(.medium))
                    .lineLimit(1)
                Text(exercise.isCustom ? "\(exercise.equipment.displayName) · yours" : exercise.equipment.displayName)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
            Spacer(minLength: 8)
            if let onFavourite {
                Button(action: onFavourite) {
                    Image(systemName: exercise.isFavourite ? "heart.fill" : "heart")
                        .font(.body)
                        .foregroundStyle(exercise.isFavourite ? Theme.accent : Color.secondary.opacity(0.35))
                        .frame(width: 44, height: 44)
                        .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                .sensoryFeedback(.impact(weight: .light), trigger: exercise.isFavourite)
                .accessibilityLabel(exercise.isFavourite ? "Remove from favourites" : "Add to favourites")
            }
        }
        .padding(.vertical, 2)
    }
}

/// One logged set: `1  10 reps   50 lb   ★ PR`.
struct SetLine: View {
    let set: SetLog
    let exercise: Exercise?
    let unit: WeightUnit
    var isRecord = false

    var body: some View {
        HStack {
            Text("\(set.setNumber)")
                .font(.tabular(15, weight: .medium))
                .foregroundStyle(.secondary)
                .frame(width: 24, alignment: .leading)
            Text(exercise?.measure == .reps || exercise == nil ? "\(set.reps) reps" : LoadFormat.reps(set.reps, measure: exercise!.measure))
                .font(.tabular(16, weight: .regular))
            Spacer()
            Text(loadText)
                .font(.tabular(16, weight: .regular))
            Group {
                if isRecord {
                    Text("★ PR").foregroundStyle(Theme.record)
                } else if set.isUnderTarget {
                    Text("▼").foregroundStyle(.secondary)
                        .accessibilityLabel("under target of \(set.targetReps ?? 0)")
                } else {
                    Text("")
                }
            }
            .font(.footnote.weight(.semibold))
            .frame(width: 44, alignment: .trailing)
        }
    }

    private var loadText: String {
        LoadFormat.load(weight: set.weight, incline: set.incline, exercise: exercise, unit: unit) ?? "—"
    }
}

/// `Back  [████░░░░]  4,800 lb`.
struct BarRow: View {
    let label: String
    let value: Double
    let maximum: Double
    let unit: WeightUnit

    var body: some View {
        HStack(spacing: 10) {
            Text(label)
                .font(.subheadline)
                .frame(width: 84, alignment: .leading)
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    Capsule().fill(Theme.fill)
                    Capsule().fill(value > 0 ? Theme.accent : .clear)
                        .frame(width: maximum > 0 ? geo.size.width * value / maximum : 0)
                }
            }
            .frame(height: 8)
            Text(LoadFormat.volume(value, unit))
                .font(.tabular(14, weight: .medium))
                .foregroundStyle(value > 0 ? .primary : .secondary)
                .frame(width: 92, alignment: .trailing)
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("\(label), \(LoadFormat.volume(value, unit))")
    }
}

// MARK: - Chip filter

struct ChipBar: View {
    @Binding var selection: MuscleGroup?
    /// When bound, a ♥ chip filters to favourites — the Favourites view.
    var favourites: Binding<Bool>?

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                if let favourites {
                    chip(nil, systemImage: favourites.wrappedValue ? "heart.fill" : "heart", selected: favourites.wrappedValue) {
                        favourites.wrappedValue.toggle()
                    }
                    .accessibilityLabel("Favourites only")
                }
                chip("All", selected: selection == nil) { selection = nil }
                ForEach(MuscleGroup.allCases) { group in
                    chip(group.displayName, selected: selection == group) {
                        selection = selection == group ? nil : group
                    }
                }
            }
            .padding(.horizontal, Theme.Metrics.gutter)
            .padding(.vertical, 4)
        }
        .sensoryFeedback(.selection, trigger: selection)
    }

    private func chip(_ title: String?, systemImage: String? = nil, selected: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack(spacing: 4) {
                if let systemImage { Image(systemName: systemImage) }
                if let title { Text(title) }
            }
            .font(.subheadline.weight(.semibold))
            .padding(.horizontal, 14)
            .frame(minHeight: 36)
            .foregroundStyle(selected ? Color(.systemBackground) : .primary)
            .background(Capsule().fill(selected ? Color.primary : Theme.fill))
        }
        .buttonStyle(.plain)
        .accessibilityAddTraits(selected ? .isSelected : [])
    }
}

// MARK: - Empty states

struct EmptyState: View {
    let title: String
    let message: String
    var systemImage: String = "tray"
    var action: (title: String, run: () -> Void)?

    var body: some View {
        ContentUnavailableView {
            Label(title, systemImage: systemImage)
        } description: {
            Text(message)
        } actions: {
            if let action {
                Button(action.title, action: action.run)
                    .buttonStyle(.borderedProminent)
                    .controlSize(.large)
            }
        }
    }
}

// MARK: - ⓘ

/// The long text lives behind this, not under the heading.
struct InfoButton: View {
    let text: String
    @State private var shown = false

    var body: some View {
        Button { shown = true } label: {
            Image(systemName: "info.circle")
                .frame(width: 32, height: 32)
                .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .foregroundStyle(.secondary)
        .accessibilityLabel("More about this")
        .popover(isPresented: $shown) {
            Text(text)
                .font(.callout)
                .padding()
                .frame(idealWidth: 300)
                .fixedSize(horizontal: false, vertical: true)
                .presentationCompactAdaptation(.popover)
        }
    }
}

// MARK: - Formatting

enum Dates {
    /// `Tue 23 Sep`.
    static func day(_ date: Date) -> String {
        date.formatted(.dateTime.weekday(.abbreviated).day().month(.abbreviated))
    }

    /// `3 days ago`, `today`, `yesterday`.
    static func ago(_ date: Date, now: Date = .now) -> String {
        let calendar = Calendar.current
        let days = calendar.dateComponents([.day], from: calendar.startOfDay(for: date), to: calendar.startOfDay(for: now)).day ?? 0
        switch days {
        case ..<1: return "today"
        case 1: return "yesterday"
        default: return "\(days) days ago"
        }
    }
}

/// A number with a small label under it — the stat tile.
struct StatTile: View {
    let value: String
    let label: String

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(value)
                .font(.tabular(24, weight: .bold))
                .lineLimit(1)
                .minimumScaleFactor(0.6)
            Text(label).eyebrow()
        }
        .card(padding: 14)
        .accessibilityElement(children: .combine)
    }
}
