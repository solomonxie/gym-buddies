import SwiftUI

/// Neutral surfaces and one accent. Colour means "you can act on this";
/// everything else is greyscale so the one thing that matters stands out.
enum Theme {
    static let accent = Color.accentColor
    static let accentSoft = Color.accentColor.opacity(0.14)
    /// Kept for shared drawing code (muscle map) — same as the accent.
    static let chrome = accent

    static let surface = Color(.systemGroupedBackground)
    static let card = Color(.secondarySystemGroupedBackground)
    static let fill = Color(.tertiarySystemFill)
    static let record = Color(red: 1.0, green: 0.72, blue: 0.0)
    static let done = Color.green

    /// Nothing that takes a tap mid-set is smaller than this. Apple's 44pt
    /// minimum assumes a steady hand and a dry finger; neither applies here.
    static let tapTarget: CGFloat = 60

    enum Metrics {
        static let corner: CGFloat = 20
        static let smallCorner: CGFloat = 14
        static let gutter: CGFloat = 16
    }
}

extension Font {
    /// Numbers that change while you watch them, so the layout can't jitter.
    static func tabular(_ size: CGFloat, weight: Font.Weight = .bold) -> Font {
        .system(size: size, weight: weight, design: .rounded).monospacedDigit()
    }

    /// Small caps-style label over a value.
    static let eyebrow = Font.system(size: 12, weight: .semibold, design: .rounded)
}

extension View {
    /// A rounded card on the grouped background.
    func card(padding: CGFloat = Theme.Metrics.gutter) -> some View {
        self
            .padding(padding)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(RoundedRectangle(cornerRadius: Theme.Metrics.corner, style: .continuous).fill(Theme.card))
    }

    func eyebrow() -> some View {
        self
            .font(.eyebrow)
            .textCase(.uppercase)
            .tracking(0.6)
            .foregroundStyle(.secondary)
    }
}
