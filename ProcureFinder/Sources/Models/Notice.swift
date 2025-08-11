import Foundation

public struct Notice: Identifiable, Hashable {
    public let id = UUID()
    public let publicationNumber: String
    public let title: String
    public let country: String?
    public let procedure: String?
    public let cpvTop: String?
    public let budget: Double?
    public let publicationDate: Date?
}

public struct CPV: Identifiable, Hashable, Codable {
    public var id: String { code }
    public let code: String
    public let en: String
    public let de: String
}

public struct SearchFilters: Equatable {
    public var text: String = ""
    public var countries: [String] = []
    public var dateFrom: Date? = nil
    public var dateTo: Date? = nil
    public var procedures: [String] = []
    public var cpvCodes: [String] = []
    public var sort: Sort = .dateDesc
    public enum Sort: String, CaseIterable { case dateDesc = "publication-date,desc"; case dateAsc = "publication-date,asc" }
}
