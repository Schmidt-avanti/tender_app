import SwiftUI

/// Placeholder bis die API von SavedSearchManager final ist.
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
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
            }
            .padding()
            .navigationTitle("Gespeichert")
        }
    }
}

#Preview {
    SavedSearchesView()
}
