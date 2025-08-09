import SwiftUI

/// Container mit Tabs (ohne Favoriten-Tab).
struct RootView: View {
    @StateObject private var searchVM = SearchViewModel()
    @EnvironmentObject private var savedSearches: SavedSearchManager
    @EnvironmentObject private var bidManager: BidManager

    var body: some View {
        TabView {
            SearchView(viewModel: searchVM)
                .tabItem { Label("Suchen", systemImage: "magnifyingglass") }

            SavedSearchesView()
                .tabItem { Label("Gespeichert", systemImage: "bookmark") }

            BidListView()
                .tabItem { Label("Bids", systemImage: "doc.plaintext") }

            StatsView(viewModel: searchVM)
                .tabItem { Label("Statistik", systemImage: "chart.bar") }
        }
        .onAppear {
            if searchVM.results.isEmpty {
                searchVM.runSearch()
            }
        }
    }
}
