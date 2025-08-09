import Foundation
import Combine

/// Verwalten von Favoriten (leichtgewichtige Snapshots, nicht der ganze Tender).
@MainActor
final class FavoritesManager: ObservableObject {
    static let shared = FavoritesManager()

    /// Gespeicherter Stand je Tender-ID
    @Published private(set) var items: [String: FavoriteData] = [:]

    private let storageKey = "favorites.v1"

    private init() {
        load()
        // Bei Änderungen automatisch persistieren
        $items
            .debounce(for: .milliseconds(150), scheduler: RunLoop.main)
            .sink { [weak self] _ in self?.save() }
            .store(in: &cancellables)
    }

    // MARK: - Public API (wie im UI verwendet)

    /// Favorit an/aus für gegebenen Tender
    func toggle(tender: Tender) {
        if items[tender.id] != nil {
            items.removeValue(forKey: tender.id)
        } else {
            items[tender.id] = FavoriteData(
                id: tender.id,
                title: tender.title,
                url: tender.url?.absoluteString,
                note: items[tender.id]?.note // evtl. bestehende Notiz mitnehmen
            )
        }
    }

    /// Abfrage über Tender-ID
    func isFavorite(id: String) -> Bool { items[id] != nil }

    /// Bequeme Überladung
    func isFavorite(_ tender: Tender) -> Bool { isFavorite(id: tender.id) }

    /// Notiz setzen (leer erlaubt)
    func setNote(_ note: String, for id: String) {
        if var f = items[id] {
            f.note = note
            items[id] = f
        } else {
            // Falls noch kein Favorit angelegt war, trotzdem Note halten
            items[id] = FavoriteData(id: id, title: "", url: nil, note: note)
        }
    }

    /// Notiz abfragen
    func note(for id: String) -> String {
        items[id]?.note ?? ""
    }

    // MARK: - Internals & Persistence

    private var cancellables = Set<AnyCancellable>()

    private func load() {
        guard let data = UserDefaults.standard.data(forKey: storageKey) else { return }
        do {
            let decoded = try JSONDecoder().decode([String: FavoriteData].self, from: data)
            self.items = decoded
        } catch {
            // bei Schemaänderungen lieber frisch starten
            self.items = [:]
        }
    }

    private func save() {
        do {
            let data = try JSONEncoder().encode(items)
            UserDefaults.standard.set(data, forKey: storageKey)
        } catch {
            // Persistenzfehler bewusst still – UI soll nicht blockieren
            // (Optional: Logging ergänzen)
        }
    }

    // Leichtgewichtige, codierbare Snapshot-Struktur
    struct FavoriteData: Codable, Hashable {
        let id: String
        var title: String
        var url: String?
        var note: String?
    }
}
