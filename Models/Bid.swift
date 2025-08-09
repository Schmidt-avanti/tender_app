import Foundation

enum BidStatus: String, Codable, CaseIterable, Sendable {
    case preparing      // statt .draft
    case submitted
    case won
    case lost
}

struct Bid: Identifiable, Codable, Sendable {
    var id: UUID
    var tenderId: String
    var title: String
    var amount: Double?
    var status: BidStatus
    var createdAt: Date

    init(
        id: UUID = UUID(),
        tenderId: String,
        title: String,
        amount: Double? = nil,
        status: BidStatus,
        createdAt: Date
    ) {
        self.id = id
        self.tenderId = tenderId
        self.title = title
        self.amount = amount
        self.status = status
        self.createdAt = createdAt
    }
}