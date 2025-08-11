import Foundation
import OSLog

@MainActor
final class CPVRepository: ObservableObject {
    @Published var all: [CPV] = []
    @Published var favorites: Set<String> = []
    private let log = Logger(subsystem: "ProcureFinder", category: "CPV")
    private let favoritesKey = "cpv_favorites"

    func loadCPV() async {
        guard all.isEmpty,
              let url = Bundle.main.url(forResource: "cpv", withExtension: "json"),
              let data = try? Data(contentsOf: url) else { return }
        do {
            all = try JSONDecoder().decode([CPV].self, from: data)
        } catch {
            log.error("CPV decode failed: \(error.localizedDescription)")
        }
        favorites = Set(UserDefaults.standard.stringArray(forKey: favoritesKey) ?? [])
    }

    func toggleFavorite(code: String) {
        if favorites.contains(code) { favorites.remove(code) } else { favorites.insert(code) }
        UserDefaults.standard.set(Array(favorites), forKey: favoritesKey)
    }

    func search(_ text: String) -> [CPV] {
        guard !text.isEmpty else { return all }
        let q = text.lowercased()
        return all.filter { $0.de.lowercased().contains(q) || $0.en.lowercased().contains(q) || $0.code.contains(q) }
    }
}
