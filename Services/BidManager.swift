//
//  BidManager.swift
//  TendersApp
//

import Foundation

@MainActor
final class BidManager: ObservableObject {
    static let shared = BidManager()

    static let shared = \2()
    @Published private(set) var bids: [Bid] = []

    private let storageKey = "bids.v1"
    private let decoder = JSONDecoder()
    private let encoder = JSONEncoder()

    init() {
        decoder.dateDecodingStrategy = .iso8601
        encoder.dateEncodingStrategy = .iso8601
        load()
    }

    func load() {
        guard let data = UserDefaults.standard.data(forKey: storageKey) else {
            self.bids = []
            return
        }
        do {
            let decoded = try decoder.decode([Bid].self, from: data)
            self.bids = decoded
        } catch {
            print("Failed to decode bids: \(error)")
            self.bids = []
        }
    }

    private func persist() {
        do {
            let data = try encoder.encode(bids)
            UserDefaults.standard.set(data, forKey: storageKey)
        } catch {
            print("Failed to encode bids: \(error)")
        }
    }

    func add(_ bid: Bid) {
        bids.append(bid)
        persist()
    }

    func update(_ bid: Bid) {
        if let idx = bids.firstIndex(where: { $0.id == bid.id }) {
            bids[idx] = bid
            persist()
        }
    }

    func remove(_ bidID: Bid.ID) {
        bids.removeAll { $0.id == bidID }
        persist()
    }

    func addTask(to bidID: Bid.ID, title: String) {
        guard let idx = bids.firstIndex(where: { $0.id == bidID }) else { return }
        bids[idx].tasks.append(BidTask(title: title))
        persist()
    }

    func toggleTask(bidID: Bid.ID, taskID: BidTask.ID) {
        guard let bidx = bids.firstIndex(where: { $0.id == bidID }) else { return }
        guard let tidx = bids[bidx].tasks.firstIndex(where: { $0.id == taskID }) else { return }
        bids[bidx].tasks[tidx].isDone.toggle()
        persist()
    }

    func addComment(to bidID: Bid.ID, text: String) {
        guard let idx = bids.firstIndex(where: { $0.id == bidID }) else { return }
        bids[idx].comments.insert(BidComment(text: text), at: 0)
        persist()
    }
}
