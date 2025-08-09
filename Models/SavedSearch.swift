//
//  SavedSearch.swift
//  TendersApp
//

import Foundation

struct SavedSearch: Identifiable, Codable, Hashable {
    var id: UUID
    var name: String
    var filters: Filters
    var createdAt: Date

    init(id: UUID = UUID(), name: String, filters: Filters, createdAt: Date = Date()) {
        self.id = id
        self.name = name
        self.filters = filters
        self.createdAt = createdAt
    }
}
