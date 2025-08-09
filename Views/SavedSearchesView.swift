import SwiftUI

/// Displays the user's saved searches.  Allows creating new saved
/// searches based on the current filters and running a search to
/// populate results.  Uses the `SavedSearchManager` environment
/// object to persist data and `SearchViewModel` to perform the
/// search when a saved search is selected.  The view is structured
/// as a simple list for clarity.
struct SavedSearchesView: View {
    @EnvironmentObject private var savedSearches: SavedSearchManager
    @StateObject private var searchVM = SearchViewModel()
    @State private var showingAddSheet: Bool = false
    @State private var newSearchName: String = ""
    @State private var showResults: Bool = false
    @State private var selectedResults: [Tender] = []

    var body: some View {
        NavigationStack {
            List {
                ForEach(savedSearches.searches) { search in
                    Button(action: {
                        Task {
                            selectedResults = await savedSearches.execute(search: search)
                            showResults = true
                        }
                    }) {
                        VStack(alignment: .leading) {
                            Text(search.name)
                                .font(.headline)
                            Text("\(search.filters.cpv.count) CPV, \(search.filters.regions.count) Regionen")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                        }
                    }
                }
                .onDelete { offsets in
                    for index in offsets {
                        let id = savedSearches.searches[index].id
                        savedSearches.remove(id: id)
                    }
                }
            }
            .navigationTitle("Gespeicherte Suchen")
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button(action: { showingAddSheet = true }) {
                        Label("Neu", systemImage: "plus")
                    }
                }
            }
            .sheet(isPresented: $showingAddSheet) {
                NavigationStack {
                    Form {
                        Section(header: Text("Name")) {
                            TextField("z. B. Hotlines Berlin", text: $newSearchName)
                        }
                        Section(header: Text("Filter")) {
                            // Use the same FilterSheet view to configure new searches
                            FilterSheet(filters: $searchVM.filters) {
                                // nothing
                            }
                            .frame(height: 400)
                        }
                    }
                    .navigationTitle("Neue Suche")
                    .toolbar {
                        ToolbarItem(placement: .confirmationAction) {
                            Button("Speichern") {
                                savedSearches.addSearch(name: newSearchName.isEmpty ? "Unbenannte Suche" : newSearchName, filters: searchVM.filters)
                                newSearchName = ""
                                searchVM.filters = SearchFilters()
                                showingAddSheet = false
                            }
                        }
                        ToolbarItem(placement: .cancellationAction) {
                            Button("Abbrechen") {
                                newSearchName = ""
                                searchVM.filters = SearchFilters()
                                showingAddSheet = false
                            }
                        }
                    }
                }
            }
            .navigationDestination(isPresented: $showResults) {
                ResultsListView(results: selectedResults)
            }
        }
    }
}

/// A helper view to present search results from a saved search.  This
/// view reuses some of the styling from the main search view but
/// operates independently so it can be pushed onto the navigation
/// stack.
private struct ResultsListView: View {
    let results: [Tender]
    @EnvironmentObject private var favs: FavoritesManager
    var body: some View {
        List(results) { tender in
            NavigationLink(value: tender) {
                HStack {
                    VStack(alignment: .leading, spacing: 8) {
                        Text(tender.title)
                            .font(.headline)
                        if let buyer = tender.buyer {
                            Text(buyer)
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                        }
                    }
                    Spacer()
                    Button(action: {
                        withAnimation(.spring()) {
                            favs.toggle(tender: tender)
                        }
                    }) {
                        Image(systemName: favs.isFavorite(id: tender.id) ? "star.fill" : "star")
                            .foregroundColor(.yellow)
                    }
                    .buttonStyle(.plain)
                }
            }
        }
        .navigationTitle("Ergebnisse")
        .navigationDestination(for: Tender.self) { tender in
            TenderDetailView(tender: tender)
        }
    }
}

struct SavedSearchesView_Previews: PreviewProvider {
    static var previews: some View {
        SavedSearchesView()
            .environmentObject(SavedSearchManager.shared)
            .environmentObject(FavoritesManager.shared)
    }
}