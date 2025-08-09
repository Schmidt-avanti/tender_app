//
//  SavedSearchManager.swift
//  TendersApp
//

import Foundation

@MainActor
final class SavedSearchManager: ObservableObject {
    static let shared = SavedSearchManager()

    static let shared = \2()
    @Published private(set) var items: [SavedSearch] = []

    private let storageKey = "saved-searches.v1"
    private let decoder = JSONDecoder()
    private let encoder = JSONEncoder()

    init() {
        decoder.dateDecodingStrategy = .iso8601
        encoder.dateEncodingStrategy = .iso8601
        load()
    }

    func load() {
        guard let data = UserDefaults.standard.data(forKey: storageKey) else { return }
        do {
            items = try decoder.decode([SavedSearch].self, from: data)
        } catch {
            print("Failed to decode saved searches: \(error)")
            items = []
        }
    }

    private func persist() {
        do {
            let data = try encoder.encode(items)
            UserDefaults.standard.set(data, forKey: storageKey)
        } catch {
            print("Failed to encode saved searches: \(error)")
        }
    }

    func add(name: String, filters: Filters) {
        let s = SavedSearch(name: name, filters: filters)
        items.append(s)
        persist()
    }

    func remove(id: SavedSearch.ID) {
        items.removeAll { $0.id == id }
        persist()
    }
}
