import SwiftUI

struct FavouritesView: View {
    var body: some View {
        NavigationStack {
            Placeholder(
                task: "T3.3 · Favourites",
                drawing: "docs/uiux/exercises.md",
                note: "The library filtered, not a second list."
            )
            .navigationTitle("Favourites")
        }
    }
}
