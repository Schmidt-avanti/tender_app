import Foundation

@MainActor
final class BidManager: ObservableObject {
    static let shared = BidManager()

    @Published private(set) var bids: [Bid] = []

    // Falls du persistieren willst, ergänze hier Laden/Speichern (UserDefaults/CoreData o.ä.)
    init() {
        // load()
    }

    @discardableResult
    func createBid(for tender: Tender) -> Bid {
        let newBid = Bid(
            id: UUID(),
            tenderId: tender.id,
            title: tender.title,
            amount: nil,
            status: .preparing,
            createdAt: Date()
        )
        bids.append(newBid)
        // persist()
        return newBid
    }

    func updateStatus(for bidID: UUID, to newStatus: BidStatus) {
        guard let idx = bids.firstIndex(where: { $0.id == bidID }) else { return }
        bids[idx].status = newStatus
        // persist()
    }

    // MARK: - Persistence (optional)
    /*
    private func persist() {
        // ...
    }

    private func load() {
        // ...
    }
    */
}
