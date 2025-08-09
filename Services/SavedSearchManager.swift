import Foundation

@MainActor
final class SavedSearchManager: ObservableObject {
    @Published private(set) var savedQueries: [String] = []

    func save(query: String) {
        guard !query.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return }
        if !savedQueries.contains(query) {
            savedQueries.append(query)
        }
    }

    func remove(at offsets: IndexSet) {
        savedQueries.remove(atOffsets: offsets)
    }
}