import SwiftUI

struct SearchView: View {
    @EnvironmentObject var vm: SearchViewModel
    @StateObject private var saved = SavedSearchManager()

    var body: some View {
        VStack(spacing: 12) {
            HStack {
                TextField("z. B. \"IT Dienstleistung Wartung\"", text: $vm.query)
                    .textFieldStyle(.roundedBorder)
                    .disableAutocorrection(true)
                    .textInputAutocapitalization(.never)

                Button {
                    Task { await vm.performSearch() }
                } label: {
                    if vm.isSearching {
                        ProgressView()
                    } else {
                        Image(systemName: "magnifyingglass")
                    }
                }
                .buttonStyle(.borderedProminent)
                .disabled(vm.query.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || vm.isSearching)
            }
            .padding(.horizontal)

            if let msg = vm.errorMessage {
                Text(msg)
                    .foregroundColor(.secondary)
                    .padding(.horizontal)
            }

            List {
                ForEach(vm.results) { t in
                    NavigationLink(destination: TenderDetailView(tender: t)) {
                        VStack(alignment: .leading, spacing: 6) {
                            Text(t.title).font(.headline)
                            if let buyer = t.buyer { Text(buyer).font(.subheadline).foregroundColor(.secondary) }
                            if let loc = t.location { Text(loc).font(.subheadline).foregroundColor(.secondary) }
                            if let d = t.deadline {
                                Text("Frist: \(format(date: d))").font(.footnote).foregroundColor(.secondary)
                            }
                        }
                    }
                }
            }
            .listStyle(.plain)
        }
        .navigationTitle("Ausschreibungen")
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button {
                    saved.save(query: vm.query)
                } label: {
                    Label("Suche speichern", systemImage: "bookmark")
                }
                .disabled(vm.query.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
            }
        }
    }

    private func format(date: Date) -> String {
        let f = DateFormatter()
        f.dateStyle = .medium
        return f.string(from: date)
    }
}

struct SearchView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationView {
            SearchView()
                .environmentObject(SearchViewModel())
        }
    }
}