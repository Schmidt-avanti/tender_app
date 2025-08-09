import SwiftUI

struct SavedSearchesView: View {
    @StateObject private var manager = SavedSearchManager()
    @EnvironmentObject var vm: SearchViewModel

    var body: some View {
        List {
            ForEach(manager.savedQueries, id: \.self) { q in
                HStack {
                    Text(q)
                    Spacer()
                    Button {
                        vm.query = q
                        Task { await vm.performSearch() }
                    } label: {
                        Image(systemName: "arrow.clockwise")
                    }
                    .buttonStyle(.bordered)
                }
            }
            .onDelete(perform: manager.remove)
        }
        .navigationTitle("Gespeicherte Suchen")
        .toolbar {
            EditButton()
        }
    }
}