import SwiftUI

struct RootView: View {
    var body: some View {
        TabView {
            NavigationView {
                SearchView()
            }
            .tabItem {
                Label("Suche", systemImage: "magnifyingglass")
            }

            NavigationView {
                BidListView()
            }
            .tabItem {
                Label("Gebote", systemImage: "doc.text")
            }

            NavigationView {
                SavedSearchesView()
            }
            .tabItem {
                Label("Suchen", systemImage: "bookmark")
            }

            NavigationView {
                StatsView()
            }
            .tabItem {
                Label("Stats", systemImage: "chart.bar")
            }
        }
    }
}

struct RootView_Previews: PreviewProvider {
    static var previews: some View {
        RootView()
            .environmentObject(BidManager.shared)
            .environmentObject(SearchViewModel())
    }
}