import SwiftUI

struct RootView: View {
    @StateObject private var searchVM = SearchViewModel()
    @EnvironmentObject private var favs: FavoritesManager
    @EnvironmentObject private var savedSearches: SavedSearchManager
    @EnvironmentObject private var bidManager: BidManager

    var body: some View {
        ZStack {
            // Vollflächiger Hintergrund gegen Letterboxing
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
        .task {
            // Erste Suche anstoßen, damit Stats/Favoriten Daten bekommen
            if searchVM.results.isEmpty {
                searchVM.runSearch()
            }
        }
    }
}

#Preview {
    RootView()
        .environmentObject(FavoritesManager.shared)
        .environmentObject(SavedSearchManager.shared)
        .environmentObject(BidManager.shared)
}
