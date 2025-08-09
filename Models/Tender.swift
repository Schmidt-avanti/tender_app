//
//  Tender.swift
//  TendersApp
//

import Foundation

struct Tender: Identifiable, Codable, Hashable {
    var id: UUID
    var title: String
    var buyer: String
    var country: String
    var cpv: [String]
    var url: URL
    var publishedAt: Date
    var deadline: Date?
    var valueEstimate: Double?

    init(
        id: UUID = UUID(),
        title: String,
        buyer: String,
        country: String,
        cpv: [String] = [],
        url: URL,
        publishedAt: Date = Date(),
        deadline: Date? = nil,
        valueEstimate: Double? = nil
    ) {
        self.id = id
        self.title = title
        self.buyer = buyer
        self.country = country
        self.cpv = cpv
        self.url = url
        self.publishedAt = publishedAt
        self.deadline = deadline
        self.valueEstimate = valueEstimate
    }

    var subtitleLine: String {
        let df = DateFormatter()
        df.dateStyle = .medium
        var parts: [String] = []
        parts.append(buyer)
        if let d = deadline {
            parts.append("Deadline: " + df.string(from: d))
        }
        parts.append(country)
        return parts.joined(separator: " • ")
    }

    static func mock(
        id: UUID = UUID(),
        title: String = "IT-Dienstleistungen für Schulverwaltung",
        buyer: String = "Stadtverwaltung Musterstadt",
        country: String = "DE",
        cpv: [String] = ["72222300", "72222310"],
        url: URL = URL(string: "https://example.com/tender/123")!,
        publishedAt: Date = Date(),
        deadline: Date? = Calendar.current.date(byAdding: .day, value: 21, to: Date()),
        valueEstimate: Double? = 250_000
    ) -> Tender {
        Tender(
            id: id,
            title: title,
            buyer: buyer,
            country: country,
            cpv: cpv,
            url: url,
            publishedAt: publishedAt,
            deadline: deadline,
            valueEstimate: valueEstimate
        )
    }
}
