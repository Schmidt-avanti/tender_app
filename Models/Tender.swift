import Foundation

struct Tender: Identifiable, Codable, Equatable, Sendable {
    var id: String
    var title: String
    var buyer: String?
    var location: String?
    var deadline: Date?
    var budget: String?
    var url: URL?
    var summary: String?
    var source: String?

    init(
        id: String,
        title: String,
        buyer: String? = nil,
        location: String? = nil,
        deadline: Date? = nil,
        budget: String? = nil,
        url: URL? = nil,
        summary: String? = nil,
        source: String? = nil
    ) {
        self.id = id
        self.title = title
        self.buyer = buyer
        self.location = location
        self.deadline = deadline
        self.budget = budget
        self.url = url
        self.summary = summary
        self.source = source
    }
}

extension Tender {
    static let mock: Tender = .init(
        id: "MOCK-1",
        title: "Beispiel: IT-Dienstleistungen für Stadtverwaltung",
        buyer: "Stadtverwaltung Beispielstadt",
        location: "Beispielstadt",
        deadline: Calendar.current.date(byAdding: .day, value: 21, to: Date()),
        budget: "ca. 250.000 EUR",
        url: URL(string: "https://example.com/tender/123"),
        summary: "Bereitstellung von IT-Unterstützung, Wartung und Support für 24 Monate.",
        source: "MockProvider"
    )
}