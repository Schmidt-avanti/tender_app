import Foundation

struct Tender: Identifiable, Hashable {
    let id: String
    let source: String
    let title: String
    let buyer: String?
    let cpv: [String]
    let country: String?
    let city: String?
    let deadline: Date?          // Abgabefrist (falls vorhanden)
    let publishedAt: Date?       // Veröffentlichungsdatum (falls vorhanden)
    let valueEstimate: Double?
    let url: URL?
}

extension Tender {
    var subtitleLine: String {
        let pub = publishedAt?.formatted(date: .abbreviated, time: .omitted) ?? "–"
        let dl  = deadline?.formatted(date: .abbreviated, time: .omitted) ?? "–"
        let land = country ?? "–"
        return "Veröffentlicht: \(pub)   •   Abgabe: \(dl)   •   Land: \(land)"
    }
}
