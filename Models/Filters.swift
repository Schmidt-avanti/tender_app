import Foundation

struct Filters: Codable, Equatable {
    var query: String = ""
    var country: String? = nil
    var cpv: String? = nil
    var minBudget: Double? = nil
    var maxBudget: Double? = nil
    var onlyEU: Bool = false
}