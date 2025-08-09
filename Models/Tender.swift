import Foundation

/// Minimales Tender-Modell, das überall in der App genutzt wird.
/// Jetzt auch Codable, damit z.B. `Bid: Codable` sauber kompiliert.
struct Tender: Identifiable, Hashable, Codable {
    let id: String
    let source: String
    let title: String

    var buyer: String?
    var cpv: [String]
    var country: String?
    var city: String?

    /// Abgabedatum (optional)
    var deadline: Date?

    /// Veröffentlichungsdatum (optional)
    var publishedAt: Date?

    /// Geschätzter Wert (optional)
    var valueEstimate: Double?

    /// Link zur Ausschreibung (optional)
    var url: URL?
}

extension Tender {
    /// Zeile für die Liste: "Veröffentlicht … · Abgabe … · Land …"
    var subtitleLine: String {
        var bits: [String] = []
        if let p = publishedAt {
            bits.append("Veröffentlicht: \(p.formatted(date: .abbreviated, time: .omitted))")
        }
        if let d = deadline {
            bits.append("Abgabe: \(d.formatted(date: .abbreviated, time: .omitted))")
        }
        if let c = country, !c.isEmpty {
            bits.append(c)
        }
        return bits.isEmpty ? "—" : bits.joined(separator: " · ")
    }
}
