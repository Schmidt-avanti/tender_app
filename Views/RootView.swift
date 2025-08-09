import SwiftUI

/// Container mit Tab-Navigation für Suche, gespeicherte Suchen,
/// Favoriten, Bid-Workflow und Statistik.
struct RootView: View {
    @StateObject private var searchVM = SearchViewModel()
    @EnvironmentObject private var favs: FavoritesManager
    @EnvironmentObject private var savedSearches: SavedSearchManager
    @EnvironmentObject private var bidManager: BidManager

    var body: some View {
        ZStack {
            // Vollflächiger Hintergrund über Dynamic Island & Home-Indikator
            Color(.systemBackground).ignoresSafeArea()

            TabView {
                SearchView(viewModel: searchVM)
                    .tabItem { Label("Suchen", systemImage: "magnifyingglass") }

                SavedSearchesView()
                    .tabItem { Label("Suchen", systemImage: "bookmark") }

                FavoritesView()
                    .tabItem { Label("Favoriten", systemImage: "star.fill") }

                BidListView()
                    .tabItem { Label("Bids", systemImage: "doc.plaintext") }

                StatsView(viewModel: searchVM)
                    .tabItem { Label("Statistik", systemImage: "chart.bar") }
            }
        }
        .onAppear {
            // Erste Suche beim Start anstoßen (damit Stats/Favoriten Daten haben)
            if searchVM.results.isEmpty {
                searchVM.runSearch()
            }
        }
    }
}

struct RootView_Previews: PreviewProvider {
    static var previews: some View {
        RootView()
            .environmentObject(FavoritesManager.shared)
            .environmentObject(SavedSearchManager.shared)
            .environmentObject(BidManager.shared)
    }
}
