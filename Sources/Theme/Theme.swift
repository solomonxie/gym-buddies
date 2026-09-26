import SwiftUI

/// Colours are deliberately flat and high-contrast: the app is read at arm's
/// length, through sweat, on a screen angled away from you.
enum Theme {
    static let chrome = Color(red: 0.17, green: 0.42, blue: 0.63)
    static let headerCard = Color(red: 0.04, green: 0.16, blue: 0.27)
    static let restBar = Color(red: 0.15, green: 0.22, blue: 0.28)

    static let setTile = Color(red: 0.23, green: 0.23, blue: 0.23)
    static let repsTile = Color(red: 0.25, green: 0.32, blue: 0.71)
    static let weightTile = Color(red: 0.75, green: 0.27, blue: 0.18)

    static let surface = Color(.systemGroupedBackground)
    static let card = Color(.secondarySystemGroupedBackground)

    /// Nothing that takes a tap mid-set is smaller than this. Apple's 44pt
    /// minimum assumes a steady hand and a dry finger; neither applies here.
    static let tapTarget: CGFloat = 60

    enum Metrics {
        static let corner: CGFloat = 10
        static let gutter: CGFloat = 12
    }
}

extension Font {
    /// Numbers that change while you watch them, so the layout can't jitter.
    static func tabular(_ size: CGFloat, weight: Font.Weight = .bold) -> Font {
        .system(size: size, weight: weight, design: .rounded).monospacedDigit()
    }
}
