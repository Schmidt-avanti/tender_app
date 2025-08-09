//
//  Bid.swift
//  TendersApp
//

import Foundation

struct BidTask: Identifiable, Codable, Hashable {
    var id: UUID
    var title: String
    var isDone: Bool

    init(id: UUID = UUID(), title: String, isDone: Bool = false) {
        self.id = id
        self.title = title
        self.isDone = isDone
    }
}

enum BidStatus: String, Codable, CaseIterable, Identifiable {
    case preparing
    case submitted
    case won
    case lost

    var id: String { rawValue }

    var title: String {
        switch self {
        case .preparing: return "In Vorbereitung"
        case .submitted: return "Eingereicht"
        case .won: return "Zuschlag"
        case .lost: return "Abgelehnt"
        }
    }
}

struct BidComment: Identifiable, Codable, Hashable {
    var id: UUID
    var text: String
    var createdAt: Date

    init(id: UUID = UUID(), text: String, createdAt: Date = Date()) {
        self.id = id
        self.text = text
        self.createdAt = createdAt
    }
}

struct Bid: Identifiable, Codable, Hashable {
    var id: UUID
    var tender: Tender
    var status: BidStatus
    var createdAt: Date
    var tasks: [BidTask]
    var comments: [BidComment]

    init(
        id: UUID = UUID(),
        tender: Tender,
        status: BidStatus = .preparing,
        createdAt: Date = Date(),
        tasks: [BidTask] = [],
        comments: [BidComment] = []
    ) {
        self.id = id
        self.tender = tender
        self.status = status
        self.createdAt = createdAt
        self.tasks = tasks
        self.comments = comments
    }

    // Convenience init used in various places
    init(tender: Tender) {
        self.init(tender: tender, status: .preparing)
    }

    static func mock(tender: Tender = .mock()) -> Bid {
        Bid(
            tender: tender,
            status: .preparing,
            createdAt: Date(),
            tasks: [
                BidTask(title: "Eignungsnachweise sammeln"),
                BidTask(title: "Referenzen prüfen"),
                BidTask(title: "Preisblatt kalkulieren")
            ],
            comments: [
                BidComment(text: "Kickoff mit Vertrieb abgeschlossen."),
                BidComment(text: "Rückfragenliste an AG gesendet.")
            ]
        )
    }
}
