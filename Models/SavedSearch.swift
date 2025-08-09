import Foundation

/// Represents a saved search configuration that can be reused by the user.
/// Each saved search stores the original filters along with a friendly name
/// and a unique identifier.  Saved searches can later be executed to
/// refresh results or used to subscribe to push notifications for new
/// tenders matching the criteria.
struct SavedSearch: Identifiable, Codable, Hashable {
    /// A stable identifier for this saved search.  Use UUIDs so that
    /// objects remain distinct even if filters change.
    let id: UUID
    /// A user‑defined title to make it easier to recognise the search.
    var name: String
    /// The underlying filter configuration.  This mirrors the
    /// `SearchFilters` used in the live search view.
    var filters: SearchFilters
    /// The timestamp when the search was originally saved.  Useful for
    /// sorting or auditing.
    var createdAt: Date

    init(id: UUID = UUID(), name: String, filters: SearchFilters, createdAt: Date = Date()) {
        self.id = id
        self.name = name
        self.filters = filters
        self.createdAt = createdAt
    }
}