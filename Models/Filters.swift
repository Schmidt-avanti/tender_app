import Foundation

/// Defines the search filters used to query the backend.  All fields
/// are optional, allowing the user to specify as much or as little
/// constraint as desired.
struct SearchFilters: Codable, Equatable, Hashable {
    var cpv: [String] = []
    var regions: [String] = []
    var minValue: Double? = nil
    var maxValue: Double? = nil
    var deadlineFrom: Date? = nil
    var deadlineTo: Date? = nil
    var freeText: String = ""
}
