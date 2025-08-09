//
//  SearchView.swift
//  TendersApp
//

import SwiftUI

struct SearchView: View {
    @ObservedObject var viewModel: SearchViewModel
    @State private var showFilters = false

    init(viewModel: SearchViewModel = SearchViewModel()) {
        self._viewModel = ObservedObject(initialValue: viewModel)
    }

    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                searchBar

                if viewModel.isLoading {
                    ProgressView("Suche…")
                        .padding()
                }

                if let message = viewModel.errorMessage {
                    Text(message)
                        .foregroundStyle(.red)
                        .padding()
                }

                if viewModel.results.isEmpty && !viewModel.isLoading {
                    ContentUnavailableView("Keine Ergebnisse", systemImage: "doc.text.magnifyingglass", description: Text("Starte eine Suche oben oder passe die Filter an."))
                        .padding()
                } else {
                    List(viewModel.results) { tender in
                        NavigationLink {
                            TenderDetailView(tender: tender)
                        } label: {
                            VStack(alignment: .leading, spacing: 4) {
                                Text(tender.title)
                                    .font(.headline)
                                    .lineLimit(2)
                                Text(tender.subtitleLine)
                                    .font(.subheadline)
                                    .foregroundStyle(.secondary)
                                    .lineLimit(1)
                            }
                            .padding(.vertical, 4)
                        }
                    }
                    .listStyle(.plain)
                }
            }
            .navigationTitle("Suche")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        showFilters = true
                    } label: {
                        Image(systemName: "line.3.horizontal.decrease.circle")
                    }
                }
            }
        }
        .sheet(isPresented: $showFilters) {
            NavigationStack {
                FilterSheet(filters: $viewModel.query)
                    .navigationTitle("Filter")
                    .toolbar {
                        ToolbarItem(placement: .cancellationAction) {
                            Button("Abbrechen") { showFilters = false }
                        }
                        ToolbarItem(placement: .confirmationAction) {
                            Button("Anwenden") {
                                showFilters = false
                                viewModel.search()
                            }
                        }
                    }
            }
        }
    }

    private var searchBar: some View {
        HStack {
            TextField("Stichwort, CPV, Auftraggeber…", text: $viewModel.query.queryText)
                .textFieldStyle(.roundedBorder)
                .submitLabel(.search)
                .onSubmit { viewModel.search() }

            Button {
                viewModel.search()
            } label: {
                Image(systemName: "magnifyingglass")
                    .padding(.horizontal, 8)
            }
            .buttonStyle(.borderedProminent)
        }
        .padding([.horizontal, .top])
    }
}

#Preview {
    SearchView()
}
