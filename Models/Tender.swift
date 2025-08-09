import Foundation

/// Minimales Tender-Modell. Jetzt Codable und Hashable.
/// Damit können `Bid`-Objekte dieses Modell persistieren.
struct Tender: Identifiable, Hashable, Codable {
    let id: String
    let source: String
    let title: String
    var buyer: String?
    var cpv: [String]
    var country: String?
    var city: String?
    var deadline: Date?
    var publishedAt: Date?
    var valueEstimate: Double?
    var url: URL?
}

extension Tender {
    /// Zeile für die Liste: „Veröffentlicht … · Abgabe … · Land …“
    var subtitleLine: String {
        var parts: [String] = []
        if let pub = publishedAt {
            parts.append("Veröffentlicht: \(pub.formatted(date: .abbreviated, time: .omitted))")
        }
        if let dl = deadline {
            parts.append("Abgabe: \(dl.formatted(date: .abbreviated, time: .omitted))")
        }
        if let c = country, !c.isEmpty {
            parts.append(c)
        }
        return parts.isEmpty ? "—" : parts.joined(separator: " · ")
    }
}
