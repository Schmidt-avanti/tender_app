import SwiftUI

struct SearchView: View {
    @StateObject var vm = SearchViewModel()
    @EnvironmentObject var resultsVM: ResultsViewModel

    var body: some View {
        NavigationStack {
            VStack(spacing: 12) {
                // Minimaler Trigger zur Suche (deine bestehenden Filter-Controls bleiben in SearchViewModel)
                Button("Suche aktualisieren") {
                    Task {
                        // Übergib die aktuellen Filter an das Results-VM und starte eine frische Suche
                        resultsVM.filters = vm.filters
                        await resultsVM.load(reset: true)
                    }
                }
                .buttonStyle(.borderedProminent)

                // Ergebnisliste
                ResultsView()
                    .environmentObject(resultsVM)
            }
            .padding()
            .navigationTitle("Ausschreibungen")
        }
    }
}

