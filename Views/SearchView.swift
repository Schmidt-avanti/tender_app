import SwiftUI

/// Haupt-Suchbildschirm: Trefferliste mit Titel + Veröffentlicht/Abgabe/Land.
/// Favoriten sind vorerst deaktiviert, damit der Build stabil läuft.
struct SearchView: View {
    @ObservedObject var viewModel: SearchViewModel

    @State private var showingFilters: Bool = false
    @State private var showingSaveSheet: Bool = false
    @State private var saveSearchName: String = ""

    @EnvironmentObject private var savedSearches: SavedSearchManager

    var body: some View {
        NavigationStack {
            Group {
                if viewModel.isLoading {
                    ProgressView("Suche läuft…")
                        .padding()
                } else if let msg = viewModel.errorMessage {
                    VStack(spacing: 16) {
                        Text("Fehler")
                            .font(.title2).bold()
                        Text(msg)
                            .multilineTextAlignment(.center)
                            .foregroundColor(.secondary)
                        Button {
                            viewModel.runSearch()
                        } label: {
                            Label("Erneut versuchen", systemImage: "arrow.clockwise")
                        }
                        .buttonStyle(.borderedProminent)
                    }
                    .padding()
                } else if viewModel.results.isEmpty {
                    VStack(spacing: 12) {
                        Text("Keine Ergebnisse")
                            .font(.title2)
                            .foregroundColor(.secondary)
                        Text("Passe die Filter an oder gib einen Freitext ein.")
                            .multilineTextAlignment(.center)
                            .foregroundColor(.secondary)
                    }
                    .padding()
                } else {
                    List {
                        // WICHTIG: id: \.id => vermeidet die Binding-ForEach-Variante
                        ForEach(viewModel.rankedResults, id: \.id) { tender in
                            NavigationLink(
                                destination: TenderDetailView(tender: tender)
                            ) {
                                HStack(alignment: .top, spacing: 12) {
                                    VStack(alignment: .leading, spacing: 6) {
                                        Text(tender.title)
                                            .font(.headline)
                                            .foregroundColor(.primary)
                                            .lineLimit(2)

                                        Text(tender.subtitleLine)
                                            .font(.subheadline)
                                            .foregroundColor(.secondary)
                                            .lineLimit(1)

                                        if !tender.cpv.isEmpty {
                                            ScrollView(.horizontal, showsIndicators: false) {
                                                HStack(spacing: 8) {
                                                    ForEach(tender.cpv, id: \.self) { code in
                                                        Pill(text: code)
                                                    }
                                                }
                                            }
                                        }
                                    }
                                    Spacer(minLength: 8)
                                }
                                .padding(.vertical, 6)
                            }
                        }
                    }
                    .listStyle(.plain)
                    .refreshable { viewModel.runSearch() }
                }
            }
            .navigationTitle("Ausschreibungen")
            .toolbar {
                ToolbarItemGroup(placement: .primaryAction) {
                    Button { viewModel.runSearch() } label: {
                        Image(systemName: "magnifyingglass")
                    }
                    Button { showingFilters.toggle() } label: {
                        Image(systemName: "line.3.horizontal.decrease.circle")
                    }
                }
                ToolbarItem(placement: .automatic) {
                    Button {
                        saveSearchName = ""
                        showingSaveSheet = true
                    } label: { Image(systemName: "bookmark") }
                    .accessibilityLabel("Suche speichern")
                }
            }
            .sheet(isPresented: $showingFilters) {
                FilterSheet(filters: $viewModel.filters) {
                    viewModel.runSearch()
                }
            }
            .sheet(isPresented: $showingSaveSheet) {
                NavigationStack {
                    Form {
                        Section(header: Text("Name der Suche")) {
                            TextField("z. B. Kundenservice Berlin", text: $saveSearchName)
                        }
                        Section(header: Text("Filter")) {
                            if !viewModel.filters.cpv.isEmpty {
                                ScrollView(.horizontal, showsIndicators: false) {
                                    HStack(spacing: 8) {
                                        ForEach(viewModel.filters.cpv, id: \.self) { code in
                                            Pill(text: code)
                                        }
                                    }
                                }
                            }
                            if !viewModel.filters.regions.isEmpty {
                                ScrollView(.horizontal, showsIndicators: false) {
                                    HStack(spacing: 8) {
                                        ForEach(viewModel.filters.regions, id: \.self) { reg in
                                            Pill(text: reg)
                                        }
                                    }
                                }
                            }
                            if !viewModel.filters.freeText.isEmpty {
                                Text("Freitext: \(viewModel.filters.freeText)")
                                    .font(.subheadline)
                                    .foregroundColor(.secondary)
                            }
                        }
                    }
                    .navigationTitle("Suche speichern")
                    .toolbar {
                        ToolbarItem(placement: .confirmationAction) {
                            Button("Speichern") {
                                let name = saveSearchName.isEmpty ? "Gespeicherte Suche" : saveSearchName
                                savedSearches.addSearch(name: name, filters: viewModel.filters)
                                showingSaveSheet = false
                            }
                        }
                        ToolbarItem(placement: .cancellationAction) {
                            Button("Abbrechen") { showingSaveSheet = false }
                        }
                    }
                }
            }
        }
        .onAppear {
            if viewModel.results.isEmpty && !viewModel.isLoading {
                viewModel.runSearch()
            }
        }
    }
}

