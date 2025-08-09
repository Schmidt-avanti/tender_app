import Foundation

/// Manages the collection of bids for the current user.  Persists
/// data locally via UserDefaults.  Supports CRUD operations on bids
/// and nested tasks and comments.  In a real application you would
/// connect to a backend to store and synchronise bids across team
/// members and devices.
@MainActor
final class BidManager: ObservableObject {
    static let shared = BidManager()
    @Published private(set) var bids: [Bid] = []
    private let storageKey = "bids"
    private let encoder = JSONEncoder()
    private let decoder = JSONDecoder()
    private init() {
        load()
    }
    /// Save the current bid list to UserDefaults.
    private func save() {
        do {
            let data = try encoder.encode(bids)
            UserDefaults.standard.set(data, forKey: storageKey)
        } catch {
            print("Failed to save bids: \(error)")
        }
    }
    /// Load existing bids from UserDefaults.
    private func load() {
        guard let data = UserDefaults.standard.data(forKey: storageKey) else { return }
        do {
            bids = try decoder.decode([Bid].self, from: data)
        } catch {
            print("Failed to load bids: \(error)")
        }
    }
    /// Create a new bid for a given tender and return the created instance.
    func createBid(for tender: Tender) -> Bid {
        let bid = Bid(tender: tender)
        bids.append(bid)
        save()
        return bid
    }
    /// Update a bid in place.  Searches for a bid with the same id and
    /// replaces it.
    func update(bid: Bid) {
        guard let index = bids.firstIndex(where: { $0.id == bid.id }) else { return }
        bids[index] = bid
        save()
    }
    /// Remove a bid entirely.
    func remove(id: UUID) {
        bids.removeAll { $0.id == id }
        save()
    }
    /// Retrieve a bid by identifier.
    func bid(for id: UUID) -> Bid? {
        return bids.first(where: { $0.id == id })
    }
}