import SwiftUI

/// Platzhalteransicht für gespeicherte Suchen.
/// Kann später durch eine voll funktionsfähige Version ersetzt werden.
struct SavedSearchesView: View {
    var body: some View {
        NavigationStack {
            VStack(spacing: 12) {
                Image(systemName: "bookmark")
                    .font(.system(size: 40, weight: .regular))
                    .foregroundStyle(.secondary)
                Text("Gespeicherte Suchen")
                    .font(.title3)
                Text("Diese Ansicht wird in einem späteren Schritt angebunden.")
                    .multilineTextAlignment(.center)
                    .foregroundStyle(.secondary)
            }
            .padding()
            .navigationTitle("Gespeichert")
        }
    }
}

#Preview {
    SavedSearchesView()
}
