import SwiftUI

struct StatsView: View {
    // Falls du hier ein ViewModel nutzt, kannst du es wie gewohnt injizieren.
    // @EnvironmentObject var searchViewModel: SearchViewModel

    var body: some View {
        Group {
            // Beispiel: Wenn du echte Daten hast, zeige sie hier. Andernfalls: leere Ansicht.
            // if hasData { ... } else { ... }

            // iOS 17+: ContentUnavailableView
            if #available(iOS 17.0, *) {
                ContentUnavailableView(
                    "Keine Daten",
                    systemImage: "chart.bar",
                    description: Text("Führe zuerst eine Suche aus.")
                )
            } else {
                // iOS 16 Fallback
                VStack(spacing: 12) {
                    Image(systemName: "chart.bar")
                        .font(.system(size: 40))
                    Text("Keine Daten")
                        .font(.headline)
                    Text("Führe zuerst eine Suche aus.")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .multilineTextAlignment(.center)
                .padding()
            }
        }
        .navigationTitle("Statistiken")
        .background(Color(UIColor.systemBackground))
    }
}

#Preview {
    StatsView()
}
