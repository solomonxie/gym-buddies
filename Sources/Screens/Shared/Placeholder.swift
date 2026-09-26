import SwiftUI

/// Stands in for a screen until its IMPLEMENT_PLAN task lands.
struct Placeholder: View {
    let task: String
    let drawing: String
    var note: String?

    var body: some View {
        VStack(spacing: 8) {
            Text(task)
                .font(.caption.weight(.semibold))
                .foregroundStyle(.secondary)
            Text(drawing)
                .font(.system(.footnote, design: .monospaced))
                .foregroundStyle(Theme.chrome)
            if let note {
                Text(note)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
            }
        }
        .padding()
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Theme.surface)
    }
}
