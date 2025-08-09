import SwiftUI

/// Gespeicherte Suchen (ohne Favorites-Bezug).
struct SavedSearchesView: View {
    @EnvironmentObject private var savedSearches: SavedSearchManager
    @State private var selected: SavedSearch?

    var body: some View {
        NavigationStack {
            List {
                ForEach(savedSearches.items, id: \.id) { s in
                    Button {
                        selected = s
                    } label: {
                        VStack(alignment: .leading, spacing: 4) {
                            Text(s.name)
                                .font(.headline)
                            Text(summary(for: s))
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.vertical, 6)
                    }
                }
                .onDelete(perform: delete)
            }
            .listStyle(.plain)
            .navigationTitle("Gespeichert")
            .sheet(item: $selected) { s in
                SavedSearchRunnerView(search: s)
            }
        }
    }

    private func delete(at offsets: IndexSet) {
        for idx in offsets {
            let s = savedSearches.items[idx]
            savedSearches.remove(id: s.id)
        }
    }

    private func summary(for s: SavedSearch) -> String {
        var bits: [String] = []
        if !s.filters.cpv.isEmpty { bits.append("CPV: \(s.filters.cpv.joined(separator: ", "))") }
        if !s.filters.regions.isEmpty { bits.append("Regionen: \(s.filters.regions.joined(separator: ", "))") }
        if !s.filters.freeText.isEmpty { bits.append("Text: \(s.filters.freeText)") }
        return bits.isEmpty ? "Keine Filter" : bits.joined(separator: " · ")
    }
}

/// Einfache Runner-View, die eine gespeicherte Suche ausführt.
private struct SavedSearchRunnerView: View {
    let search: SavedSearch
    @StateObject private var vm = SearchViewModel()

    var body: some View {
        NavigationStack {
            SearchView(viewModel: vm)
                .onAppear {
                    vm.filters = search.filters
                    vm.runSearch()
                }
        }
    }
}
