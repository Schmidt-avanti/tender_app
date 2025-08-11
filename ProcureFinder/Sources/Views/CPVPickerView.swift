import SwiftUI

struct CPVPickerView: View {
    @EnvironmentObject var repo: CPVRepository
    @Binding var selected: [String]
    @State private var q = ""

    var body: some View {
        NavigationStack {
            VStack {
                TextField("Suchen …", text: $q).textFieldStyle(.roundedBorder).padding()
                List {
                    ForEach(repo.search(q)) { cpv in
                        HStack {
                            VStack(alignment: .leading) {
                                Text("\(cpv.code) – \(cpv.de)").font(.body)
                                Text(cpv.en).font(.caption).foregroundStyle(.secondary)
                            }
                            Spacer()
                            if selected.contains(where: { $0 == cpv.code }) { Image(systemName: "checkmark.circle.fill") }
                        }
                        .contentShape(Rectangle())
                        .onTapGesture { toggle(cpv.code) }
                        .swipeActions(edge: .trailing) {
                            Button {
                                repo.toggleFavorite(code: cpv.code)
                            } label: {
                                Image(systemName: repo.favorites.contains(cpv.code) ? "star.fill" : "star")
                            }
                        }
                    }
                }
            }
            .navigationTitle(L10n.t(.cpvPicker))
            .toolbar { ToolbarItem(placement: .cancellationAction) { Button("Fertig") { dismiss() } } }
        }
    }
    @Environment(\.dismiss) private var dismiss
    private func toggle(_ code: String) {
        if let idx = selected.firstIndex(of: code) { selected.remove(at: idx) } else { selected.append(code) }
    }
}
