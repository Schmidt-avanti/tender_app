import Foundation

struct SearchFilters: Codable, Equatable, Hashable {
    var cpv: [String] = []
    var regions: [String] = []
    var minValue: Double? = nil
    var maxValue: Double? = nil
    var deadlineFrom: Date? = nil
    var deadlineTo: Date? = nil
    var freeText: String = ""
}
