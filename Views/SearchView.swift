import SwiftUI

/// The main search screen.  Displays tender results and allows the user
/// to refine the query via a filter sheet.  Each row includes a
/// favourite star that can be toggled with an animation.
struct SearchView: View {
    @ObservedObject var viewModel: SearchViewModel
    @State private var showingFilters: Bool = false
    @State private var showingSaveSheet: Bool = false
    @State private var saveSearchName: String = ""
    @EnvironmentObject private var favs: FavoritesManager
    @EnvironmentObject private var savedSearches: SavedSearchManager
    
    var body: some View {
        NavigationStack {
            Group {
                if viewModel.isLoading {
                    ProgressView("Suche läuft…")
                } else if let msg = viewModel.errorMessage {
                    VStack(spacing: 16) {
                        Text("Fehler").font(.title2).bold()
                        Text(msg).multilineTextAlignment(.center)
                        PrimaryButton(title: "Erneut versuchen") {
                            viewModel.runSearch()
                        }
                    }.padding()
                } else if viewModel.results.isEmpty {
                    VStack(spacing: 16) {
                        Text("Keine Ergebnisse")
                            .font(.title2)
                            .foregroundColor(.secondary)
                        Text("Versuche, die Suche anzupassen oder andere Filter auszuwählen.")
                            .multilineTextAlignment(.center)
                            .foregroundColor(.secondary)
                    }
                    .padding()
                } else {
                    List(viewModel.rankedResults) { tender in
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
                                    ScrollView(.horizontal, showsIndicators: false) {
                                        HStack(spacing: 8) {
                                            ForEach(tender.cpv, id: \.self) { code in
                                                Pill(text: code)
                                            }
                                            if let d = tender.deadline {
                                                let formatted = DateFormatter.localizedString(from: d, dateStyle: .short, timeStyle: .none)
                                                Pill(text: "Frist: \(formatted)")
                                            }
                                        }
                                    }
                                }
                                Spacer()
                                Button(action: {
                                    withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) {
                                        favs.toggle(tender: tender)
                                    }
                                }) {
                                    Image(systemName: favs.isFavorite(id: tender.id) ? "star.fill" : "star")
                                        .foregroundColor(.yellow)
                                        .scaleEffect(favs.isFavorite(id: tender.id) ? 1.3 : 1.0)
                                }
                                .buttonStyle(.plain)
                            }
                            .padding(.vertical, 4)
                        }
                    }
                    .listStyle(.plain)
                }
            }
            .navigationTitle("Ausschreibungen")
            .navigationDestination(for: Tender.self) { tender in
                TenderDetailView(tender: tender)
            }
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button {
                        showingFilters.toggle()
                    } label: {
                        Image(systemName: "line.3.horizontal.decrease.circle")
                    }
                }
                ToolbarItem(placement: .primaryAction) {
                    Button {
                        viewModel.runSearch()
                    } label: {
                        Image(systemName: "magnifyingglass")
                    }
                }
            ToolbarItem(placement: .automatic) {
                Button {
                    saveSearchName = ""
                    showingSaveSheet = true
                } label: {
                    Image(systemName: "bookmark")
                }
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
                        // Show a summary of current filters.  Use chips for CPV and regions.
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
                        Button("Abbrechen") {
                            showingSaveSheet = false
                        }
                    }
                }
            }
        }
        }
    }
}
