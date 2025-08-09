//
//  SavedSearchesView.swift
//  TendersApp
//

import SwiftUI

struct SavedSearchesView: View {
    @ObservedObject var searchVM: SearchViewModel
    @EnvironmentObject var savedManager: SavedSearchManager
    @State private var newName: String = ""

    var body: some View {
        NavigationView {
            List {
                Section("Gespeicherte Suchen") {
                    if savedManager.items.isEmpty {
                        Text("Noch keine Suchen gespeichert.")
                            .foregroundStyle(.secondary)
                    } else {
                        ForEach(savedManager.items) { item in
                            Button {
                                searchVM.query = item.filters
                                searchVM.search()
                            } label: {
                                VStack(alignment: .leading) {
                                    Text(item.name).font(.headline)
                                    Text("Erstellt: \(item.createdAt.formatted(date: .abbreviated, time: .omitted))")
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                }
                            }
                        }
                        .onDelete { idx in
                            for i in idx {
                                let id = savedManager.items[i].id
                                savedManager.remove(id: id)
                            }
                        }
                    }
                }

                Section("Aktuelle Suche speichern") {
                    HStack {
                        TextField("Name", text: $newName)
                        Button("Speichern") {
                            guard !newName.trimmingCharacters(in: .whitespaces).isEmpty else { return }
                            savedManager.add(name: newName, filters: searchVM.query)
                            newName = ""
                        }
                    }
                }
            }
            .navigationTitle("Suchen")
            .toolbar { EditButton() }
        }
    }
}

#Preview {
    SavedSearchesView(searchVM: SearchViewModel())
        .environmentObject(SavedSearchManager())
}
