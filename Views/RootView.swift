import SwiftUI

/// A container view hosting a tabbed interface.  Each tab displays
/// a different aspect of the tender search workflow: searching,
/// viewing favourites and viewing simple statistics about the current
/// results.
struct RootView: View {
    @StateObject private var searchVM = SearchViewModel()
    @EnvironmentObject private var favs: FavoritesManager
    @EnvironmentObject private var savedSearches: SavedSearchManager
    @EnvironmentObject private var bidManager: BidManager

    var body: some View {
        TabView {
            SearchView(viewModel: searchVM)
                .tabItem {
                    Label("Suchen", systemImage: "magnifyingglass")
                }
            SavedSearchesView()
                .tabItem {
                    Label("Suchen", systemImage: "bookmark")
                }
            FavoritesView()
                .tabItem {
                    Label("Favoriten", systemImage: "star.fill")
                }
            BidListView()
                .tabItem {
                    Label("Bids", systemImage: "doc.plaintext")
                }
            StatsView(viewModel: searchVM)
                .tabItem {
                    Label("Statistik", systemImage: "chart.bar")
                }
        }
        .onAppear {
            // Kick off a search so that stats and favourites can be populated
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
    }
}
