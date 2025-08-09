import Foundation
import Combine

/// Manages the user's favourite tenders and notes.  Stores data in
/// UserDefaults under the key "favorites".  Provides methods to
/// toggle favourites, check favourite status and manage notes.
final class FavoritesManager: ObservableObject {
    struct FavoriteData: Codable {
        let tender: Tender
        var note: String
    }
    
    @Published private(set) var items: [String: FavoriteData] = [:]
    
    static let shared = FavoritesManager()
    private let storageKey = "favorites"
    private let decoder = JSONDecoder()
    private let encoder = JSONEncoder()
    
    private init() {
        load()
    }
    
    /// Toggle a tender's favourite state.  If it isn't favourited
    /// already it will be stored with an empty note; otherwise it will
    /// be removed.
    func toggle(tender: Tender) {
        if items[tender.id] != nil {
            remove(id: tender.id)
        } else {
            add(tender: tender)
        }
    }
    
    private func add(tender: Tender) {
        items[tender.id] = FavoriteData(tender: tender, note: "")
        save()
    }
    
    func remove(id: String) {
        items.removeValue(forKey: id)
        save()
    }
    
    func isFavorite(id: String) -> Bool {
        return items[id] != nil
    }
    
    func note(for id: String) -> String {
        return items[id]?.note ?? ""
    }
    
    func setNote(_ note: String, for id: String) {
        guard var fav = items[id] else { return }
        fav.note = note
        items[id] = fav
        save()
    }
    
    private func save() {
        do {
            let data = try encoder.encode(items)
            UserDefaults.standard.set(data, forKey: storageKey)
            objectWillChange.send()
        } catch {
            print("Failed to save favourites: \(error)")
        }
    }
    
    private func load() {
        guard let data = UserDefaults.standard.data(forKey: storageKey) else { return }
        do {
            let decoded = try decoder.decode([String: FavoriteData].self, from: data)
            self.items = decoded
        } catch {
            print("Failed to load favourites: \(error)")
        }
    }
}
