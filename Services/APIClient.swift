//
//  APIClient.swift
//  TendersApp
//

import Foundation

enum APIError: Error {
    case invalidURL
    case decoding
    case transport(Error)
}

final class APIClient {
    static let shared = APIClient()
    private init() {}

    // In a real app, replace this with your backend call.
    func searchTenders(filters: Filters) async throws -> [Tender] {
        // Simulate latency
        try await Task.sleep(nanoseconds: 250_000_000)

        // Create some mock data filtered by query text and optional country/cpv
        let base: [Tender] = (0..<25).map { idx in
            Tender.mock(
                id: UUID(),
                title: "Ausschreibung \(idx + 1): \(filters.queryText.isEmpty ? "Leistung" : filters.queryText)",
                buyer: ["Stadt Köln", "Land Berlin", "Universität München", "Klinikum Hamburg"].randomElement() ?? "Vergabestelle",
                country: filters.countries.first ?? ["DE","AT","CH","FR","NL"].randomElement()!,
                cpv: filters.cpv.isEmpty ? ["72000000"] : filters.cpv,
                url: URL(string: "https://example.com/\(idx)")!,
                publishedAt: Date().addingTimeInterval(TimeInterval(-(idx * 86_400))),
                deadline: Calendar.current.date(byAdding: .day, value: Int.random(in: 7...45), to: Date()),
                valueEstimate: Double(Int.random(in: 50_000...500_000))
            )
        }

        let text = filters.queryText.lowercased()
        let filtered = base.filter { t in
            (text.isEmpty || t.title.lowercased().contains(text) || t.buyer.lowercased().contains(text))
        }
        return filtered
    }
}
