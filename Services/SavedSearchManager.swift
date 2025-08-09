import Foundation
import UserNotifications

/// Manages the user's collection of saved searches.  Searches are
/// persisted to disk and can optionally register push notifications
/// when new tenders matching the search criteria are found.  In a
/// production environment you would communicate with a backend to
/// perform the search server‑side and schedule remote notifications;
/// here we simulate by scheduling a local notification after the
/// search completes.
@MainActor
final class SavedSearchManager: ObservableObject {
    /// The shared singleton instance used throughout the app.
    static let shared = SavedSearchManager()
    /// Published list of all saved searches.  Updating this array will
    /// automatically notify any SwiftUI views observing it.
    @Published private(set) var searches: [SavedSearch] = []
    /// The key used to store saved searches in UserDefaults.
    private let storageKey = "savedSearches"
    /// Encoders for persisting and restoring saved searches.
    private let encoder = JSONEncoder()
    private let decoder = JSONDecoder()

    private init() {
        load()
    }

    /// Persists the current list of saved searches to UserDefaults.
    private func save() {
        do {
            let data = try encoder.encode(searches)
            UserDefaults.standard.set(data, forKey: storageKey)
        } catch {
            print("Failed to save saved searches: \(error)")
        }
    }

    /// Restores the saved searches from UserDefaults, if any exist.
    private func load() {
        guard let data = UserDefaults.standard.data(forKey: storageKey) else { return }
        do {
            let decoded = try decoder.decode([SavedSearch].self, from: data)
            self.searches = decoded
        } catch {
            print("Failed to load saved searches: \(error)")
        }
    }

    /// Adds a new saved search.  After insertion the list is sorted by
    /// creation date descending so the newest searches appear first.
    func addSearch(name: String, filters: SearchFilters) {
        let newSearch = SavedSearch(name: name, filters: filters)
        searches.append(newSearch)
        searches.sort { $0.createdAt > $1.createdAt }
        save()
    }

    /// Removes a saved search by its identifier.  If the search cannot
    /// be found this has no effect.
    func remove(id: UUID) {
        searches.removeAll { $0.id == id }
        save()
    }

    /// Updates an existing saved search by replacing it with the
    /// provided value.  Searches are matched by identifier.
    func update(search: SavedSearch) {
        guard let index = searches.firstIndex(where: { $0.id == search.id }) else { return }
        searches[index] = search
        save()
    }

    /// Runs the given saved search by invoking the API client.  If
    /// results are found a local notification is scheduled to alert
    /// the user.  This is a simulation of a server‑side polling
    /// mechanism.  Returns the results so they can be displayed.
    func execute(search: SavedSearch) async -> [Tender] {
        do {
            let results = try await APIClient.shared.asyncSearch(filters: search.filters)
            if !results.isEmpty {
                scheduleNotification(for: search, count: results.count)
            }
            return results
        } catch {
            print("Error executing saved search: \(error)")
            return []
        }
    }

    /// Schedules a local notification summarising the search results.
    private func scheduleNotification(for search: SavedSearch, count: Int) {
        let content = UNMutableNotificationContent()
        content.title = "Neue Ergebnisse für \(search.name)"
        content.body = "Es wurden \(count) neue Ausschreibungen gefunden."
        content.sound = .default
        // Trigger after 5 seconds as a simple demo.  In reality the
        // backend would control when notifications fire.
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 5, repeats: false)
        let request = UNNotificationRequest(identifier: search.id.uuidString, content: content, trigger: trigger)
        UNUserNotificationCenter.current().add(request) { error in
            if let error = error {
                print("Failed to schedule saved search notification: \(error)")
            }
        }
    }
}