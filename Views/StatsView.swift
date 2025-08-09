import SwiftUI

struct StatsView: View {
    var body: some View {
        Group {
            if #available(iOS 17.0, *) {
                ContentUnavailableView(
                    "Keine Daten",
                    systemImage: "chart.bar",
                    description: Text("Führe zuerst eine Suche aus.")
                )
            } else {
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