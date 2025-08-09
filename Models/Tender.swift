import Foundation

/// Represents a tender returned by the backend.  Many fields are
/// optional because procurement notices can be incomplete.  Notes and
/// favourite status are stored separately in `FavoritesManager`.
struct Tender: Identifiable, Codable, Hashable {
    let id: String
    let source: String
    let title: String
    let buyer: String?
    let cpv: [String]
    let country: String?
    let city: String?
    let deadline: Date?
    let valueEstimate: Double?
    let url: URL?
}
